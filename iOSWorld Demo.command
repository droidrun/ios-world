#!/bin/bash
#
#  iOSWorld Demo  —  double-click this file in Finder to start.
#
#  It opens the interactive demo in a Terminal window: type any task in plain
#  language and watch an LLM agent drive the iOS Simulator. Nothing to type at
#  a shell — Finder runs this for you, and the window closes itself when you
#  quit the demo (type 'q').
#
#  One-time prerequisites (same as the benchmark — see README.md):
#    1. ./scripts/setup_env.sh                     — Python + Appium deps
#    2. cp .env.example .env  and add an API key   — pick a model
#    3. ./iphone/bootstrap/bootstrap_ios_apps.sh   — build + install 26 apps
#
#  If macOS says the file is "from an unidentified developer", right-click it
#  in Finder and choose Open once — this only happens for downloaded copies.
#
cd "$(dirname "$0")" || { echo "Cannot locate the iOSWorld folder."; exit 1; }

printf '\033]0;iOSWorld Demo\007'   # name the Terminal window
clear

# Prefer the project virtualenv that scripts/setup_env.sh creates, so the demo
# (and the agent runner it spawns) see appium-python-client and the LLM SDKs.
if [ -f .venv/bin/activate ]; then
  # shellcheck disable=SC1091
  source .venv/bin/activate
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "Python 3 was not found. Install Apple's command-line tools first:"
  echo "    xcode-select --install"
  echo
  printf "Press Return to close this window. "
  read -r _
  exit 1
fi

python3 scripts/demo.py "$@"
status=$?

echo
if [ "$status" -eq 0 ]; then
  # Clean finish — close this Terminal window automatically so there's
  # nothing to tidy up. Identifies its own window by tty, so other Terminal
  # windows are left alone. If macOS blocks the AppleScript, the window just
  # stays open (harmless) and can be closed with ⌘W.
  echo "  Demo closed — see you next time."
  sleep 2
  tty_dev="$(tty)"
  osascript >/dev/null 2>&1 <<APPLESCRIPT
tell application "Terminal"
  repeat with w in windows
    repeat with t in tabs of w
      if tty of t is "${tty_dev}" then
        close w saving no
        return
      end if
    end repeat
  end repeat
end tell
APPLESCRIPT
else
  # Something went wrong — keep the window open so the message stays readable.
  echo "  The demo exited with an error (details above)."
  printf "  Press Return to close this window. "
  read -r _
fi
exit "$status"
