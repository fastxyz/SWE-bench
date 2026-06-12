# START — the 3-arm FVK benchmark

This is the single onboarding document for running the `fvk_bench` benchmark on a fresh
Ubuntu machine, whether you are a human or a Claude session. Everything below is verified
against the actual CLI; commands are copy-pasteable.

## 1. What this is

A controlled benchmark of Claude Code on 45 SWE-bench Verified instances, with three arms
per instance. **baseline**: a fresh Claude Code session reads a real GitHub issue and fixes
the checked-out repo. **fvk**: a second session resumes the frozen baseline transcript
(`--resume --fork-session`) and audits the fix using the Formal Verification Kit
methodology. **control**: an independent fork of the same frozen baseline transcript
performs a standard careful code review — it isolates the FVK method from the generic
"spend a second session reviewing your work" effect. Solutions are git patches extracted
from the workspace and scored by the official SWE-bench Docker harness. Orchestration
lives in `fvk_bench/`; the experiment's pinned parameters live in `fvk_bench/config.py`.

## 2. Prerequisites

- Ubuntu on **x86_64** (the pinned instances' prebuilt Docker images do not support arm64).
- **Claude Code CLI ≥ 2.1.169**, logged in with a subscription. Check with `claude --version`;
  log in with `claude` then `/login`. Benchmark sessions run with a scrubbed environment, so
  `ANTHROPIC_API_KEY` is ignored (and removed) — subscription auth is what gets used.
- **git**.
- **Docker** — needed only for `validate-gold` and `evaluate`, with ~120 GB free disk for
  instance images. You can run sessions on a machine without Docker (`doctor --no-eval-checks`).
- **Python ≥ 3.10**.

## 3. Setup

```bash
git clone https://github.com/fastxyz/SWE-bench
cd SWE-bench
git submodule update --init
python -m venv .venv
.venv/bin/pip install -e .
```

That single `pip install -e .` is sufficient: it installs the `swebench` package (the
evaluation harness) and all dependencies, including `datasets`. You do not need HuggingFace
access to run sessions — the 45 instances' public metadata is already committed at
`fvk_bench/data/instances.json`; the `datasets` library is only exercised if you ever
re-vendor that file (`vendor-instances`) or when the eval harness fetches the dataset at
evaluation time. The two submodules under `third_party/` provide the 45-problem list and
the FVK materials, so `git submodule update --init` is mandatory.

## 4. Sanity check

```bash
.venv/bin/python -m fvk_bench doctor --canary
```

`doctor` verifies the host: claude binary and version, git, Docker reachability, x86_64,
Python ≥ 3.10, importability of `swebench`/`datasets`, ~120 GB free disk, no `CLAUDE.md` or
`.claude/` anywhere above the workspace root, and warns if `ANTHROPIC_API_KEY` is set.
`--canary` additionally runs a real (cheap) 2-turn haiku session with the exact production
flags and audits its transcript for cleanliness: the session must advertise exactly the 5
pinned tools and contain no skills, MCP servers, or agent listings. Optional
`--probe-model` runs the canary with the pinned production model instead, confirming your
subscription can access `claude-opus-4-8` before you commit to a long run. Use
`--no-eval-checks` on a session-only machine to relax the Docker requirement to a warning.

## 5. Run one problem

The happy path, on a new machine, in order:

```bash
.venv/bin/python -m fvk_bench validate-gold --run-id myrun --instances sympy__sympy-12489
.venv/bin/python -m fvk_bench run --run-id myrun --instances sympy__sympy-12489
.venv/bin/python -m fvk_bench evaluate --run-id myrun
.venv/bin/python -m fvk_bench report --run-id myrun
```

- `validate-gold` scores the official gold patch for the instance in your Docker
  environment; it must resolve, or real scores from this machine are uninterpretable. The
  first invocation pulls the instance's prebuilt Docker image — expect minutes (longer on a
  slow connection).
- `run` executes the three arms sequentially in one hermetic workspace: a fresh baseline
  session, then two forks of its frozen transcript. Each arm is a 200-turn
  `claude-opus-4-8` session at max effort with a 4-hour timeout — budget possibly hours
  for one instance.
