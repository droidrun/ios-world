#!/usr/bin/env python3
"""iOSWorld demo mode — type any task, watch an LLM agent drive the simulator.

This is the *easy on-ramp* to the benchmark. Where the paper runners replay the
fixed 133-task suite, demo mode lets you type a free-form goal ("reply to the
latest QuickChat message", "find my next flight and add a Notes reminder") and
watch the agent navigate Jordan Avery's fully-seeded iPhone live.

It wraps the standard runner (`scripts/appium_agent.py`) — no scoring, no
rubric, just a clean terminal UI over the agent's thoughts and actions:

  1. finds (or boots) an iOS Simulator and brings its window forward,
  2. starts an Appium server if one isn't already running,
  3. synthesises a one-off task from whatever you type,
  4. streams the agent's per-step reasoning + actions into the terminal.

Usage:
    python3 scripts/demo.py                       # interactive — uses .env
    python3 scripts/demo.py --provider anthropic --model claude-opus-4-6
    python3 scripts/demo.py --task "set a 6:45 AM alarm labeled Gym"

The provider/model default to LLM_PROVIDER / LLM_MODEL in .env (any of the six
paper runners). Prereqs are the same as the benchmark: scripts/setup_env.sh has
been run and ./iphone/bootstrap/bootstrap_ios_apps.sh has installed the 26 apps.
"""

from __future__ import annotations

import argparse
import json
import os
import pathlib
import re
import shutil
import subprocess
import sys
import threading
import time
import urllib.error
import urllib.request

REPO_ROOT = pathlib.Path(__file__).resolve().parent.parent
AGENT = REPO_ROOT / "scripts" / "appium_agent.py"

# Provider -> the env var that must be populated for that provider's runner.
PROVIDER_KEY = {
    "anthropic": "ANTHROPIC_API_KEY",
    "openai": "OPENAI_API_KEY",
    "gemini": "GEMINI_API_KEY",
    "vllm": "VLLM_BASE_URL",
}

EXAMPLE_TASKS = [
    "set a 6:45 AM alarm labeled Gym in the Clock app",
    "reply 'on my way' to the latest message in QuickChat",
    "find Jordan's next flight in SkyTrip and save it as a Notes reminder",
]

# Preset runners shown by the startup picker. --provider/--model can name any
# other supported combo too.
RUNNERS = [
    ("Claude Opus 4.6",   "anthropic", "claude-opus-4-6"),
    ("Claude Sonnet 4.6", "anthropic", "claude-sonnet-4-6"),
    ("GPT-5.4",           "openai",    "gpt-5.4"),
    ("GPT-5.4 Mini",      "openai",    "gpt-5.4-mini"),
    ("Gemini 3 Flash",    "gemini",    "gemini-3-flash-preview"),
    ("Qwen3.5 35B-A3B",   "vllm",      "qwen3.5-35B-a3"),
]


# ─────────────────────────────────────────────────────────────────────────────
# Terminal styling — pure-stdlib ANSI, no third-party dependency.
# ─────────────────────────────────────────────────────────────────────────────
_USE_COLOR = sys.stdout.isatty() and os.environ.get("NO_COLOR") is None
_TTY = sys.stdout.isatty()


def _c(text: str, *codes: str) -> str:
    """Wrap `text` in ANSI codes, or return it untouched when color is off."""
    if not _USE_COLOR or not codes:
        return text
    return f"\033[{';'.join(codes)}m{text}\033[0m"


# Code fragments (joined inside _c). The iOSWorld site is deliberately
# monochrome — Apple-silver, high contrast, no colour accent — so the UI
# leans on weight (bold = "ink") and dimming (= the #86868b tertiary grey)
# rather than hue. The three status hues are used sparingly, as the site does.
BOLD, DIM = "1", "2"
GREEN, YELLOW, RED = "32", "33", "31"  # ok / warn / bad — used only on glyphs

WIDTH = max(46, min((shutil.get_terminal_size((80, 24)).columns) - 6, 68))


def ink(s: str) -> str:
    """Primary text — the site's near-black #0a0a0a 'ink'."""
    return _c(s, BOLD)


def sub(s: str) -> str:
    """Tertiary text — captions, hairlines, the #86868b grey."""
    return _c(s, DIM)


def eyebrow(s: str) -> str:
    """A small mono-caps specimen label, as used site-wide for section marks
    (the site tracks these +0.12em — restrained, so plain caps reads truest)."""
    return _c(s.upper(), DIM)


def hr(width: int = WIDTH) -> str:
    """A hairline rule — the site's 1px #d2d2d7 divider."""
    return _c("─" * max(1, width), DIM)


_ANSI_RE = re.compile(r"\033\[[0-9;]*m")


def _vis(s: str) -> int:
    """Visible width of a string, ignoring ANSI escape codes."""
    return len(_ANSI_RE.sub("", s))


# Content width inside a card — sized so the card's outer edge lands exactly
# on a full-width `hr()` rule (card = ╭ + dashes + ╮; dashes = WIDTH - 2).
CARD_W = WIDTH - 4


