# Qwen3.5-35B-A3B vLLM Cluster Setup

This guide is for running the iOSWorld Qwen CUA+MCP agent against a
self-hosted vLLM OpenAI-compatible endpoint.

Use this model name for the benchmark:

```sh
Qwen/Qwen3.5-35B-A3B
```

The local runner also accepts this shorter alias:

```sh
qwen3.5-35B-a3
```

## What The Benchmark Expects

iOSWorld talks to Qwen through vLLM's OpenAI-compatible Chat Completions API.
For MCP+CUA runs, the request contains:

- the Qwen `mobile_use` tool first,
- task-scoped MCP function tools after it,
- screenshots on CUA turns,
- tool results returned as ordinary Chat Completions `tool` messages.

The vLLM server must therefore support automatic tool calling. For
Qwen3.5-35B-A3B, use the model-card tool-call command:

```sh
vllm serve Qwen/Qwen3.5-35B-A3B \
  --host 0.0.0.0 \
  --port 8000 \
  --served-model-name qwen3.5-35B-a3 \
  --tensor-parallel-size 8 \
  --max-model-len 132000 \
  --reasoning-parser qwen3 \
  --enable-auto-tool-choice \
  --tool-call-parser qwen3_coder
```

If `qwen3_coder` is missing, the vLLM build is too old for this Qwen3.5 tool
path. Install a current vLLM nightly/main build rather than silently switching
parsers.

## Cluster Request

Recommended starting request:

- 8 GPUs for the standard Qwen3.5-35B-A3B deployment. Request 132k context
  for iOSWorld runs unless a specific experiment needs the full 262k model-card
  setting.
- CUDA-capable nodes with enough aggregate VRAM for Qwen3.5-35B-A3B and KV
  cache at the requested context length.
- One exposed service port, normally `8000`.
- A shared Hugging Face cache or enough local disk for the model weights.

For constrained clusters, reduce `--max-model-len` first, for example 32768 or
65536. For very large-context experiments, the model card also shows 262144.
Keep the tool-calling flags unchanged.

## Install Environment

On the cluster node:

```sh
module load cuda || true
python -m venv .venv-qwen-vllm
source .venv-qwen-vllm/bin/activate
pip install -U pip uv
uv pip install vllm --torch-backend=auto --extra-index-url https://wheels.vllm.ai/nightly
uv pip install -U openai
```

If your cluster already provides a vetted vLLM module or container, use that,
but confirm it exposes `--tool-call-parser qwen3_coder`:

```sh
vllm serve --help | grep -E "tool-call-parser|qwen3_coder"
```

## Slurm Example

Save as `serve_qwen35_vllm.slurm` and adjust partition/account names:

```bash
#!/usr/bin/env bash
#SBATCH --job-name=qwen35-vllm
#SBATCH --nodes=1
#SBATCH --gres=gpu:8
#SBATCH --cpus-per-task=32
#SBATCH --mem=0
#SBATCH --time=24:00:00
#SBATCH --output=qwen35-vllm-%j.log

set -euo pipefail

module load cuda || true
source .venv-qwen-vllm/bin/activate

export HF_HOME="${HF_HOME:-$HOME/.cache/huggingface}"
export VLLM_WORKER_MULTIPROC_METHOD=spawn

vllm serve Qwen/Qwen3.5-35B-A3B \
  --host 0.0.0.0 \
  --port 8000 \
  --served-model-name qwen3.5-35B-a3 \
  --tensor-parallel-size 8 \
  --max-model-len "${MAX_MODEL_LEN:-132000}" \
  --reasoning-parser qwen3 \
  --enable-auto-tool-choice \
  --tool-call-parser qwen3_coder
```

Submit:

```sh
sbatch serve_qwen35_vllm.slurm
squeue -u "$USER"
tail -f qwen35-vllm-<jobid>.log
```

The server is ready when `/v1/models` responds.

## Connect From The iOSWorld Machine

If the cluster node is not directly reachable, forward the port:

```sh
ssh -N -L 8000:<compute-node-hostname>:8000 <cluster-login-host>
```

Then configure iOSWorld locally:

```sh
export LLM_PROVIDER=vllm
export LLM_MODEL=qwen3.5-35B-a3
export VLLM_BASE_URL=http://localhost:8000/v1
export VLLM_API_KEY=EMPTY
```

