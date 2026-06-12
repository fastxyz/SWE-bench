# Design: 3-Arm Claude Code Benchmarking Infrastructure (baseline / fvk / control)

**Date:** 2026-06-12
**Status:** Draft for review
**Repo:** fastxyz/SWE-bench (this repo)

## Goal

A controlled, reproducible benchmarking infrastructure that orchestrates and evaluates
Claude Code sessions across 45 SWE-bench Verified problems using three experimental arms,
maximizing session standardization and fairness across machines that run local Claude Code
subscriptions (not the API).

The three arms simulate:

- **baseline** — a user solves a GitHub issue with a fresh Claude Code session and submits a fix (V1).
- **fvk** — continuing from baseline, the user invokes the Formal Verification Kit (FVK) methodology
  as a code-review pass, lists findings, and submits a revised (or confirmed) fix (V2-fvk).
- **control** — independently continuing from baseline (unaware of FVK), the user invokes a standard
  careful code review, lists findings, and submits a revised (or confirmed) fix (V2-control).

The control arm isolates the effect of the FVK *methodology* from the effect of
"spend a second session reviewing your own work."

## Key facts discovered during recon

- The 45 problems are SWE-bench **Verified** instances, defined by the 45 files in
  `prompts/<instance_id>.md` of `fastxyz/swebench-fvk-reproducibility`
  (22 django, 7 sympy, 5 sphinx, 3 astropy, 3 pytest, 2 xarray, 2 pylint, 1 scikit-learn).
- Solutions for SWE-bench instances are **git patches** (often multi-file), evaluated by this repo's
  official harness `swebench.harness.run_evaluation` in Docker against `model_patch` predictions.
- The FVK method docs live in `grosu/formal-verification-kit`:
  `README.md`, `AGENTS.md`, `commands/formalize.md`, `commands/verify.md`,
  plus `knowledge/*.md` primers that `AGENTS.md`'s BOOTSTRAP step mandates.
- Local Claude CLI (tested with 2.1.169) supports all required flags:
  `--fork-session`, `--tools`, `--effort max`, `--session-id`, `--resume`,
  `--strict-mcp-config`, `--setting-sources`, `--disable-slash-commands`, `--output-format json`.

## Decisions already confirmed with the owner

1. **Solutions are git patches** (`solutions/solution_<arm>.patch`), not single `.py` files.
   Claude edits the checked-out repo directly; the orchestrator extracts diffs.
2. **Session tool set:** `Read,Write,Edit,Glob,Grep` — read-only search/navigation included,
   zero execution and zero network capability. No Bash, no WebSearch, no Task/agents.
3. **Live session workspaces live outside the repo** (default `~/.swe-fvk-runs/`);
   durable artifacts are harvested into the repo under `results/` and committed.
4. The FVK arm prompt's Tasks block is the owner's text **verbatim**
   (read the 4 `fvk_materials/` docs; produce the 5 `fvk/` artifacts).
5. The control prompt is written from scratch, **structurally identical** to the fvk prompt
   except the methodology (standard careful code review; no FVK materials anywhere).

## Architecture

Approach: a small, self-contained Python package in this repo (no changes to the existing
`swebench/` package), with a subcommand CLI, vendored instance data, and a deterministic
per-instance state machine. Alternatives considered and rejected: a bash script suite
(fragile JSON/state handling, untestable at 45×3 scale) and extending the reproducibility
repo's `run_clean_twin_queue.py` (HumanEval-specific, ad-hoc scripts explicitly excluded).

### Repo layout