def card(rows: list[str]) -> None:
    """Draw a rounded hairline card around `rows` — the site's Apple
    rounded-rectangle surface (.card / .glass-panel), rendered in mono."""
    dashes = WIDTH - 2
    print("  " + _c("╭" + "─" * dashes + "╮", DIM))
    for r in rows:
        print("  " + _c("│", DIM) + " " + r
              + " " * max(0, CARD_W - _vis(r)) + " " + _c("│", DIM))
    print("  " + _c("╰" + "─" * dashes + "╯", DIM))


def banner() -> None:
    """Print the iOSWorld masthead — a rounded card holding the wordmark and
    paper title, the way the site frames identity in a clean Apple surface."""
    title = "A Benchmark for Personally Intelligent Phone Agents"
    left, right = ink("iOSWorld"), eyebrow("Demo")
    gap = max(2, CARD_W - _vis(left) - _vis(right))
    print()
    card([
        "",
        left + " " * gap + right,
        sub(title[:CARD_W]),
        "",
    ])
    print()
    print("  " + sub("Type a task in plain language; a computer-use agent drives"))
    print("  " + sub("a real iOS simulator across Jordan Avery's 26-app iPhone."))
    print()


def textbox(prompt_examples: bool = True) -> str:
    """Prompt for a task — an academic form field: eyebrow label, then a
    caret input line closed by a hairline rule (no box; input of any length
    stays clean)."""
    if prompt_examples:
        print("  " + eyebrow("examples"))
        for ex in EXAMPLE_TASKS:
            print("    " + sub(ex))
        print()
    print("  " + eyebrow("task"))
    try:
        raw = input("  " + ink("›") + " ")
    except EOFError:
        raw = ""
        print()
    print("  " + hr())
    return raw.strip()


def pick_model(cur_provider: str, cur_model: str) -> tuple[str, str]:
    """Startup picker — choose the agent's provider + model. Enter keeps the
    .env default; a number switches to one of the paper runners for this
    session. Ctrl-C / Ctrl-D also just keep the default."""
    print("  " + eyebrow("model"))
    for i, (label, prov, mdl) in enumerate(RUNNERS, 1):
        is_default = prov == cur_provider and mdl == cur_model
        marker = sub("   ← default") if is_default else ""
        print("  " + _c(str(i), BOLD) + "   " + label.ljust(20)
              + sub(prov) + marker)
    default = f"{cur_provider} · {cur_model}" if cur_provider and cur_model \
        else "none set"
    print("  " + hr())
    while True:
        try:
            raw = input("  " + ink("›") + " 1-" + str(len(RUNNERS))
                         + ", or Enter for " + sub(default) + "  ").strip()
        except (EOFError, KeyboardInterrupt):
            print()
            return cur_provider, cur_model
        if not raw:
            return cur_provider, cur_model
        if raw.isdigit() and 1 <= int(raw) <= len(RUNNERS):
            _, prov, mdl = RUNNERS[int(raw) - 1]
            return prov, mdl
        print("  " + sub(f"  '{raw}' — type 1-{len(RUNNERS)}, or just Enter."))


# ─────────────────────────────────────────────────────────────────────────────
# Spinner — a single status line that animates while a blocking step runs.
# ─────────────────────────────────────────────────────────────────────────────
class Spinner:
    FRAMES = "⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"

    def __init__(self, label: str):
        self.label = label
        self._stop = threading.Event()
        self._thread: threading.Thread | None = None

    def start(self) -> "Spinner":
        if _TTY:
            self._thread = threading.Thread(target=self._spin, daemon=True)
            self._thread.start()
        else:
            print(f"  · {self.label} …", flush=True)
        return self

    def _spin(self) -> None:
        i = 0
        while not self._stop.is_set():
            frame = self.FRAMES[i % len(self.FRAMES)]
            sys.stdout.write(f"\r\033[K  {frame} {_c(self.label, DIM)} …")
            sys.stdout.flush()
            i += 1
            time.sleep(0.08)

    def stop(self, ok: bool = True, detail: str | None = None) -> None:
        if self._stop.is_set():
            return  # already stopped — keep stop() idempotent
        self._stop.set()
        if self._thread is not None:
            self._thread.join()
        sym = _c("✓", GREEN) if ok else _c("✗", RED)
        tail = _c(f"  {detail}", DIM) if detail else ""
        line = f"  {sym} {self.label}{tail}"
        if _TTY:
            sys.stdout.write(f"\r\033[K{line}\n")
        else:
            print(line)
        sys.stdout.flush()

    def __enter__(self) -> "Spinner":
        return self.start()

    def __exit__(self, exc_type, exc, tb) -> None:
        if not self._stop.is_set():
            self.stop(ok=exc_type is None)


def die(msg: str, hint: str | None = None) -> "NoReturn":  # type: ignore[valid-type]
    print(f"\n  {_c('✗', RED)} {msg}", file=sys.stderr)
    if hint:
        print(_c(f"    {hint}", DIM), file=sys.stderr)
    sys.exit(1)


