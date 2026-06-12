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
4. **Prompt design is a dedicated deliverable.** The fvk arm reads the same 4 `fvk_materials/`
   docs and produces the same 5 `fvk/` artifacts as the owner's reference protocol, but all
   prompt text is carefully designed for this benchmark — the owner's HumanEval v2 example is a
   structural reference (allowed/forbidden-inputs framing), not copied verbatim.
5. The control prompt is written from scratch, **structurally identical** to the fvk prompt
   except the methodology (standard careful code review; no FVK materials anywhere).
6. **Turn budget 200 for all three arms** — these are hard problems; the ceiling must not bind.
7. **Customized skills are banned as hard as the CLI allows** (defense in depth, verified
   empirically per machine via the doctor canary).

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
  cli.py                            # subcommands: doctor, list, run, evaluate, validate-gold, report, vendor-instances
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
  .gitignore                        # re-includes *.patch, *.jsonl, *.jsonl.* (root .gitignore excludes them)
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
benchmark/instance.json  # public metadata: repo, base_commit, version — no test info of any kind
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

## CLI surface (running selected problems must be easy)

```
python -m fvk_bench list                         # the 45 IDs, grouped by repo, with status per run
python -m fvk_bench doctor [--canary] [--probe-model]
python -m fvk_bench validate-gold --run-id X --instances ID [ID...] | --all
python -m fvk_bench run        --run-id X --instances ID [ID...] | --all  [--arms ...] [--retry-failed]
python -m fvk_bench evaluate   --run-id X
python -m fvk_bench report     --run-id X
```

- `--instances` takes one or more exact instance IDs; `--all` selects all 45. IDs are validated
  against the list derived from the submodule before anything runs.
- `--run-id` defaults to `<UTC-timestamp>-<hostname>`; reusing a run-id resumes it (completed
  arms are skipped, so a single problem or the full 45 can be processed incrementally with the
  same three commands).
- `run` executes scaffold → 3 arms → harvest per instance; `evaluate` and `report` operate on
  whatever instances the run contains. The happy path for "test one problem" is exactly:
  `run --instances X`, `evaluate`, `report`.
- `report` writes `scores.md`/`scores.json` covering **every instance in the run × every arm** —
  failed or skipped arms appear explicitly as `failed(<reason>)`/`skipped`, never omitted — and
  refreshes a cross-run `results/INDEX.md` (run_id, machine, model, instance count, per-arm
  resolved totals) so all documented results are discoverable from one file.

## Claude invocation contract (the standardization core)

One function in `claude_runner.py` builds every invocation:

```bash
cd <workspace> && env -i \
    HOME="$HOME" PATH="$PATH" USER="$USER" TERM=dumb LANG=C.UTF-8 TZ=UTC \
  claude -p "$(cat .fvk_bench/prompts/<arm>.md)" \
    --model claude-opus-4-8 \
    --effort max \
    --max-turns 200 \
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
- **Turn budgets:** 200 for every arm — these are hard problems and the ceiling must not bind.
  fvk and control budgets are **always equal** (control validity). Configurable; recorded in manifests.
- **`env -i` allowlist** eliminates environment drift: kills `ANTHROPIC_API_KEY` (which would
  silently switch billing to the API), `CLAUDE_*`/`MAX_THINKING_TOKENS` overrides, and
  locale/timezone differences.
- **Banning customized skills and extra affordances (defense in depth):**
  - `--disable-slash-commands` — per the CLI, disables **all** skills.
  - `--tools 'Read,Write,Edit,Glob,Grep'` — whitelisting these 5 excludes by omission the Skill,
    Task/agent, SlashCommand, Bash, WebFetch/WebSearch, TodoWrite and Notebook tools.
  - `--strict-mcp-config --mcp-config '{"mcpServers":{}}'` — zero MCP servers regardless of any
    machine configuration.
  - `--setting-sources project,local` — excludes user-level settings (where personal skills,
    plugins, hooks and marketplace installs live); the workspace itself contains no `.claude/`,
    no settings, no `CLAUDE.md` anywhere in its ancestry, so project/local sources resolve empty.
    During implementation we test whether the CLI accepts an even narrower source list (e.g.
    empty) and use the narrowest value that still authenticates; the value used is recorded.
  - No `--plugin-dir`, no `--agents`, no `--append-system-prompt`.
  - `env -i` scrub removes `CLAUDE_*` / `ANTHROPIC_*` overrides.
  - **Empirical verification, not trust:** `doctor --canary` asserts from a real transcript that
    the session advertises exactly the 5 tools and contains no skill/plugin/agent-listing/MCP
    attachments; the same assertion runs as a post-arm audit on every benchmark transcript, and
    any violation marks the arm `failed(contaminated_session)`.
- **Session IDs:** baseline's uuid4 is pre-generated and recorded *before* launch (known even on
  crash). Fork session IDs are parsed from the JSON result envelope. After each arm, the full
  session transcript (`~/.claude/projects/<munged-cwd>/<session-id>.jsonl`) is harvested and
  gzipped into results — audit evidence of exactly what each session saw and did.
- **Prompt delivery:** prompt text is passed via argv from the rendered file; the rendered file is
  the artifact of record.
- **Timeout:** per-arm wall-clock timeout (default 4h — 200-turn max-effort sessions can run long)
  so a hung session cannot stall the queue; timeouts are recorded as `failed(timeout)`.
- Sequential execution only (one session at a time) — subscription rate limits and machine-load
  fairness; `run` accepts multiple instances and loops.

### CLI option audit and rejected alternatives

Every flag above was checked against `claude` 2.1.169 `--help` on this machine. Two findings from
the owner's prior transcript audits are encoded as hard rules:

- **Use `--tools`, never `--allowedTools`.** `--allowedTools` is a permission allowlist, not an
  availability restriction — in the prior HumanEval run it left Bash usable (actually used in
  157/164 sessions) and left deferred-tool and agent-listing attachments in transcripts.
  `--tools` restricts the actual built-in tool set. The post-arm transcript audit exists precisely
  to catch a regression here.
- **`--bare` is rejected**, although it would be the most minimal session: bare mode skips
  OAuth/keychain auth and demands an API key — it cannot authenticate a subscription. Our flag
  set is the strictest invocation that still authenticates via subscription login, and the canary
  proves the resulting transcripts carry no deferred-tool/agent-listing/MCP attachments.
- `--permission-mode bypassPermissions` is a valid mode (choices verified); with a 5-tool
  read/search/edit surface it grants nothing dangerous and removes interactive prompts.
- `--model claude-opus-4-8` is a pinned ID, not the drifting `opus` alias; `doctor --probe-model`
  (optional, single 1-turn session) confirms the account can access it before a long run.

### Repeatability of the numbers

What this infrastructure standardizes: inputs (vendored instance data), prompts (hashed
templates), the full flag set, tool surface, env allowlist, cwd shape, session lineage
(fork-from-frozen-baseline), and the evaluation route (official dockerized harness, prebuilt
images). What it cannot standardize: server-side sampling — the CLI exposes no seed, so two runs
of the same arm are two draws from the same distribution, and per-instance flips across machines
are expected noise. Therefore:

- Cross-machine comparisons are made at the **aggregate** level (per-arm resolved counts, flip
  counts), not per instance.
- Repeat runs are first-class: each gets its own `run_id`; `results/INDEX.md` aggregates across
  runs so variance is visible rather than hidden.
- Every manifest records enough (versions, flags, hashes, timestamps, machine) to explain any
  two runs' differences honestly.

### Preflight: `python -m fvk_bench doctor`

- `claude` present; version printed and recorded (warn if ≠ the version this infra was tested with).
- `--probe-model` (optional): a single 1-turn session with the pinned production model to confirm
  the subscription can access `claude-opus-4-8` before committing to a long run.
- git, docker daemon reachable (eval only), CPU arch is x86_64 (required by the pinned instances),
  `datasets`/`swebench` importable, disk space check (eval needs ~120GB free).
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

**Prompt design is its own deliverable in the implementation plan** — drafted against the
checklist below, reviewed, then frozen before any benchmark run. The owner's HumanEval v2 prompt
is the structural reference (its allowed-inputs / forbidden-inputs / tasks framing), adapted to
this benchmark — never copied verbatim, since paths, solution format (repo edits, not a `.py`
file) and the no-execution reality all differ.

Three versioned templates in `fvk_bench/prompts/`, rendered per instance with placeholders
(`{instance_id}`, `{repo}`, `{base_commit}`). All three share one skeleton:

1. instance header (repo, base commit, where things are)
2. allowed inputs (explicit whitelist of workspace paths)
3. forbidden inputs (no internet/external data, no gold-fix knowledge, no hidden tests, no test
   execution — "there are intentionally no test results available; do not infer or ask for them")
4. tasks
5. output discipline (do not modify test files; do not create files outside the named outputs;
   stop only after all named files are written)

Per-arm content:

- **baseline.md** — read `benchmark/PROBLEM.md`, locate the root cause in `repo/`, implement the
  fix by editing `repo/` directly (multi-file edits allowed), write `reports/baseline_notes.md`
  (root cause, fix rationale, assumptions).
- **fvk.md** — "continue from the same context" framing; states that `repo/` currently contains
  the V1 fix applied. Tasks: read `fvk_materials/README.md`, `fvk_materials/AGENTS.md`,
  `fvk_materials/commands/formalize.md`, `fvk_materials/commands/verify.md`; produce
  `fvk/SPEC.md`, `fvk/FINDINGS.md`, `fvk/PROOF_OBLIGATIONS.md`, `fvk/PROOF.md`,
  `fvk/ITERATION_GUIDANCE.md`; revise or confirm the V1 fix by editing `repo/` (an unchanged V1
  must be justified by the FVK artifacts); write `reports/fvk_notes.md` tracing every decision to
  specific findings / proof obligations.
- **control.md** — identical skeleton and framing except the methodology section: perform a
  careful, standard code review of the V1 fix (correctness, edge cases, error handling,
  regressions, API-contract adherence), write findings to `review/FINDINGS.md`, revise or confirm
  by editing `repo/` (an unchanged V1 must be justified by the review findings), and write
  `reports/control_notes.md` tracing every decision to specific findings. No mention of FVK;
  no `fvk_materials/` exists in its workspace view.

Prompt design checklist (acceptance criteria for the deliverable):

- [ ] Allowed/forbidden inputs enumerate the **actual** workspace paths of this infrastructure.
- [ ] Review-arm prompts state the workspace state on entry (V1 applied to `repo/`; where notes live).
- [ ] **No-execution notice:** the session has no shell, no Python, no K tooling — FVK's
      `verify.md` asks for `kompile`/`kprove` commands, and the prompt must make explicit that
      such commands are to be *written as artifacts*, never executed; all verification is by
      construction and reasoning.
- [ ] fvk.md and control.md differ **only** in the methodology/tasks middle section (diffable);
      artifact burden is comparable (findings file + notes + optional repo edits in both).
- [ ] Baseline prompt forbids reading `reports/`, `fvk/`, `review/` (must not anticipate review arms).
- [ ] No prompt mentions scoring, resolved-iff thresholds, or the existence of other arms.
- [ ] Wording reviewed for leakage (nothing hints at gold-patch shape or test names).

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
4. `python -m fvk_bench report --run-id X` renders `scores.md`: a per-instance × arm table
   (resolved, FTP x/y, PTP x/y) covering every instance in the run — failed/skipped arms and
   empty patches shown explicitly — plus aggregates (resolved counts per arm, baseline→fvk and
   baseline→control flip counts with +/− direction, fvk-vs-control delta), and updates the
   cross-run `results/INDEX.md`.

Evaluation runs only after all arms of the selected instances are frozen — no arm ever observes
test results (matching the reproducibility protocol's "no test results available" discipline).

### Why this is the proper evaluation route (verified against harness source)

- The dockerized `swebench.harness.run_evaluation` is the officially recommended way to score
  Verified instances; per-instance results land at
  `logs/run_evaluation/<run_id>/<model_name_or_path>/<instance_id>/report.json`
  (plus `test_output.txt` / `run_instance.log`), which `evaluate` harvests into `results/`.
- **Prebuilt images:** the harness default namespace `swebench` pulls prebuilt instance images
  from DockerHub instead of building locally — the most reproducible and disk-friendly path.
  We keep that default; `--namespace none` remains available for local builds.
- **Non-Python setup of the 45 instances:** entirely baked into the harness's images — none of it
  touches the host. Specifics (from `swebench/harness/constants/python.py`): django needs
  generated `en_US.UTF-8` locales + `LANG`/`LC_ALL` env; sphinx ≥7.2 needs `graphviz`;
  pylint 2.8 needs `libenchant-2-dev`/`hunspell-en-us`; scikit-learn and astropy compile
  C/Cython extensions at image build; sympy, pytest, xarray need nothing special.
  Host requirements are only: Docker, **x86_64** (many of the 45 are pinned x86_64 via the
  harness's `USE_X86_PY` list; arm64 is not supported for them), ~120GB free disk.

### Environment validation: `python -m fvk_bench validate-gold`

Runs the harness with `--predictions_path gold` (official gold patches) over the selected
instances **before** any real evaluation. Gold must resolve every selected instance; anything
less means the eval environment is broken on this machine, and real scores would be
uninterpretable. START.md makes this a required step for new machines.

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

`results/.gitignore` re-includes `*.patch`, `*.jsonl`, and `*.jsonl.*` — the repo root
`.gitignore` excludes all three globally (verified), and `*.jsonl.*` is what matches the
gzipped transcripts. No results subdirectory may end in `logs` (root ignores `*logs/`).

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
2. Live validation on **one** problem — `sympy__sympy-12489` (small repo, fast eval):
   `doctor --canary` → `validate-gold` for the instance (gold must resolve) → `run` with the
   pinned production settings → `evaluate` → `report`; push its `results/<run_id>/`.
3. `START.md` covers: prerequisites (Ubuntu x86_64, Claude Code subscription + login, git, Docker,
   `pip install -e .`), `git submodule update --init`, then the exact command sequence
   (`doctor` → `validate-gold` → `run` → `evaluate` → `report`), how to select instances, and how
   to contribute results from a new machine (one directory per `run_id`; machine identity in
   `run_manifest.json`).

## Appendix: file-existence audit

Every external file/path this spec relies on, with verification status (2026-06-12, this machine):

**Verified to exist:**

- `fastxyz/swebench-fvk-reproducibility` → `prompts/<instance_id>.md` × 45 (cloned & counted;
  IDs enumerated in recon, incl. `sympy__sympy-12489` used for live validation).
- `grosu/formal-verification-kit` → `README.md`, `AGENTS.md`, `commands/formalize.md`,
  `commands/verify.md`, `knowledge/k-framework.md`, `knowledge/matching-logic.md`,
  `knowledge/reachability-and-circularities.md`, `knowledge/sources.md` (cloned & listed; these
  8 files are the `fvk_materials/` copy set).
- `swebench.harness.run_evaluation` with `--predictions_path gold` (run_evaluation.py:608),
  default `--namespace swebench` (run_evaluation.py:285,654); dataset names pass through to
  HuggingFace so `princeton-nlp/SWE-bench_Verified` loads as-is (harness/utils.py:151-167).
- Per-repo install specs incl. non-Python steps: `swebench/harness/constants/python.py`.
- Eval report location: `logs/run_evaluation/<run_id>/<model_name_or_path>/<instance_id>/report.json`.
- Root `.gitignore` patterns requiring the results re-include: `*.patch`, `*.jsonl`, `*.jsonl.*`,
  `*logs/` (read directly).
- Claude CLI 2.1.169 flags: `--tools`, `--effort` (max), `--fork-session`, `--session-id`,
  `--resume`, `--setting-sources`, `--strict-mcp-config`, `--disable-slash-commands`,
  `--permission-mode bypassPermissions` (help output read directly).
- Session transcript location pattern `~/.claude/projects/<munged-cwd>/<session-id>.jsonl`
  (observed on this machine).

**Created by this project (do not exist yet):**

- `fvk_bench/**` (package, `prompts/{baseline,fvk,control}.md`, `data/instances.json`),
  `tests/fvk_bench/**`, `third_party/` submodule wiring + `.gitmodules`, `results/**`
  (incl. `.gitignore`, `INDEX.md`, per-run trees), `START.md`.
- At runtime only (never committed): workspace trees under `~/.swe-fvk-runs/`
  (`benchmark/`, `repo/`, `reports/`, `fvk/`, `review/`, `fvk_materials/`, `.fvk_bench/`).

**Deliberately absent everywhere:** gold patches, `test_patch` contents, hidden test names —
they exist only inside the eval harness's own dataset download at evaluation time.

## Out of scope (YAGNI)

- Parallel Claude sessions, API-based runs, Modal/cloud evaluation, statistical analysis tooling,
  multi-model comparisons, automatic prompt tuning. The schema records enough to add any of these later.
