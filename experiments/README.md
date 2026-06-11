# SWE-bench prompt experiments

A small, self-contained harness for testing whether changing the agent's prompt changes its
resolve rate on SWE-bench. One **preset** = one prompt strategy + one run config; one command
runs the agent, grades it, and files the results.

It drives [mini-swe-agent](https://github.com/SWE-agent/mini-swe-agent) as the agent and the
[SWE-bench](https://github.com/SWE-bench/SWE-bench) harness for grading, reusing the same cached
Docker images for both.

```
experiments/
├── presets/<preset>/
│   ├── prompt.md      # inject/replace: the text added to the agent's system prompt
│   ├── skeleton.md    # jointembed only: methodology skeleton (no prompt.md)
│   └── config.yaml    # model / subset / split / slice / workers / mode / k
├── data/<preset>/     # jointembed only, generated: references.yaml, prompts/<id>.md, test.parquet
├── results/<preset>/  # filled by run.sh: report.json, preds.json, meta.yaml, trajectories/
├── gen_prompts.py <preset>   # jointembed pre-step (calls the AI offline)
└── run.sh <preset>
```

## Prerequisites

- **Docker** — running, able to pull images. Each task runs in a SWE-bench Docker image; the
  harness pulls them on first use (~2–3 GB each, cached after). On Apple Silicon they run x86_64
  under emulation, which works but is slower.
- **Python 3.11** and [**uv**](https://github.com/astral-sh/uv) (`brew install uv`).
- An **LLM API key** for an OpenAI-compatible endpoint (this repo's presets use DeepSeek).

## Install (once)

From the repository root:

```bash
uv venv --python 3.11 .venv
source .venv/bin/activate
uv pip install swebench==4.1.0 mini-swe-agent==2.3.1
```

That pulls in everything the harness needs (the `datasets`, `litellm`, and `pyyaml` deps come
transitively). Then set your API key:

```bash
cp experiments/.env.example experiments/.env
# edit experiments/.env and set:  API_KEY=<your key>
```

(or `export API_KEY=<your key>` in the shell — both scripts check the shell env first). The key is
read at runtime and passed to litellm in memory only; it is never written into any tracked file.

The SWE-bench task datasets (issue text + gold patches, a few MB) are public and downloaded
automatically by `load_dataset` on first run, then cached under `~/.cache/huggingface/`.

## How to run

**Run every command from this `experiments/` directory** — the scripts resolve their own paths, so
you never switch between here and the repo root. Activate the venv once per shell:

```bash
cd experiments
source ../.venv/bin/activate
```

Normal (inject/replace) preset — one command runs the agent and grades it:

```bash
./run.sh baseline
```

`jointembed` preset — generate the per-task prompts first, then run:

```bash
./gen_prompts.py fvk-v7      # offline; calls the AI; writes data/fvk-v7/
./run.sh fvk-v7              # runs the agent on the augmented dataset, then grades
```

Not activating the venv? Call the interpreter explicitly, still from `experiments/`:

```bash
../.venv/bin/python gen_prompts.py fvk-v7
./run.sh fvk-v7              # run.sh uses ../.venv internally, no activation needed
```

Each `run.sh` is fresh (re-runs all instances) and writes `results/<preset>/` ending with a
`X/N resolved` line.

## The three modes

`mode` in a preset's `config.yaml` selects how the prompt reaches the agent:

- **`inject`** (default) — `prompt.md` is appended *after* the agent's default system prompt, so
  the agent keeps its base instructions and your text is added on top. `baseline/prompt.md` is
  empty (inject nothing → unchanged default); `fvk-v4/prompt.md` holds only the extra discipline.
- **`replace`** — `prompt.md` becomes the **entire** system prompt, fully overriding the default.
- **`jointembed`** — every task gets its *own* prompt (see below) instead of one shared system
  prompt. The preset holds `skeleton.md` and has no `prompt.md`.

## mode: jointembed (AI-generated per-task prompts)

`gen_prompts.py <preset>` is a two-stage offline pass, run **before** `run.sh`:

1. **Select** — for each test task, an AI picks the `k` most relevant solved issues from the config
   `subset` (minus the whole test slice, so the grading set never leaks in).
2. **Generate** — an AI folds each picked example's issue + gold patch into `skeleton.md` and writes
   a tailored prompt for that task.

Each generated prompt is appended to that task's `problem_statement` (mini has no per-instance
*system* prompt), and the result is written as a local dataset that `run.sh` feeds to the agent.
Grading is unchanged — it always uses the canonical `subset`.

Outputs land in `data/<preset>/` (always — no path to configure) and are inspectable / hand-editable
before you run, so you can edit and re-run:

- `references.yaml` — which examples were picked per task
- `prompts/<id>.md` — the generated guidance per task
- `test.parquet` — the augmented dataset

`gen_prompts.py` runs tasks in parallel (`workers` from config) and prints a **leakage sentinel**:
any picked example sharing a gold-patch file with its target, so you know which results carry an
asterisk. Tasks that error are skipped (and printed) — just re-run to fill them in.

## config.yaml

```yaml
model: deepseek/deepseek-v4-pro   # any litellm model id (openai/<name> for a custom OpenAI-compatible endpoint)
api_key: env:API_KEY              # env:NAME reads $NAME; the secret is never written to disk
api_base: https://api.deepseek.com  # optional; any OpenAI-compatible endpoint
subset: verified                  # verified | lite | full -- for jointembed, also the candidate pool
split: test                       # HF split; Verified has only `test`
slice: "0:10"                     # which instances (dataset order)
workers: 4                        # agent run parallelism; jointembed also parallelizes generation
mode: inject                      # inject | replace | jointembed
k: 3                              # jointembed only: examples picked per task
```

`model` / `api_base` / `api_key` are passed to litellm, so you can target DeepSeek, an
OpenAI-compatible gateway, or a self-hosted endpoint just by editing the config. `api_key: env:NAME`
keeps the key out of the file: it is resolved at runtime from `$NAME` (shell env) or
`experiments/.env` (gitignored) and passed to litellm in memory only — never written into any
tracked file or trajectory. Omit `api_key` to fall back to litellm's provider default env var (e.g.
`DEEPSEEK_API_KEY`). The same resolution is used by both `run.sh` and `gen_prompts.py`.

## Add a preset

```bash
mkdir presets/my-idea
# inject/replace: write presets/my-idea/prompt.md   (the text to inject)
# jointembed:     write presets/my-idea/skeleton.md (the methodology skeleton)
cp presets/baseline/config.yaml presets/my-idea/config.yaml   # then edit mode/model/slice/...
./run.sh my-idea
```

## Optional: HuggingFace token

Silences the "unauthenticated requests" warning and speeds up dataset downloads. The SWE-bench
datasets are public, so this is **not required** and the data is cached after the first load:

```bash
export HF_TOKEN=hf_...            # from https://huggingface.co/settings/tokens
# or: huggingface-cli login
# already cached? export HF_HUB_OFFLINE=1 to skip the network check entirely
```

## Presets & results so far (deepseek-v4-pro, Verified first 10)

| preset | strategy | resolved |
|---|---|---|
| `baseline` | nothing (default prompt) | 6/10 |
| `fvk-v4` | formal-verification (draft → FVK-check → regenerate) | — |
| `fvk-v5` | self-review (draft → review → regenerate) | — |
| `fvk-v6` | demonstration-guided (static) | — |
| `fvk-v7` | jointembed (AI-selected per-task examples) | — |

> Note: `fvk-v4`–`fvk-v6` were run before retrieval was implemented, so their numbers aren't a
> final verdict. `n=10` moves in 10% steps — treat all of these as directional, not conclusive.