# ─────────────────────────────────────────────────────────────────────────────
# Environment + simulator + Appium setup.
# ─────────────────────────────────────────────────────────────────────────────
def load_env() -> dict:
    """Parse the repo's .env into a dict (empty values are skipped so they
    never clobber a real value already present in the ambient environment)."""
    env = dict(os.environ)
    env_file = REPO_ROOT / ".env"
    if not env_file.exists():
        return env
    for line in env_file.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        if line.startswith("export "):
            line = line[len("export "):]
        key, _, val = line.partition("=")
        key, val = key.strip(), val.strip().strip('"').strip("'")
        if key and val:
            env[key] = val
    return env


def simctl(*args: str) -> subprocess.CompletedProcess:
    return subprocess.run(["xcrun", "simctl", *args], capture_output=True, text=True)


def _devices() -> list[dict]:
    """Flat list of all simulator devices, each annotated with its iOS version."""
    proc = simctl("list", "devices", "-j")
    out: list[dict] = []
    try:
        data = json.loads(proc.stdout)
    except json.JSONDecodeError:
        return out
    for runtime, devs in (data.get("devices") or {}).items():
        ver = ""
        m = re.search(r"iOS-([\d-]+)", runtime)
        if m:
            ver = m.group(1).replace("-", ".")
        for d in devs:
            d["_ios"] = ver
            out.append(d)
    return out


def _sim_has_apps(udid: str, manifest: dict) -> bool:
    """True when the benchmark apps are installed on this simulator."""
    bundles = [v["bundle_id"] for v in list(manifest.values())[:3] if v.get("bundle_id")]
    return all(
        simctl("get_app_container", udid, b).returncode == 0 for b in bundles
    ) if bundles else False


def find_simulator(env: dict, manifest: dict, device_name: str) -> tuple[str, str, str]:
    """Pick a simulator to drive — preferring a booted one that already has the
    26 apps installed. Boots one if nothing suitable is running.

    Returns (udid, name, ios_version).
    """
    devices = _devices()
    if not devices:
        die("No iOS simulators found.",
            "Install an iOS runtime: Xcode → Settings → Platforms.")

    booted = [d for d in devices if d.get("state") == "Booted"]
    iphones = [d for d in booted if "iPhone" in d.get("name", "")]

    # Priority order of candidates to consider among already-booted iPhones.
    ordered: list[dict] = []
    pinned = env.get("SIMCTL_UDID", "").strip()
    if pinned:
        ordered += [d for d in iphones if d.get("udid") == pinned]
    ordered += [d for d in iphones if d.get("name") == device_name]
    ordered += [d for d in iphones if d not in ordered]

    # Prefer a booted iPhone that already has the apps; fall back to any booted.
    for d in ordered:
        if _sim_has_apps(d["udid"], manifest):
            return d["udid"], d["name"], d.get("_ios", "")
    if ordered:
        d = ordered[0]
        return d["udid"], d["name"], d.get("_ios", "")

    # Nothing booted — boot the configured device (or any available iPhone).
    target = next((d for d in devices if d.get("name") == device_name and d.get("isAvailable")), None)
    target = target or next(
        (d for d in devices if "iPhone" in d.get("name", "") and d.get("isAvailable")), None)
    if not target:
        die(f"No simulator named {device_name!r} and no available iPhone to boot.",
            "Create one, or set DEVICE_NAME in .env to a sim you have.")
    with Spinner(f"booting {target['name']}") as sp:
        simctl("boot", target["udid"])
        subprocess.run(["xcrun", "simctl", "bootstatus", target["udid"], "-b"],
                       capture_output=True, text=True)
        sp.label = f"booted {target['name']}"
    return target["udid"], target["name"], target.get("_ios", "")


def appium_alive(url: str) -> bool:
    try:
        with urllib.request.urlopen(f"{url}/status", timeout=3) as r:
            return r.status == 200
    except (urllib.error.URLError, OSError):
        return False


def ensure_appium(url: str, auto_start: bool) -> subprocess.Popen | None:
    """Make sure an Appium server answers at `url`. Starts one if needed and
    returns the process so the caller can shut it down on exit."""
    if appium_alive(url):
        print("  " + _c("✓", GREEN) + " Appium ready  " + sub(url))
        return None
    if not auto_start:
        die(f"Appium is not reachable at {url}.",
            "Start it in another terminal:  appium --port 4723")
    if shutil.which("appium") is None:
        die("Appium is not installed.", "Run ./scripts/setup_env.sh first.")

    port = url.rsplit(":", 1)[-1].split("/")[0] or "4723"
    (REPO_ROOT / "results").mkdir(parents=True, exist_ok=True)
    log = open(REPO_ROOT / "results" / ".demo-appium.log", "w")
    proc = subprocess.Popen(
        ["appium", "--port", port, "--log-level", "warn"],
        stdout=log, stderr=subprocess.STDOUT,
    )
    with Spinner("starting Appium") as sp:
        for _ in range(60):  # up to ~30s
            if appium_alive(url):
                sp.label = f"Appium ready  {url}"
                return proc
            if proc.poll() is not None:
                sp.stop(ok=False)
                die("Appium exited during startup.",
                    "See results/.demo-appium.log")
            time.sleep(0.5)
        sp.stop(ok=False)
    proc.terminate()
    die("Appium did not become ready in time.")