```
fvk_bench/                          # new top-level Python package
  __init__.py
  __main__.py                       # python -m fvk_bench
  cli.py                            # subcommands: doctor, list, run, evaluate, report, vendor-instances
  config.py                         # all knobs: model, effort, max-turns, tools, paths, timeouts
  instances.py                      # vendored instance metadata access
  scaffold.py                       # workspace construction, bare-mirror repo cache
  claude_runner.py                  # the ONLY place `claude` is invoked
  arms.py                           # baseline → fvk → control state machine + git choreography
  evaluate.py                       # official harness invocation + score harvest
  harvest.py                        # workspace → results/ copier + manifest writer
  prompts/
    baseline.md                     # versioned prompt templates with {placeholders}
    fvk.md
    control.md
  data/
    instances.json                  # vendored PUBLIC fields of the 45 instances
tests/fvk_bench/                    # unit tests with a fake `claude` binary
third_party/
  swebench-fvk-reproducibility/     # submodule — source of truth for the 45 problem IDs
  formal-verification-kit/          # submodule — source of fvk_materials/
results/
  .gitignore                        # re-includes *.patch / *.jsonl (root .gitignore excludes them)
  <run_id>/...                      # committed run artifacts (schema below)
START.md                            # how anyone (human or Claude session) starts testing
```

### Vendored instance data (`fvk_bench/data/instances.json`)

Generated by a maintainer command `python -m fvk_bench vendor-instances` from
`princeton-nlp/SWE-bench_Verified` (test split) and committed. Contains **public fields only**:

- `instance_id`, `repo`, `base_commit`, `version`, `problem_statement`, `hints_text`
- `fail_to_pass_count`, `pass_to_pass_count` (**counts only** — never test names)

Gold patches and `test_patch` never enter this repo or any workspace; the evaluation harness
fetches the dataset itself at eval time. Benefits: `run` needs no HuggingFace access, every
machine scaffolds byte-identical problem inputs, and hidden-test discipline is structural
rather than prompt-enforced. The 45-ID list is read from the submodule's `prompts/*.md`
filenames and cross-checked against `instances.json` at startup.

## Workspace lifecycle

Default root: `~/.swe-fvk-runs/` (configurable via `--workspace-root` / env `FVK_BENCH_WORKSPACE`).
Per instance: `~/.swe-fvk-runs/<run_id>/<instance_id>/`:

```
benchmark/PROBLEM.md     # problem statement + hints, rendered from vendored data
benchmark/instance.json  # public metadata incl. "resolved iff X/Y" counts
repo/                    # git checkout at base_commit (detached HEAD), from local mirror cache
reports/                 # sessions write {baseline,fvk,control}_notes.md here
fvk/                     # fvk arm writes its 5 artifacts here
review/                  # control arm writes FINDINGS.md here
fvk_materials/           # exists ONLY while the fvk arm runs (injected, then removed)
.fvk_bench/              # orchestrator-private: state.json, rendered prompts, raw claude JSON results
```

Target repos are cloned once into `~/.swe-fvk-runs/cache/repos/<org>__<repo>.git` (bare mirror,
fetched on demand) and checked out locally per instance — 22 django instances ≠ 22 GitHub clones.

**Why outside the repo:** Claude Code loads `CLAUDE.md` / `.claude/` from the cwd's ancestry.
A workspace under the user's repo tree would leak machine-specific context into sessions.
An external root guarantees an identical, hermetic cwd shape on every machine.

## Arm state machine and git choreography

Order per instance: **baseline → fvk → control**, all three in the **same cwd**
(resumed transcripts reference workspace-relative paths, which must stay valid), with
deterministic resets between arms:

1. **baseline** — fresh session with pre-generated `--session-id` (uuid4, recorded before launch).
   Claude edits `repo/`, writes `reports/baseline_notes.md`.
   Orchestrator extracts: `git add -A` → `git diff --cached --binary HEAD` →
   `solutions/solution_baseline.patch` (staging first captures newly created files), then resets staging.
   Record post-baseline workspace tree hash H1 (all files except `.fvk_bench/`).
