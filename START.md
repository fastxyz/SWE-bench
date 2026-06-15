# START — the baseline/fvk/control FVK benchmark

This is the single onboarding document for running the `fvk_bench` benchmark on a fresh
Ubuntu machine, whether you are a human or a Claude session. Everything below is verified
against the actual CLI; commands are copy-pasteable.

## 1. What this is

A controlled benchmark on SWE-bench Verified instances. The default instance set is the
original 45-problem FVK subset; the full 500-problem Verified set is available with
`--instance-set verified500`. Each run may request any subset of the three arms.
**baseline**: a fresh agent session reads a real GitHub issue and fixes the checked-out
repo. **fvk**: a second session resumes the frozen baseline transcript
(`--resume --fork-session`) and audits the fix using the Formal Verification Kit
methodology. **control**: an independent fork of the same frozen baseline transcript
performs a standard careful code review — it isolates the FVK method from the generic
"spend a second session reviewing your work" effect. Solutions are git patches extracted
from the workspace and scored by the official SWE-bench Docker harness. Orchestration
lives in `fvk_bench/`; the experiment's pinned parameters live in `fvk_bench/config.py`.

The agent under test is selectable: **Claude Code** by default, or **OpenAI Codex**
(`gpt-5.5`) via `--agent codex`. Both run the identical three arms and are scored by the
same harness; results record their agent and live side by side. See §5 (“Choosing the
agent”) for the Codex prerequisites and the honest cross-agent caveats.

## 2. Prerequisites