def _probe(url: str, headers: dict | None = None, timeout: float = 6.0):
    """Return (status, None) if the host answered with ANY HTTP code, or
    (None, reason) if it could not be reached at all."""
    req = urllib.request.Request(url, headers=headers or {})
    try:
        with urllib.request.urlopen(req, timeout=timeout) as r:
            return r.status, None
    except urllib.error.HTTPError as exc:
        return exc.code, None  # the server replied — it is reachable
    except (urllib.error.URLError, OSError) as exc:
        return None, str(getattr(exc, "reason", exc))


def check_provider(provider: str, model: str, env: dict) -> bool:
    """Pre-flight the model backend so a dead server or rejected key fails
    *here*, loudly and immediately — never as a task silently hung at
    'connecting…'. Returns True when the backend was confirmed reachable."""
    if provider == "vllm":
        base = env.get("VLLM_BASE_URL", "").rstrip("/")
        if not base:
            die("vllm is selected but VLLM_BASE_URL is not set.",
                "Set VLLM_BASE_URL in .env, or use a cloud model: "
                "--provider anthropic --model claude-opus-4-6")
        status, _ = _probe(base + "/models")
        if status is None:
            die(f"No model backend — the vLLM server at {base} is not reachable.",
                "Start your vLLM server (see docs/qwen_vllm_cluster.md), or run "
                "on a cloud model: --provider anthropic --model claude-opus-4-6")
        return True

    # Cloud providers — confirm the API key is accepted.
    endpoints = {
        "anthropic": ("https://api.anthropic.com/v1/models",
                      {"x-api-key": env.get("ANTHROPIC_API_KEY", ""),
                       "anthropic-version": "2023-06-01"}),
        "openai": ("https://api.openai.com/v1/models",
                   {"Authorization": "Bearer " + env.get("OPENAI_API_KEY", "")}),
        "gemini": ("https://generativelanguage.googleapis.com/v1beta/models?key="
                   + env.get("GEMINI_API_KEY", ""), {}),
    }
    if provider not in endpoints:
        return False  # unknown provider — let the runner be the judge
    url, headers = endpoints[provider]
    status, reason = _probe(url, headers)
    if status in (401, 403):
        die(f"Your {provider} API key was rejected (HTTP {status}).",
            f"Check {PROVIDER_KEY.get(provider, 'the API key')} in .env.")
    if status is None:
        print("  " + _c("!", YELLOW) + " " + sub(
            f"could not reach {provider} to verify the key ({reason}) "
            "— continuing anyway"))
        return False
    return True


# ─────────────────────────────────────────────────────────────────────────────
# Seeding — wipe + reseed every app to Jordan Avery's canonical state, with a
# live progress bar. Done up front, before the prompt, so a typed task starts
# instantly instead of stalling on a ~minute reseed.
# ─────────────────────────────────────────────────────────────────────────────
SEED_BAR_W = 22


def _run_internal_seed(udid: str) -> None:
    """Hidden child-process seeding command: wipe, then reseed every app one at
    a time, emitting a progress line per app. seed_simulator() runs this as a
    child process so appium_agent's chatty simctl logging stays isolated from
    the demo UI — the parent only ever sees the clean progress lines below."""
    real_out = sys.stdout  # saved before the redirect_stdout() below

    def emit(msg: str) -> None:
        print(msg, file=real_out, flush=True)

    try:
        sys.path.insert(0, str(REPO_ROOT / "scripts"))
        import appium_agent as aa
    except Exception as exc:  # noqa: BLE001
        emit(f"FATAL could not load the runner: {exc}")
        return

    manifest_path = REPO_ROOT / (os.environ.get("APP_MANIFEST")
                                 or "iphone/bootstrap/.app_manifest.json")
    if not manifest_path.is_absolute():
        manifest_path = REPO_ROOT / manifest_path
    try:
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    except Exception as exc:  # noqa: BLE001
        emit(f"FATAL could not read the app manifest: {exc}")
        return

    apps = sorted(manifest.keys())
    emit(f"TOTAL {len(apps)}")

    # Single-threaded child, so the global stdout redirect is safe — it
    # swallows appium_agent's per-app simctl chatter; progress goes to the
    # saved real stdout via emit().
    import contextlib
    import io
    with contextlib.redirect_stdout(io.StringIO()):
        try:
            # One wipe pass over all apps in a single call — the shared
            # workspace-suite container must be cleared once, not re-cleared
            # per app (which would clobber an already-seeded sibling).
            aa.reset_app_data(udid, apps, manifest)
        except Exception as exc:  # noqa: BLE001
            emit(f"WARN wipe: {exc}")
        for i, app in enumerate(apps, 1):
            emit(f"SEED {i} {app}")
            try:
                aa.reseed_apps(udid, [app], manifest)
            except Exception:  # noqa: BLE001
                emit(f"ERR {app}")
    emit("DONE")


def _draw_seed(state: dict, frame: str, elapsed: float) -> None:
    """Render the one-line seeding indicator in place (TTY)."""
    if state["phase"] == "wipe":
        body = ink("Seeding the iPhone") + "   " + sub("clearing previous data")
    else:
        total, done = state["total"], state["done"]
        filled = round(SEED_BAR_W * done / max(1, total))
        bar = _c("▰" * filled, BOLD) + _c("▱" * (SEED_BAR_W - filled), DIM)
        clock = f"{int(elapsed) // 60}:{int(elapsed) % 60:02d}"
        body = (bar + "  " + sub(f"{done:2d}/{total}")
                + "  " + ink(state["current"]) + "  " + sub(clock))
    sys.stdout.write(f"\r\033[K  {frame}  {body}")
    sys.stdout.flush()