2. **scrub & stage for fvk** — `git reset --hard <base_commit>` + `git clean -fdx`, re-apply
   `solution_baseline.patch`; copy FVK docs into `fvk_materials/`:
   `README.md`, `AGENTS.md`, `commands/formalize.md`, `commands/verify.md`, `knowledge/*.md`
   (the 4 entry docs the prompt names, plus the knowledge primers `AGENTS.md` mandates — the kit
   is self-contained, the agent never needs to leave the workspace).
3. **fvk** — `--resume <baseline-session-id> --fork-session`. Claude audits V1, writes the 5
   `fvk/` artifacts + `reports/fvk_notes.md`, edits `repo/` if revising.
   Orchestrator extracts the cumulative diff-from-base → `solutions/solution_fvk.patch`.
4. **scrub & stage for control** — harvest fvk artifacts, then **remove** `fvk_materials/`, `fvk/`,
   `reports/fvk_notes.md`; reset `repo/` to base + re-apply the baseline patch.
   Orchestrator **asserts** the workspace tree hash now equals H1 — a scrub bug aborts the arm
   rather than silently contaminating the control.
5. **control** — `--resume <baseline-session-id> --fork-session` (a second, independent fork of the
   same frozen baseline transcript). Claude reviews V1, writes `review/FINDINGS.md` +
   `reports/control_notes.md`, edits `repo/` if revising → `solutions/solution_control.patch`.

Design notes:

- **fvk-before-control is deliberate:** if the scrub ever failed, FVK material could only leak
  *into* the control arm, which biases the experiment **against** FVK's measured advantage —
  the conservative failure direction.
- Both forks branch from the identical frozen baseline transcript, so arm order has no other effect.
- Arm statuses: `completed | failed(<reason>) | skipped`. **No silent automatic retries** — a retry
  is a different sample. `run --retry-failed` re-runs failed arms explicitly; every attempt is
  counted in the manifest.
- If the baseline arm produced an empty diff, the run is still carried through (review arms review
  "no change"; predictions with empty patches are recorded as unresolved at eval time, not dropped).

## Claude invocation contract (the standardization core)

One function in `claude_runner.py` builds every invocation:

```bash
cd <workspace> && env -i \
    HOME="$HOME" PATH="$PATH" USER="$USER" TERM=dumb LANG=C.UTF-8 TZ=UTC \
  claude -p "$(cat .fvk_bench/prompts/<arm>.md)" \
    --model claude-opus-4-8 \
    --effort max \
    --max-turns <60|40|40> \
    --output-format json \
    --permission-mode bypassPermissions \
    --setting-sources project,local \
    --disable-slash-commands \
    --tools 'Read,Write,Edit,Glob,Grep' \
    --strict-mcp-config --mcp-config '{"mcpServers":{}}' \
    [--session-id <uuid4>          # baseline]
    [--resume <baseline-id> --fork-session   # fvk and control]
```

- **Model pinned** to `claude-opus-4-8` (not the `opus` alias, which drifts across releases).
  Configurable in `config.py`, recorded in every manifest.
- **Effort `max`** (CLI supports low/medium/high/xhigh/max).
- **Turn budgets:** baseline 60; fvk 40; control 40. fvk and control budgets are **always equal**
  (control validity). All configurable; recorded in manifests.
- **`env -i` allowlist** eliminates environment drift: kills `ANTHROPIC_API_KEY` (which would
  silently switch billing to the API), `CLAUDE_*`/`MAX_THINKING_TOKENS` overrides, and
  locale/timezone differences.
- **`--setting-sources project,local`** excludes user-level settings; the workspace contains no
  project settings at all, and no `CLAUDE.md` exists anywhere in its ancestry.
- **`--strict-mcp-config --mcp-config '{"mcpServers":{}}'`** guarantees zero MCP servers;
  `--disable-slash-commands` disables all skills; `--tools` restricts to exactly 5 built-ins.
- **Session IDs:** baseline's uuid4 is pre-generated and recorded *before* launch (known even on
  crash). Fork session IDs are parsed from the JSON result envelope. After each arm, the full
  session transcript (`~/.claude/projects/<munged-cwd>/<session-id>.jsonl`) is harvested and
  gzipped into results — audit evidence of exactly what each session saw and did.
