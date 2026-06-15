# Run a benchmark batch — ready-made prompt

**This page is for human users: fill in the parameters in the prompt below, then paste
the whole prompt into your local Claude Code session.**

- `{instance-set}` — `fvk45` for the original 45-instance subset, or `verified500` for the
  full SWE-bench Verified set.
- `{batch}` — `batch1` ... `batch5` for `fvk45`, or `verified001` ... `verified050` for
  `verified500`.
- `{arms}` — usually `baseline,fvk,control` for the 45-set experiment, or `baseline,fvk`
  for a two-arm full-Verified run.
- `{max-parallel}` — how many problems may run at the same time. For a 10-instance
  `verified500` batch, `3` finishes in roughly four rolling slots. Parallel runs are
  faster but share your machine and your subscription's rate limits.
- `{agent}` — `claude` (default) or `codex`: which agent under test. `codex` runs the same
  requested arms with OpenAI Codex (`gpt-5.5`) and needs a Codex subscription (see
  START.md §2); validate it before a full batch.

**You need:** an Ubuntu **x86_64** machine · [Claude Code](https://claude.com/claude-code)
installed and logged in with a subscription (and, for `{agent}` = `codex`, the Codex CLI
logged in with a Codex subscription) · Docker with ~120 GB free disk · Python ≥ 3.10
· git · this repo cloned locally, on `main`. Everything else is in
[START.md](START.md) — your Claude session will read it.

**What to expect:** these runs take a **long time**. While the benchmark runs, your Claude
session may look stale or idle; **it is not stuck** — it is waiting for background sessions
and tests to finish. Send `status?` at any time and it will reply with a progress report.

---

```text
I have the fastxyz/SWE-bench repo cloned locally on main, with Claude Code installed and
logged in. Run one benchmark batch end to end.

Read START.md at the repo root and follow it exactly. Parameters for this run:
- instance set: {instance-set}
- batch: {batch}
- arms: {arms}
- max parallel instances: {max-parallel}
- agent: {agent}
- run id: {batch}-{agent}-$(hostname)-$(date +%y%m%d%H%M%S)
  (compute the run id once at the start and reuse the exact same string for every
  command below — the agent keeps Claude and Codex runs distinct, the timestamp keeps
  it unique so concurrent runs never collide)

Carry out, in order:
1. Setup + sanity: `git submodule update --init`, create .venv and `pip install -e .`,
   then `python -m fvk_bench doctor --agent {agent} --canary`. Stop and show me the
   output if any hard check fails or the canary is not clean.
2. `validate-gold --instance-set {instance-set}` for this batch — every selected instance
   must resolve before continuing.
3. `run` the batch with `--instance-set {instance-set}`, `--batch {batch}`,
   `--agent {agent}`, `--arms {arms}`, and `--max-parallel {max-parallel}`. This takes
   hours: run it in the background and monitor until every requested arm of every instance
   is completed. If an arm fails with a transient error (e.g. API overload), rerun the same
   command with `--retry-failed`. Never edit anything under fvk_bench/ (prompts, config) —
   that would break comparability across machines.
4. `evaluate`, then `report`.
5. Commit ONLY the new results/<run-id>/ directory plus results/INDEX.md to main and push
   before starting any later batch.

This will take hours. While work is running in the background, stay on it and do not give
up; whenever I send `status?`, reply with a concise progress report: per-instance arm
statuses, what is currently running, and elapsed time.

When done, report: the scores.md aggregates (per-arm resolved counts, flips), any arms
that failed or needed retries, and total wall-clock time.
```