def seed_simulator(udid: str, env: dict) -> None:
    """Wipe + reseed all 26 apps to Jordan Avery's canonical state, showing a
    live progress bar. Runs before the prompt so a task starts the instant
    it's typed — never a silent stall after you hit Enter."""
    proc = subprocess.Popen(
        [sys.executable, str(pathlib.Path(__file__).resolve()),
         "--internal-seed", udid],
        cwd=str(REPO_ROOT), env=env,
        stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
        text=True, bufsize=1,
    )
    state: dict = {"total": 26, "done": 0, "current": "",
                   "phase": "wipe", "failed": [], "fatal": None}

    def reader() -> None:
        assert proc.stdout is not None
        for line in proc.stdout:
            parts = line.split()
            if not parts:
                continue
            tag = parts[0]
            if tag == "TOTAL" and len(parts) > 1:
                state["total"] = int(parts[1])
            elif tag == "SEED" and len(parts) > 2:
                state["phase"] = "seed"
                state["done"] = int(parts[1]) - 1   # apps fully done so far
                state["current"] = parts[2]
            elif tag == "ERR" and len(parts) > 1:
                state["failed"].append(parts[1])
            elif tag == "FATAL":
                state["fatal"] = line.partition(" ")[2].strip()
            elif tag == "DONE":
                state["done"] = state["total"]
                state["phase"] = "done"

    t = threading.Thread(target=reader, daemon=True)
    t.start()

    start = time.time()
    if not _TTY:
        print("  " + sub("Seeding the iPhone with Jordan Avery's data …"))
    try:
        i = 0
        while proc.poll() is None:
            if _TTY:
                _draw_seed(state, Spinner.FRAMES[i % len(Spinner.FRAMES)],
                           time.time() - start)
            i += 1
            time.sleep(0.08)
    except KeyboardInterrupt:
        proc.terminate()
        if _TTY:
            sys.stdout.write("\r\033[K")
        raise
    t.join(timeout=1.0)

    if _TTY:
        sys.stdout.write("\r\033[K")
    if state["fatal"]:
        print("  " + _c("✗", RED) + " could not seed the simulator  "
              + sub(state["fatal"]))
    elif state["failed"]:
        ok = state["total"] - len(state["failed"])
        print("  " + _c("✓", GREEN) + " iPhone ready  "
              + sub(f"{ok}/{state['total']} apps seeded · "
                    f"{len(state['failed'])} will retry on use"))
    else:
        print("  " + _c("✓", GREEN) + " iPhone ready  "
              + sub(f"{state['total']} apps seeded with Jordan Avery's data"))


# ─────────────────────────────────────────────────────────────────────────────
# Rendering the agent's live event stream.
# ─────────────────────────────────────────────────────────────────────────────
def _wrap(text: str, indent: str) -> str:
    import textwrap
    body = " ".join(text.split())
    return textwrap.fill(
        body, width=WIDTH + 2, initial_indent=indent, subsequent_indent=indent)


def _fmt_action(ev: dict) -> str:
    """One-line human-readable summary of an executed action event."""
    a = ev.get("action") or ev.get("type") or "?"
    x, y = ev.get("x"), ev.get("y")
    if a in ("tap_xy", "tap"):
        if x is not None and y is not None:
            return f"tap   ({int(x)}, {int(y)})"
        el = ev.get("element_id") or ev.get("accessibility_id") or ev.get("selector")
        return f"tap   {el}" if el else "tap"
    if a == "type":
        t = (ev.get("text") or "").replace("\n", " ")
        if len(t) > 56:
            t = t[:55] + "…"
        return f'type  "{t}"'
    if a == "swipe":
        return f"swipe {ev.get('direction', '')}".rstrip()
    if a == "open_url":
        return f"open  {ev.get('url', '')}"
    if a == "launch_app":
        return f"launch {ev.get('bundle_id', '')}"
    if a == "terminate_app":
        return f"close {ev.get('bundle_id', '')}"
    if a in ("stop", "done"):
        return "stop"
    return a  # home, wait, and anything else