- **Prompt delivery:** prompt text is passed via argv from the rendered file; the rendered file is
  the artifact of record.
- **Timeout:** per-arm wall-clock timeout (default 2h) so a hung session cannot stall the queue;
  timeouts are recorded as `failed(timeout)`.
- Sequential execution only (one session at a time) — subscription rate limits and machine-load
  fairness; `run` accepts multiple instances and loops.

### Preflight: `python -m fvk_bench doctor`

- `claude` present; version printed and recorded (warn if ≠ the version this infra was tested with).
- git, docker (eval only), `datasets`/`swebench` importable, disk space check (eval needs ~120GB free).
- Workspace-root ancestry contains no `CLAUDE.md` / `.claude/` directories.
- Warns if `ANTHROPIC_API_KEY` is set (it will be scrubbed anyway).
- Optional `--canary`: runs a 1-turn haiku session in a temp workspace with the exact production
  flags, then inspects its transcript to assert the available tool set is exactly our 5 tools and
  no MCP/skill/agent-listing attachments are present — empirical per-machine session-cleanliness check.

### Honest limitations (documented in START.md)

- With `--permission-mode bypassPermissions`, the `Write`/`Edit` tools could technically write
  outside the workspace via absolute paths. Sessions have no Bash and no network; prompts forbid it;
  a post-arm audit (workspace tree hash + `git status`) detects out-of-bounds writes *inside* the
  workspace; absolute-path writes elsewhere on the host are outside detection scope.
- Subscription-based runs cannot pin the server-side model snapshot the way the API can; we pin the
  model ID, CLI version, flags, prompts, and inputs, and record everything else.
- `--effort max` thinking budgets are whatever the subscription grants for `claude-opus-4-8`;
  recorded, not controllable.

## Prompts

Three versioned templates in `fvk_bench/prompts/`, rendered per instance with placeholders
(`{instance_id}`, `{repo}`, `{base_commit}`, `{resolved_iff}`). All three share one skeleton:

1. instance header (repo, base commit, where things are)
2. allowed inputs (explicit whitelist of workspace paths)
3. forbidden inputs (no internet/external data, no gold fix knowledge, no hidden tests, no test
   execution — "there are intentionally no test results available; do not infer or ask for them")
4. tasks
5. output discipline (do not modify test files; do not create files outside the named outputs;
   stop only after all named files are written)

- **baseline.md** — read `benchmark/PROBLEM.md`, locate the root cause in `repo/`, implement the
  fix by editing `repo/` directly (multi-file edits allowed), write `reports/baseline_notes.md`
  (root cause, fix rationale, assumptions).
- **fvk.md** — "Continue from the same context…" framing (adapted from the owner's v2 example);
  the owner's Tasks block **verbatim**:
  read `fvk_materials/README.md`, `fvk_materials/AGENTS.md`, `fvk_materials/commands/formalize.md`,
  `fvk_materials/commands/verify.md`; produce `fvk/SPEC.md`, `fvk/FINDINGS.md`,
  `fvk/PROOF_OBLIGATIONS.md`, `fvk/PROOF.md`, `fvk/ITERATION_GUIDANCE.md`.
  Then: revise or confirm the V1 fix by editing `repo/` (an unchanged V1 must be justified by the
  FVK artifacts), and write `reports/fvk_notes.md` tracing every decision to specific findings /
  proof obligations.
- **control.md** — byte-identical skeleton to fvk.md except the methodology section: perform a
  careful, standard code review of the V1 fix (correctness, edge cases, error handling, regressions,
  API-contract adherence), write findings to `review/FINDINGS.md`, revise or confirm by editing
  `repo/` (an unchanged V1 must be justified by the review findings), and write
  `reports/control_notes.md` tracing every decision to specific findings. No mention of FVK;
  no `fvk_materials/` exists in its workspace view.

Prompt templates are content-hashed; hashes land in `run_manifest.json` so cross-machine runs can
prove they used identical prompts.

## Evaluation & scoring

`python -m fvk_bench evaluate --run-id X` (separate phase; requires Docker + network):

1. For each arm, build a predictions JSONL:
   `{"instance_id", "model_name_or_path": "<run_id>__<arm>", "model_patch"}`.
2. Invoke the official harness once per arm:
   `python -m swebench.harness.run_evaluation --dataset_name princeton-nlp/SWE-bench_Verified
   --predictions_path <arm>.jsonl --run_id <run_id>.<arm> --instance_ids ...`
   (max_workers configurable; default 4).
3. Harvest each instance's `report.json` (resolved flag, FAIL_TO_PASS / PASS_TO_PASS outcomes →
   stored as counts) into `results/`.