The OpenAI SDK-compatible variables also work for quick probes:

```sh
export OPENAI_BASE_URL=http://localhost:8000/v1
export OPENAI_API_KEY=EMPTY
```

## Smoke Test vLLM Tool Calling

Run this from the iOSWorld machine after the tunnel is up:

```sh
python - <<'PY'
from openai import OpenAI

client = OpenAI(base_url="http://localhost:8000/v1", api_key="EMPTY")
resp = client.chat.completions.create(
    model="qwen3.5-35B-a3",
    messages=[{"role": "user", "content": "Use the tool to click the center of the screen."}],
    tools=[{
        "type": "function",
        "function": {
            "name": "mobile_use",
            "description": "Interact with a mobile screen.",
            "parameters": {
                "type": "object",
                "properties": {
                    "action": {"type": "string", "enum": ["click"]},
                    "coordinate": {
                        "type": "array",
                        "items": {"type": "integer"},
                        "minItems": 2,
                        "maxItems": 2
                    }
                },
                "required": ["action", "coordinate"]
            }
        }
    }],
    tool_choice="auto",
)
msg = resp.choices[0].message
print("content:", msg.content)
print("tool_calls:", msg.tool_calls)
PY
```

You should see a `tool_calls` entry. If it is always plain text, check that the
server was launched with both `--enable-auto-tool-choice` and
`--tool-call-parser qwen3_coder`.

## iOSWorld Dry Run

On the iOSWorld machine, run `./scripts/setup_env.sh` once before using the
`.venv/bin/python` commands below.

This validates task app scoping and provider-visible MCP tool schemas without
calling the model:

```sh
.venv/bin/python scripts/mcp_agent_runner.py \
  --task "Open Clock and tell me how many alarms are visible." \
  --apps clock \
  --model qwen3.5-35B-a3 \
  --with-cua \
  --dry-run-tools \
  --transport in_memory \
  --artifact-dir /tmp/iosworld-qwen-dry
```

## iOSWorld Live Smoke

Use a booted iPhone simulator and a running Appium server:

```sh
.venv/bin/python scripts/mcp_agent_runner.py \
  --task "Open Clock and tell me how many alarms are visible." \
  --apps clock \
  --model qwen3.5-35B-a3 \
  --with-cua \
  --max-steps 4 \
  --artifact-dir results/qwen35_vllm_smoke
```

For benchmark tasks through the main runner:

```sh
scripts/run_task_by_id.sh clock-001 \
  --mcp \
  --mcp-cua \
  --mcp-model qwen3.5-35B-a3
```

## Context And Tool Payload Rules

- Do not expose all app tools for normal runs. The runner scopes MCP tools to
  the task's involved apps.
- Keep expanded confirmation-pair tools off unless the experiment needs them.
- For Qwen3.5 context pressure, reduce `--max-model-len` only on the vLLM
  server if memory requires it; do not compensate by adding more screenshot
  history or all-app tools.
- Keep `mobile_use` as the first tool and MCP app tools after it. The runner
  does this automatically.

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `tool_calls` is empty | vLLM was not launched with auto tool choice or the Qwen parser | Add `--enable-auto-tool-choice --tool-call-parser qwen3_coder` |
| `qwen3_coder` is not accepted | vLLM build is too old | Install current vLLM nightly/main |
| API connection refused | Tunnel or compute-node service is not reachable | Check `/v1/models`, Slurm log, and SSH forwarding |
| CUDA OOM at startup | Context/KV cache too large | Lower `--max-model-len`, then restart |
| Model name not found | Served name and client model differ | Use `--served-model-name qwen3.5-35B-a3` and client model `qwen3.5-35B-a3` |

## References

- Qwen3.5-35B-A3B model card: https://huggingface.co/Qwen/Qwen3.5-35B-A3B
- vLLM Qwen3.5/Qwen3.6 recipe: https://docs.vllm.ai/projects/recipes/en/latest/Qwen/Qwen3.5.html
- vLLM tool-calling guide: https://docs.vllm.ai/en/latest/features/tool_calling/
- Qwen function-calling guide: https://qwen.readthedocs.io/en/latest/framework/function_call.html