def stream_run(proc: subprocess.Popen, verbose: bool) -> list[str]:
    """Consume appium_agent's JSON-line event stream and render it.

    appium_agent emits one JSON object per line for every structured event
    (`log_event`); free-form log lines are interleaved. We render the events
    and keep the tail of plain lines around in case the run crashes early.
    """
    recent: list[str] = []
    prep = Spinner("connecting to the simulator").start()
    preparing = True
    cur_step: int | None = None

    assert proc.stdout is not None
    # The runner streams faster than anyone reads, and the only key that can
    # reach us mid-stream is Ctrl-C. First Ctrl-C pauses and confirms (see
    # _confirm_stop) so an accidental keypress can't throw away a long run.
    while True:
        try:
            for line in proc.stdout:
                line = line.rstrip("\n")
                if not line:
                    continue

                # Only lines that parse to a dict carrying an "event" key
                # are structured events; everything else is plain log.
                ev: dict | None = None
                if line.startswith("{"):
                    try:
                        obj = json.loads(line)
                        if isinstance(obj, dict) and "event" in obj:
                            ev = obj
                    except json.JSONDecodeError:
                        pass
                if ev is None:
                    recent.append(line)
                    recent[:] = recent[-25:]
                    if verbose and not preparing:
                        print(sub(f"         {line}"))
                    continue

                et = ev["event"]

                # ── Setup phase: one spinner while the driver connects ──
                # The apps are already seeded (seed_simulator ran up front),
                # so this is just the Appium/WDA handshake — a few seconds.
                if preparing:
                    ends_prep = ("summary", "planned_actions", "action",
                                 "task_error", "llm_recoverable_error")
                    if et not in ends_prep:
                        continue  # still connecting — hold the spinner
                    # First real event — close setup, then fall through to
                    # render it. An error event means the agent never began.
                    problem = et in ("task_error", "llm_recoverable_error")
                    prep.stop(ok=not problem)
                    print()
                    if not problem:
                        print("  " + ink("●") + "  "
                              + sub("the agent is now driving the simulator"))
                        # The interrupt control — Ctrl-C is the one key that
                        # reaches us while the runner streams.
                        print("     " + _c("⌃C", BOLD)
                              + sub("  interrupt the agent · start a new task"))
                        print()
                    preparing = False

                # ── Run phase: a step mark, then thoughts + actions ──
                step = ev.get("step")
                if step is not None and step != cur_step:
                    if cur_step is not None:
                        print()  # blank between steps, not before the first
                    cur_step = step
                    mark = eyebrow("step") + _c(f"  {step:02d}  ", DIM)
                    print("  " + mark + hr(WIDTH - _vis(mark)))

                if et == "summary" and ev.get("summary"):
                    _gutter("think", ev["summary"], wrap=True)
                elif et == "action":
                    _gutter("act", _fmt_action(ev), text_code=BOLD)
                elif et == "action_error":
                    _gutter("warn", str(ev.get("error", "")), label_code=YELLOW,
                            text_code=DIM, wrap=True)
                elif et == "stuck_detected":
                    _gutter("note", "agent looks stuck — nudging it", text_code=DIM)
                elif et == "llm_recoverable_error":
                    n = ev.get("consecutive", "?")
                    _gutter("model", f"not responding (attempt {n}/3) — "
                            + str(ev.get("error", "")), label_code=YELLOW,
                            text_code=DIM, wrap=True)
                elif et == "task_error":
                    _gutter("error", str(ev.get("error", "")), label_code=RED,
                            text_code=DIM, wrap=True)
        except KeyboardInterrupt:
            # First Ctrl-C — pause and confirm before killing the agent.
            prep.stop(ok=False)  # clear the spinner if it is still up
            if _confirm_stop() == "stop":
                raise KeyboardInterrupt  # run_task terminates the runner
            print("  " + sub("… resuming"))
            print()
            continue  # re-enter the read loop — the agent kept running
        break  # stdout closed → the runner exited

    prep.stop(ok=False)  # no-op if already stopped; covers an early exit
    proc.wait()
    return recent


def _confirm_stop() -> str:
    """First Ctrl-C during a run — confirm before stopping the agent.
    Returns 'stop' (kill it, back to the prompt) or 'resume' (keep watching).
    The runner keeps running while this prompt waits."""
    print()
    print("  " + _c("⏸", YELLOW) + "  " + eyebrow("stop the agent?"))
    print("     " + sub("Ctrl-C again — stop · Enter — resume watching"))
    try:
        input("  " + ink("›") + " ")
    except (KeyboardInterrupt, EOFError):
        print()
        return "stop"
    return "resume"


def _gutter(label: str, text: str, *, label_code: str = DIM,
            text_code: str | None = None, wrap: bool = False) -> None:
    """Print an indented 'LABEL  text' line — the label sits in a fixed
    mono-caps gutter (the site's specimen-label motif), the text beside it."""
    gutter = "  " + _c(f"{label.upper():<5}", label_code) + "  "  # 2+5+2 = 9 cols
    cont = " " * 9
    paint = (lambda s: _c(s, text_code)) if text_code else (lambda s: s)
    if wrap:
        import textwrap
        rows = textwrap.wrap(" ".join(text.split()), width=WIDTH - 7) or [""]
        print(gutter + paint(rows[0]))
        for extra in rows[1:]:
            print(cont + paint(extra))
    else:
        print(gutter + paint(text))