4. `python -m fvk_bench report --run-id X` renders `scores.md`: per-instance × arm table
   (resolved, FTP x/y, PTP x/y) + aggregates (resolved counts per arm, baseline→fvk and
   baseline→control flips, fvk-vs-control delta).

Evaluation runs only after all arms of the selected instances are frozen — no arm ever observes
test results (matching the reproducibility protocol's "no test results available" discipline).

## Results schema (committed to the repo)

```
results/<run_id>/
  run_manifest.json        # machine info (os, arch), claude CLI version, model id, effort,
                           # turn budgets, tool list, full flag set, config snapshot,
                           # prompt template hashes, fvk_bench git sha, submodule shas
  scores.json              # machine-readable per-instance × arm results
  scores.md                # human-readable table + aggregates
  <instance_id>/
    manifest.json          # session ids (baseline + 2 forks), arm statuses & attempt counts,
                           # timings, num_turns, usage stats from JSON envelopes, tree hashes,
                           # patch line counts
    prompts/{baseline,fvk,control}.md          # exact rendered prompts
    solutions/solution_{baseline,fvk,control}.patch
    reports/{baseline,fvk,control}_notes.md
    fvk/                   # the 5 FVK artifacts
    review/FINDINGS.md
    transcripts/{baseline,fvk,control}.jsonl.gz
    eval/{baseline,fvk,control}.report.json
```

`results/.gitignore` re-includes `*.patch` and `*.jsonl*` (the repo root `.gitignore` excludes them globally).

## Testing strategy (for the infra itself)

- Unit tests with a **fake `claude` executable** on PATH (records argv + env to a file, emits a
  canned JSON envelope, writes canned workspace files): flag construction per arm, env allowlist,
  session-id pre-generation and fork-id parsing, patch extraction including new-file staging,
  scrub + tree-hash assertion, failure paths (nonzero exit, timeout, malformed JSON), harvest layout.
- Git choreography tests against a tiny local fixture repo (no network).
- `vendor-instances` and `evaluate` are thin shims over `datasets`/the harness; tested with mocks.
- One optional live smoke test (haiku, 2 turns) behind `FVK_BENCH_LIVE_TEST=1` — never in CI.

## Delivery sequence

1. Implement; push infra + submodules + START.md to `main`.
2. Run **one** problem end-to-end as a live validation — `sympy__sympy-12489` (small repo, fast
   eval) — with the pinned production settings; run `evaluate`; push its `results/<run_id>/`.
3. `START.md` covers: prerequisites (Ubuntu, Claude Code subscription + login, git, Docker,
   `pip install -e .`), `git submodule update --init`, `doctor`, the exact three commands
   (`run` → `evaluate` → `report`), how to select instances, and how to contribute results from a
   new machine (one directory per `run_id`; machine identity in `run_manifest.json`).

## Out of scope (YAGNI)

- Parallel Claude sessions, API-based runs, Modal/cloud evaluation, statistical analysis tooling,
  multi-model comparisons, automatic prompt tuning. The schema records enough to add any of these later.