- `evaluate` runs every harvested patch through the official dockerized test harness —
  minutes per instance once images are cached.
- `report` writes `scores.json`/`scores.md` for the run and refreshes `results/INDEX.md` —
  seconds.

## 6. Run more, or all 45

Replace `--instances sympy__sympy-12489` with more IDs (`--instances ID ID ...`) or with
`--all` (both `run` and `validate-gold` accept either). Browse the instance list with:

```bash
.venv/bin/python -m fvk_bench list                  # the 45 IDs, grouped by repo
.venv/bin/python -m fvk_bench list --run-id myrun   # annotated with per-arm statuses
```

Reusing a `--run-id` resumes an interrupted run: completed arms are skipped, so the same
three commands process a single problem or the full 45 incrementally. There are no silent
automatic retries — a retry is a different sample — so failed arms stay failed until you
pass `--retry-failed` to `run`, and every attempt is recorded in the instance manifest.
`evaluate` takes no instance selection; it scores whatever the run contains.

## 7. What gets recorded

Durable artifacts are harvested into `results/<run_id>/` (committed to the repo):

```
results/<run_id>/
  run_manifest.json        # machine, claude version, model/effort/turns/tools, full flag
                           # set, prompt template hashes, git + submodule SHAs
  scores.json, scores.md   # per-instance × arm results + aggregates
  <instance_id>/
    manifest.json          # session ids, arm statuses, attempt counts, timings, usage
    prompts/               # the exact rendered prompts per arm
    solutions/             # solution_{baseline,fvk,control}.patch
    reports/               # the sessions' {baseline,fvk,control}_notes.md
    fvk/                   # the fvk arm's 5 artifacts
    review/                # the control arm's FINDINGS.md
    transcripts/           # full session transcripts, {arm}.jsonl.gz
    eval/                  # {arm}.report.json from the harness
```

`results/INDEX.md` aggregates across runs. Live workspaces live **outside** the repo —
default `~/.swe-fvk-runs/`, overridable via `FVK_BENCH_WORKSPACE` or `--workspace-root` —
so no machine-local `CLAUDE.md`/`.claude/` can leak into sessions. Workspaces are
disposable once a run is harvested; everything of record is under `results/`.

## 8. Fairness and limitations

Standardized across machines: the pinned model id `claude-opus-4-8` (not the drifting
`opus` alias), effort `max`, 200 turns per arm, exactly 5 tools
(`Read,Write,Edit,Glob,Grep` — no Bash, no network, no agents, no skills, no MCP), the
full flag set, an env scrubbed to a small allowlist (killing `ANTHROPIC_API_KEY` and any
`CLAUDE_*` overrides), a hermetic workspace shape, vendored byte-identical instance
inputs, both review arms forking the same frozen baseline transcript, and the official
dockerized harness with prebuilt images for scoring.

Not controllable: server-side sampling. The CLI exposes no seed, so two runs of the same
arm are two draws from the same distribution, and subscription-based runs cannot pin a
server-side model snapshot the way the API can. Consequences: compare machines at the
**aggregate** level (per-arm resolved counts, flip counts), never per instance; treat
repeat runs as first-class — give each a fresh `--run-id` and let `results/INDEX.md` show
the variance rather than hide it.

One honest caveat: sessions run with `--permission-mode bypassPermissions`. The tool
surface has no execution or network capability, but `Write`/`Edit` could technically write
outside the workspace via absolute paths. Prompts forbid it, a post-arm audit (workspace
tree hash + `git status`) detects out-of-bounds writes inside the workspace, and every
transcript is harvested and audited — but absolute-path writes elsewhere on the host are
outside detection scope.

## 9. Contributing results from another machine

Commit only your `results/<run_id>/` directory — machine identity, claude version, flags,
and prompt hashes are all in `run_manifest.json`, so nothing else needs to change. Never
edit prompts or `fvk_bench/config.py` between runs you intend to compare: prompt template
hashes and a config snapshot are recorded in every manifest, and a mismatch makes runs
incomparable. Run `report` before committing so `scores.*` and `results/INDEX.md` are
fresh. Do not push from automation; open a normal PR with the new run directory.