# ─────────────────────────────────────────────────────────────────────────────
# Running one task.
# ─────────────────────────────────────────────────────────────────────────────
def run_task(goal: str, *, env: dict, udid: str, device_name: str,
             platform_version: str, manifest_path: pathlib.Path,
             max_steps: int, task_timeout: int, verbose: bool) -> None:
    """Synthesise a one-off task, run the agent, and render its trajectory."""
    ts = time.strftime("%Y%m%d-%H%M%S")
    slug = re.sub(r"[^a-z0-9]+", "-", goal.lower()).strip("-")[:40] or "task"
    run_dir = REPO_ROOT / "results" / f"demo-{ts}-{slug}"
    run_dir.mkdir(parents=True, exist_ok=True)

    # A demo task is just a goal — no rubric. The runner is invoked WITHOUT
    # --evaluate below, so the LLM-as-a-judge never runs: demo mode is for
    # watching the agent, not scoring it.
    task = [{"name": f"demo-{ts}", "goal": goal}]
    tasks_file = run_dir / "task_input.json"
    tasks_file.write_text(json.dumps(task, indent=2), encoding="utf-8")

    print()
    print("  " + hr())
    print("  " + eyebrow("running"))
    for row in _wrap(goal, "  ").splitlines():
        print(ink(row))
    print("  " + hr())
    print()

    cmd = [
        sys.executable, str(AGENT),
        "--tasks", str(tasks_file),
        "--udid", udid,
        "--device-name", device_name,
        "--app-manifest", str(manifest_path),
        "--inprocess",
        # The demo already booted the simulator and seeded all 26 apps up
        # front (see seed_simulator). So the runner does none of that again
        # per task — it just connects and runs:
        #   --no-reset      skip the simulator shutdown/boot (the reboot only
        #                   matters for the benchmark's 133-task isolation;
        #                   seed data lives on disk and survives anyway)
        #   --no-reinstall  skip the per-task data wipe + reseed
        #   --skip-erase    skip the factory erase
        "--no-reset", "--no-reinstall", "--skip-erase",
        "--action-mode", "step",
        "--max-steps", str(max_steps),
        "--task-timeout", str(task_timeout),
        "--run-dir", str(run_dir),
    ]
    if platform_version:
        cmd += ["--platform-version", platform_version]

    proc = subprocess.Popen(
        cmd, cwd=str(REPO_ROOT), env=env,
        stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
        text=True, bufsize=1,
    )
    try:
        recent = stream_run(proc, verbose=verbose)
    except KeyboardInterrupt:
        # Ctrl-C while the agent runs — stop it cleanly and hand control back
        # to the prompt so the user can start a different task.
        proc.terminate()
        try:
            proc.wait(timeout=5)
        except subprocess.TimeoutExpired:
            proc.kill()
        print()
        print("  " + hr())
        print("  " + _c("✗", YELLOW) + "  " + eyebrow("interrupted") + "  "
              + sub("the agent was stopped"))
        return

    # Read the per-task result the runner wrote into the run directory.
    result = None
    for p in sorted(run_dir.glob("*/task.json")):
        try:
            result = json.loads(p.read_text(encoding="utf-8"))
            break
        except (json.JSONDecodeError, OSError):
            pass

    print()
    print("  " + hr())
    if result is None:
        print("  " + _c("✗", RED) + "  " + eyebrow("incomplete"))
        print("  " + sub("the run did not finish — recent log:"))
        for line in recent[-10:]:
            print(sub(f"    {line}"))
        print("  " + hr())
        print("  " + eyebrow("log") + "  " + sub(str(run_dir)))
        return

    status = result.get("status")
    answer = (result.get("agent_answer") or "").strip()
    steps = result.get("steps", "?")
    secs = result.get("wall_time_seconds")
    ok = status == "ok"
    sym = _c("✓", GREEN) if ok else _c("✗", RED)
    word = "done" if ok else str(status)
    meta = f"{steps} steps" + (f"  ·  {secs:.0f}s" if isinstance(secs, (int, float)) else "")

    print("  " + sym + "  " + eyebrow(word) + "    " + sub(meta))
    if answer:
        print()
        for ln in _wrap(answer, "  ").splitlines():
            print(ln)
    elif not ok:
        # Surface *why* it failed — wrapped, not truncated.
        print()
        why = str(result.get("error") or "the run did not complete").strip()
        for ln in _wrap(why, "  ").splitlines():
            print(sub(ln))
    print("  " + hr())
    print("  " + eyebrow("trajectory") + "  " + sub(str(run_dir)))