- Ubuntu on **x86_64** (the pinned instances' prebuilt Docker images do not support arm64).
- **Claude Code CLI ≥ 2.1.169**, logged in with a subscription. Check with `claude --version`;
  log in with `claude` then `/login`. Benchmark sessions run with a scrubbed environment, so
  `ANTHROPIC_API_KEY` is ignored (and removed) — subscription auth is what gets used.
- **For `--agent codex` only:** the **Codex CLI** (check with `codex --version`), logged in
  with a **ChatGPT/Codex subscription** (`codex login`). Subscription auth is required to
  reach the pinned `gpt-5.5` — automated `codex exec` under plain API-key auth caps at
  gpt-5.4. The benchmark passes `--ignore-user-config`, so any local `~/.codex/config.toml`
  (model/provider/plugins/MCP) is ignored; only the subscription auth in `CODEX_HOME` is used.
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
access to run sessions — the 45 instances' public metadata is committed at
`fvk_bench/data/instances.json`, and the full 500-instance metadata is committed at
`fvk_bench/data/instances_verified500.json`. The `datasets` library is only exercised if
you re-vendor either file (`vendor-instances`) or when the eval harness fetches the
dataset at evaluation time. The two submodules under `third_party/` provide the
45-problem list and the FVK materials, so `git submodule update --init` is mandatory.

## 4. Sanity check

```bash
.venv/bin/python -m fvk_bench doctor --canary
# For Codex runs:
.venv/bin/python -m fvk_bench doctor --agent codex --canary
```

`doctor` verifies the host: the selected agent binary and version, git, Docker reachability,
x86_64, Python ≥ 3.10, importability of `swebench`/`datasets`, ~120 GB free disk, no
`CLAUDE.md` or `.claude/` anywhere above the workspace root, and warns if
`ANTHROPIC_API_KEY` is set. For `--agent codex`, it also requires `codex login status` to
report ChatGPT subscription auth rather than plain API-key auth. `--canary` additionally
runs a real session with the selected agent's pinned invocation shape and audits its
transcript for cleanliness. Claude's default canary uses the cheap 2-turn haiku model and
must advertise exactly the 5 pinned tools with no skills, MCP servers, or agent listings;
optional `--probe-model` runs that Claude canary with `claude-opus-4-8` instead. Codex's
canary uses the pinned production `gpt-5.5` path because that is the subscription access
that must be proven before a run. Use `--no-eval-checks` on a session-only machine to relax
the Docker requirement to a warning.

## 5. Run one problem — or any selection

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
- `run` executes the requested arms in one hermetic workspace: a fresh baseline session,
  then any requested review forks of its frozen transcript. Each arm is a 200-turn
  `claude-opus-4-8` session at max effort with a 4-hour timeout — budget possibly hours
  for one instance.
- `evaluate` runs every harvested patch for the arms recorded in `run_manifest.json`
  through the official dockerized test harness — minutes per instance once images are
  cached. Pass `--arms baseline,fvk` only when intentionally overriding an older manifest.
- `report` writes `scores.json`/`scores.md` for the run and refreshes `results/INDEX.md` —
  seconds.

Replace `--instances sympy__sympy-12489` with more IDs (`--instances ID ID ...`), with
`--batch batchN` or `--batch verifiedNNN` to pick a batch (see §6), or with `--all`.
Both `run` and `validate-gold` accept any of these. Browse the instance list with:

```bash
.venv/bin/python -m fvk_bench list                  # the 45 IDs, grouped by repo, with batch
.venv/bin/python -m fvk_bench list --run-id myrun   # annotated with per-arm statuses
.venv/bin/python -m fvk_bench list --instance-set verified500 --batch verified001
```

Reusing a `--run-id` resumes an interrupted run: completed arms are skipped, so the same
three commands process a single problem, a 45-set batch, or a full-Verified batch
incrementally. There are no silent automatic retries — a retry is a different sample — so
failed arms stay failed until you pass `--retry-failed` to `run`, and every attempt is
recorded in the instance manifest. `evaluate` takes no instance selection; it scores
whatever the run contains for the run's recorded arms.

**Choosing the agent.** `run` takes `--agent {claude,codex}` (default `claude`); the
default reproduces the original Claude experiment exactly. `--agent codex` runs the
same requested arms with OpenAI Codex (pinned `gpt-5.5`, reasoning effort `xhigh`, sandbox
`workspace-write`); add `--codex-bin` to point at a non-default binary. The agent is
recorded in `run_manifest.json` and Codex results live alongside Claude ones, so they never
overwrite each other — give each run its own `--run-id`. `validate-gold`, `evaluate`, and
`report` are agent-agnostic (they score patches and read manifests). Honest asymmetries to
keep in mind — compare **within** an agent (baseline vs fvk vs control), only loosely
**across** agents:

- Codex is a shell-execution agent, so the “no execution” rule is enforced by the **prompt**,
  not by withholding tools. Claude’s pinned 5-tool surface (no Bash) genuinely cannot run
  anything; Codex reads/searches via shell and could in principle run tests despite the
  instruction (the transcript audit records, but does not fail on, such attempts).
- Codex’s top reasoning tier `xhigh` is not identical to Claude’s `--effort max`.
- The two review arms fork the frozen baseline via `codex exec resume` plus a baseline-rollout
  snapshot/restore, rather than Claude’s `--resume --fork-session`.

The Codex arm is newly added — validate it on your machine
(`python -m fvk_bench doctor --agent codex --canary`, `pytest tests/fvk_bench/`, and one
smoke instance) before committing to a full batch.

## 6. Run a batch

### FVK 45 batches

The default 45-instance set is divided into five fixed 9-problem batches, each sized to
finish in one session; membership is the contract.

| batch  | instances |
|--------|-----------|
| batch1 | astropy__astropy-13398, django__django-10554, -11138, -11400, -11885, -12325, -12708, -13128, -13212 |
| batch2 | astropy__astropy-13579, django__django-13344, -13449, -13837, -14007, -14011, -14631, -15128, -15268 |
| batch3 | astropy__astropy-14369, django__django-15503, -15629, -15957, -16263, -16560, -16631, pylint-dev__pylint-4551, pylint-dev__pylint-8898 |
| batch4 | pydata__xarray-3993, pytest-dev__pytest-10356, -5787, -6197, sphinx-doc__sphinx-11510, -7590, -8548, -9229, -9461 |
| batch5 | pydata__xarray-6992, scikit-learn__scikit-learn-25102, sympy__sympy-12489, -13852, -13878, -14248, -16597, -17630, -18199 |

`python -m fvk_bench list` shows each instance's batch membership; add `--batch batch1` to
filter to one batch.

The four-command flow for a batch:

```bash
.venv/bin/python -m fvk_bench validate-gold --run-id batch1-$(hostname) --batch batch1
.venv/bin/python -m fvk_bench run --run-id batch1-$(hostname) --batch batch1 --max-parallel 3
.venv/bin/python -m fvk_bench evaluate --run-id batch1-$(hostname)
.venv/bin/python -m fvk_bench report --run-id batch1-$(hostname)
git add results/ && git commit -m "results: batch1 run on $(hostname)" && git push
```

**Parallelism.** `--max-parallel N` caps the number of instances running concurrently; as one
finishes the next starts (rolling, not wave). `1` is fully sequential (the default); `9` runs
the whole batch at once. Arms within a single instance always stay sequential — the fvk and
control arms fork the baseline's frozen transcript, so they cannot start until baseline
finishes. **Fairness note:** sequential (`--max-parallel 1`) is the canonical comparable mode.
Parallel sessions contend for CPU/RAM and subscription rate limits, which can affect session
behavior. Use the same setting across runs you intend to compare; the setting is recorded in
`run_manifest.json`. Note that interrupting a parallel run (Ctrl-C) is not immediate — in-flight
instances finish their remaining arms before the command exits, so prefer letting a batch
complete or size `--max-parallel` accordingly.

**Duration.** A sequential 9-problem batch (`--max-parallel 1`) runs roughly a working day of
wall clock: 3 arms × ~10–15 min/arm × 9 instances, plus variance from hard instances and
network. `--max-parallel 3` brings this to a few hours, machine and rate limits permitting.

**Interrupted?** Rerun the exact same `run` command — completed arms are skipped. Failed arms
rerun only when you add `--retry-failed` (every attempt is recorded in the instance manifest).

**Letting a Claude session drive a batch.** If you'd rather hand the whole flow to your own
Claude Code session, use the ready-made prompt in [START-PROMPT.md](START-PROMPT.md) — fill
in the instance set, batch name, arms, and parallelism cap and paste it.

### Full Verified 500 overnight batches

The full SWE-bench Verified set is exposed as `--instance-set verified500` and divided by
sorted instance id into fifty generated 10-instance batches: `verified001` through
`verified050`. For the planned overnight two-arm run, use `--arms baseline,fvk` and
`--max-parallel 3`; that runs up to three instances concurrently, so each 10-instance batch
finishes in roughly four rolling slots, subject to model rate limits and hard instances.

First verify the metadata and inspect a batch:

```bash
.venv/bin/python -m fvk_bench list --instance-set verified500 --batch verified001
```

Then run each batch with its own run id, commit, and push immediately after `report`, so a
crash or interrupted overnight test loses at most the active batch. Do not use
`--all` for this safety-oriented run; the 10-instance batch is the recovery boundary. The
loop below is sequential across batches, and because it runs with `set -euo pipefail`, a
failed validation, run, evaluation, commit, or push stops the loop before the next batch
starts:

```bash
set -euo pipefail

for n in $(seq -f "%03g" 1 50); do
  batch="verified${n}"
  run_id="${batch}-codex-$(hostname)-$(date +%y%m%d%H%M%S)"

  .venv/bin/python -m fvk_bench validate-gold \
    --instance-set verified500 --run-id "$run_id" --batch "$batch"
  .venv/bin/python -m fvk_bench run \
    --instance-set verified500 --run-id "$run_id" --batch "$batch" \
    --agent codex --arms baseline,fvk --max-parallel 3
  .venv/bin/python -m fvk_bench evaluate --run-id "$run_id"
  .venv/bin/python -m fvk_bench report --run-id "$run_id"

  git add "results/$run_id" results/INDEX.md
  git commit -m "results: ${batch} codex baseline fvk"
  git push
done
```

This produces 50 separate `results/<run-id>/` directories, 50 commits, and 50 pushes.
Because the run manifest records `arms: ["baseline", "fvk"]`, `evaluate` and `report` do
not expect or show the skipped `control` arm. The aggregate report for these runs includes
baseline→fvk flips; baseline→control flips and fvk-vs-control delta are intentionally
absent.

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
    solutions/             # solution_<arm>.patch for requested/completed arms
    reports/               # the sessions' <arm>_notes.md for requested/completed arms
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
dockerized harness with prebuilt images for scoring. For `--agent codex` the analogous
pins are model `gpt-5.5`, reasoning effort `xhigh`, sandbox `workspace-write`,
`--ignore-user-config` over the same scrubbed env, and subscription auth — but §5 lists
where the analogy is imperfect (no-execution is prompt-enforced, not tool-enforced).

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
fresh.