# ─────────────────────────────────────────────────────────────────────────────
# Main.
# ─────────────────────────────────────────────────────────────────────────────
def main() -> None:
    # Keep output line-buffered so the agent's trajectory streams live even
    # when stdout is piped (e.g. `demo.py | tee`), not just on a bare TTY.
    try:
        sys.stdout.reconfigure(line_buffering=True)
    except (AttributeError, ValueError):
        pass

    ap = argparse.ArgumentParser(
        description="iOSWorld demo mode — type a task, watch an agent drive an iPhone.")
    ap.add_argument("--provider", help="LLM provider (default: LLM_PROVIDER from .env)")
    ap.add_argument("--model", help="LLM model (default: LLM_MODEL from .env)")
    ap.add_argument("--task", help="Run this one task non-interactively, then exit.")
    ap.add_argument("--device-name", help="Simulator device name (default: DEVICE_NAME from .env)")
    ap.add_argument("--max-steps", type=int, default=50, help="Max agent steps (default: 50).")
    ap.add_argument("--task-timeout", type=int, default=600,
                    help="Per-task timeout in seconds (default: 600; 0 = none).")
    ap.add_argument("--no-appium", action="store_true",
                    help="Assume Appium is already running; do not start one.")
    ap.add_argument("--verbose", action="store_true",
                    help="Echo the runner's raw log lines beneath each step.")
    # Hidden child-process entrypoint used by seed_simulator().
    ap.add_argument("--internal-seed", metavar="UDID", help=argparse.SUPPRESS)
    args = ap.parse_args()

    if args.internal_seed:
        _run_internal_seed(args.internal_seed)
        return

    banner()

    env = load_env()
    # Resolve provider/model. Explicit --provider/--model win; otherwise fall
    # back to .env, and — in interactive mode — let the operator pick.
    explicit = bool(args.provider or args.model)
    provider = (args.provider or env.get("LLM_PROVIDER", "")).strip()
    model = (args.model or env.get("LLM_MODEL", "")).strip()
    if not explicit and not args.task:
        provider, model = pick_model(provider, model)
    if not provider or not model:
        die("No model configured.",
            "Pass --provider/--model, or set LLM_PROVIDER/LLM_MODEL in .env.")
    env["LLM_PROVIDER"], env["LLM_MODEL"] = provider, model

    key_var = PROVIDER_KEY.get(provider)
    if key_var and not env.get(key_var):
        die(f"{provider} is selected but {key_var} is not set.",
            f"Add {key_var} to .env (see .env.example).")

    # Pre-flight the model backend — a dead vLLM server or a rejected key
    # fails here, loudly, instead of hanging a task at 'connecting…'.
    verified = check_provider(provider, model, env)
    mark = _c("✓", GREEN) + " model ready  " if verified else eyebrow("model") + "  "
    print("  " + mark + sub(f"{provider} · {model}"))

    manifest_path = REPO_ROOT / (env.get("APP_MANIFEST") or "iphone/bootstrap/.app_manifest.json")
    if not manifest_path.is_absolute():
        manifest_path = REPO_ROOT / manifest_path
    if not manifest_path.exists():
        die("The benchmark apps are not built yet.",
            "Run ./iphone/bootstrap/bootstrap_ios_apps.sh first.")
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))

    device_name = args.device_name or env.get("DEVICE_NAME", "iPhone 17 Pro")

    udid, sim_name, ios_ver = find_simulator(env, manifest, device_name)
    if not _sim_has_apps(udid, manifest):
        die(f"The 26 benchmark apps are not installed on {sim_name}.",
            "Boot that simulator and run ./iphone/bootstrap/bootstrap_ios_apps.sh.")
    print("  " + _c("✓", GREEN) + " simulator ready  " + sub(f"{sim_name} · iOS {ios_ver}"))

    # Too many booted simulators starve RAM/CPU — every `simctl launch` during
    # seeding crawls (and apps can miss their seed window, forcing slow
    # retries). Warn, and hand over the exact command to free things up.
    booted = [d for d in _devices() if d.get("state") == "Booted"]
    others = [d for d in booted if d.get("udid") != udid]
    if len(others) >= 2:
        names = " ".join(f'"{d["name"]}"' if " " in d.get("name", "") else d["name"]
                          for d in others)
        print("  " + _c("!", YELLOW) + " " + sub(
            f"{len(booted)} simulators are booted — seeding and the agent will be"
            " slow."))
        print("    " + sub("free memory by shutting the others down:"))
        print("    " + _c(f"xcrun simctl shutdown {names}", DIM))

    # Bring the Simulator window forward so the operator can watch.
    subprocess.run(["open", "-a", "Simulator"], capture_output=True)

    appium_url = env.get("APPIUM_URL", "http://127.0.0.1:4723")
    appium_proc = ensure_appium(appium_url, auto_start=not args.no_appium)
    env["APPIUM_URL"] = appium_url

    common = dict(env=env, udid=udid, device_name=sim_name,
                  platform_version=env.get("PLATFORM_VERSION") or ios_ver,
                  manifest_path=manifest_path, max_steps=args.max_steps,
                  task_timeout=args.task_timeout, verbose=args.verbose)

    try:
        # Seed the whole iPhone ONCE, here, up front. After this the demo
        # never reseeds — every task runs against the live simulator as the
        # previous task left it (the runner is invoked with --no-reset /
        # --no-reinstall, see run_task). To get a fresh slate, quit and
        # relaunch.
        print()
        seed_simulator(udid, env)

        if args.task:
            run_task(args.task, **common)
        else:
            print()
            print("  " + sub("Type a task and press Enter, or 'q' to quit."))
            print()
            first = True
            while True:
                goal = textbox(prompt_examples=first)
                first = False
                if goal.lower() in ("q", "quit", "exit"):
                    break
                if not goal:
                    continue
                run_task(goal, **common)
                # Task finished — return gracefully to the prompt for the next.
                print()
                print("  " + sub("What next? Type another task, or 'q' to quit."))
                print()
    except KeyboardInterrupt:
        print()
    finally:
        if appium_proc is not None:
            appium_proc.terminate()
            try:
                appium_proc.wait(timeout=5)
            except subprocess.TimeoutExpired:
                appium_proc.kill()
    print()
    print("  " + sub("The simulator is left booted for you.") + "\n")


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        sys.exit(130)
    except BrokenPipeError:
        # The terminal window was closed mid-run — exit quietly, no traceback.
        sys.exit(0)
