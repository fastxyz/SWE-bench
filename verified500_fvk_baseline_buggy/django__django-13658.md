# django__django-13658

## Summary

**Severity:** Medium — baseline leaves a second management pre-parser
(`get_command_line_option`) constructing its `CommandParser` without a `prog`, so a
valid explicit-argv command path can still derive usage/error text from
process-global `sys.argv[0]`.

Baseline fixed the reported early parser in `ManagementUtility.execute()` by passing
`prog=self.prog_name`, and both arms passed the official SWE-bench evaluation. FVK's
completeness audit then found an **adjacent** explicit-argv parser with the *same*
global-state dependency — `get_command_line_option(argv, option)`, reachable from the
`test` command's `--testrunner` pre-parse — and added the missing `prog`. The defect
was located by **lifting the issue into an invariant over every explicit-argv
pre-parser and auditing each contributor**, not by running a new test.

| Arm | [Official SWE-bench evaluation (`FAIL_TO_PASS`)](../results/verified013-codex-XC-MINI-PRO-AHP-20260616T004115Z/django__django-13658/eval/fvk.report.json) | Residual `utils.py` defect resolved |
|---|---|---|
| baseline | resolved | no |
| gold (human oracle) | resolved | no |
| **fvk** | resolved | **yes** |

## 1. The issue and the real defect

The issue: `ManagementUtility` parses its program name from the `argv` it is handed
(stored in `self.prog_name`) so that callers of `execute_from_command_line(argv)` need
not rely on process-global `sys.argv`. But when it pre-parses `--settings` and
`--pythonpath`, the early `CommandParser` was built **without** an explicit `prog`, so
`%(prog)s` and any usage/error text fell back to `sys.argv[0]`. In an embedded
environment where `sys.argv[0]` is invalid, passing a clean explicit `argv` did not
prevent the resulting bad usage text or exceptions
([`prompts/fvk.md`](../results/verified013-codex-XC-MINI-PRO-AHP-20260616T004115Z/django__django-13658/prompts/fvk.md#L2)).

The user-facing observable that is wrong: with a valid caller-supplied `argv` but an
invalid global `sys.argv[0]`, management bootstrapping still consults the global, so
the early option pre-parse can emit `sys.argv[0]`-derived usage/error output or raise
before command dispatch.

## 2. Baseline's fix — and where it stopped

[Baseline](../results/verified013-codex-XC-MINI-PRO-AHP-20260616T004115Z/django__django-13658/solutions/solution_baseline.patch)
made exactly the change the issue requested — pass `prog=self.prog_name` to the early
parser in `ManagementUtility.execute()`:

```python
parser = CommandParser(
    prog=self.prog_name,
    usage='%(prog)s subcommand [options] [args]',
    add_help=False,
    allow_abbrev=False,
)
```

Baseline was not careless. Its root-cause analysis is correct, and it consciously
scoped the fix to the early parser, reasoning that other parsers already carry an
explicit program name:

> *"The issue is limited to the early parser used for global option preprocessing.
> Command-specific parsers already derive their program names from the command `argv`
> passed through `run_from_argv()`, and the help paths in `ManagementUtility` already
> use `self.prog_name`."*
> — [`reports/baseline_notes.md`](../results/verified013-codex-XC-MINI-PRO-AHP-20260616T004115Z/django__django-13658/reports/baseline_notes.md#L17)

That scoping is **almost** complete. It covers `ManagementUtility`'s own parsers and
the command-specific parsers built by `BaseCommand.create_parser()`. But it overlooks a
third explicit-argv parser that is *not* command-specific and does *not* receive a
`prog`: the module-level helper `get_command_line_option(argv, option)` in
`django/core/management/utils.py`, which the `test` command calls to pre-parse
`--testrunner`. Baseline left that obligation — explicit-argv parsing without a
`sys.argv[0]` dependency — unmet for that path.

## 3. How FVK formally captured the gap

FVK started from a spec that generalizes the issue beyond the single reported method.
The decisive intent items do not name `ManagementUtility.execute()` specifically — they
state the invariant for *any* explicit-argv pre-parser:

> *"When a caller passes an explicit `argv` to Django's management entry point,
> management bootstrapping must use that argument vector's program name instead of
> process-global `sys.argv[0]`."* … *"A helper whose documented contract is to parse
> 'an argument list' should not need process-global `sys.argv[0]` merely to construct
> its parser."*
> — [`fvk/SPEC.md`](../results/verified013-codex-XC-MINI-PRO-AHP-20260616T004115Z/django__django-13658/fvk/SPEC.md#L16)

The evidence ledger pins that intent to a concrete code fact found by **source audit**
— the helper's own docstring contract — not to the reported failing test:

> **E5 (source/docstring):** *`get_command_line_option(argv, option)` returns a value
> "from an argument list." → The helper's parser should be anchored to its `argv`, not
> to global `sys.argv[0]`, while preserving return behavior.*
> — [`fvk/SPEC.md`](../results/verified013-codex-XC-MINI-PRO-AHP-20260616T004115Z/django__django-13658/fvk/SPEC.md#L30)

That fact is discharged into a formal obligation requiring the helper to build its
parser from its own explicit `argv`:

> **PO4 — `get_command_line_option()` parser uses its explicit argument list.**
> *`prog_name := basename(argv[0]) if argv else ''` … constructs
> `CommandParser(prog=prog_name, …)` … parser construction does not need SYS0 …
> return value behavior remains [unchanged].*
> — [`fvk/PROOF_OBLIGATIONS.md`](../results/verified013-codex-XC-MINI-PRO-AHP-20260616T004115Z/django__django-13658/fvk/PROOF_OBLIGATIONS.md#L83)

This is FVK's value here: the second site was located by **reasoning, not
observation**. The issue says "use the argv's program name, not `sys.argv[0]`"; FVK
lifts that into an invariant over *every* explicit-argv contributor to a management
parser, and the source audit (E5) shows `get_command_line_option()` is a second such
contributor that builds its parser without a `prog`.

## 4. From formal output to the fix

The completeness audit against the spec raised the finding that V1 (baseline's change)
covered only one of the explicit-argv pre-parsers:

> **F2: V1 missed an adjacent explicit-argv pre-parser.** *Classification: code bug in
> V1, resolved in V2. … `get_command_line_option()` constructed `CommandParser(add_help=False,
> allow_abbrev=False)` without `prog`, even though its own documented input is an
> argument list. This retained the same kind of global `sys.argv[0]` dependency for a
> reachable management-command preparse.*
> — [`fvk/FINDINGS.md`](../results/verified013-codex-XC-MINI-PRO-AHP-20260616T004115Z/django__django-13658/fvk/FINDINGS.md#L14)

The iteration guidance turned that finding into a concrete decision for V2:

> *"Add the V2 `get_command_line_option()` change. Basis: FINDINGS F2,
> PROOF_OBLIGATIONS PO4. … Leaving it unchanged would preserve a second
> parser-construction dependency on invalid global `sys.argv[0]`."*
> — [`fvk/ITERATION_GUIDANCE.md`](../results/verified013-codex-XC-MINI-PRO-AHP-20260616T004115Z/django__django-13658/fvk/ITERATION_GUIDANCE.md#L11)

The decision log records the resulting code change and traces it back to F2/PO4:

> *"Added a V2 change in `repo/django/core/management/utils.py`. Trace: `fvk/FINDINGS.md`
> F2; `fvk/PROOF_OBLIGATIONS.md` PO4. … it is reachable from the `test` management
> command before command-specific parser construction, so leaving it unchanged would
> preserve the same class of global `sys.argv[0]` dependency for that path."*
> — [`reports/fvk_notes.md`](../results/verified013-codex-XC-MINI-PRO-AHP-20260616T004115Z/django__django-13658/reports/fvk_notes.md#L10)

The causal chain is on the record:

```
SPEC intent (any explicit-argv pre-parser must avoid sys.argv[0])
        ->  E5  (source audit: get_command_line_option parses an argument list, builds parser without prog)
        ->  PO4 (obligation: helper parser must use prog from its own argv)
        ->  F2  (V1 audit: helper still omits prog -> second sys.argv[0] dependency)
        ->  ITERATION_GUIDANCE / fvk_notes  ->  V2 patch (utils.py)
```

The [FVK patch](../results/verified013-codex-XC-MINI-PRO-AHP-20260616T004115Z/django__django-13658/solutions/solution_fvk.patch)
keeps baseline's `__init__.py` change verbatim and adds exactly the `utils.py` edge that
PO4 demands:

```python
prog_name = os.path.basename(argv[0]) if argv else ''
parser = CommandParser(prog=prog_name, add_help=False, allow_abbrev=False)
```

The `V1 -> V2` transition was driven by **F2/PO4** (the formal completeness finding),
**not** by a new failing test — no test exercises the `utils.py` path here (see §5).

## 5. Verification

**Tier: source-and-artifact reviewed; not executed.** No FVK regression test was added
to the harness for this instance (the run forbids touching tests, Python, or K tooling
— [`prompts/fvk.md`](../results/verified013-codex-XC-MINI-PRO-AHP-20260616T004115Z/django__django-13658/prompts/fvk.md#L26)),
so there is no RED→GREEN proof report and no executed behavioral demonstration. What was
inspected:

- The two patches, via `diff solution_baseline.patch solution_fvk.patch`: the FVK arm is
  baseline plus exactly one added hunk — `prog=prog_name` on the `utils.py`
  `CommandParser`. No other file changes.
- The official SWE-bench evaluation reports for both arms: **both resolved**, both with
  181 `PASS_TO_PASS`
  ([baseline](../results/verified013-codex-XC-MINI-PRO-AHP-20260616T004115Z/django__django-13658/eval/baseline.report.json),
  [fvk](../results/verified013-codex-XC-MINI-PRO-AHP-20260616T004115Z/django__django-13658/eval/fvk.report.json)).
  The two reports are byte-identical. This is itself the evidence that the residual
  `utils.py` defect is **not covered** by the benchmark's hidden tests: baseline ships
  the un-fixed helper yet still passes, so the harness cannot distinguish the two arms.
  FVK's extra fix is therefore a genuine residual repair, not a harness artifact.

**Comparison to the human oracle.** The gold fix for this issue changes only
`ManagementUtility.execute()` (the same site baseline fixed); it does not touch
`get_command_line_option()`. FVK's `utils.py` edge goes beyond what the maintainers'
accepted fix repaired. (Non-curated instance — no gold patch is archived alongside this
run, so this comparison is stated, not linked.)

## 6. Boundaries & honesty

- **Severity: Medium.** The trigger breadth is moderate, not catastrophic: it requires a
  valid embedded/programmatic caller that (a) supplies an explicit `argv`, (b) runs under
  an invalid global `sys.argv[0]`, and (c) reaches the `test` command's `--testrunner`
  pre-parse. In that band it can produce wrong command-line usage/error text or an
  exception — a correctness defect — but **not** silent data corruption and not a
  broadly-reachable crash. That places it above Low (it is a real wrong-behavior path on
  a supported entry point) and below High (no data loss, narrow trigger).
- **Proof status: constructed, not machine-checked.** The K artifacts
  ([`mini-management.k`](../results/verified013-codex-XC-MINI-PRO-AHP-20260616T004115Z/django__django-13658/fvk/mini-management.k),
  [`management-preparse-spec.k`](../results/verified013-codex-XC-MINI-PRO-AHP-20260616T004115Z/django__django-13658/fvk/management-preparse-spec.k))
  and the `kompile`/`kast`/`kprove` commands were **written but never run** — the FVK
  artifacts say so explicitly
  ([`fvk/PROOF.md`](../results/verified013-codex-XC-MINI-PRO-AHP-20260616T004115Z/django__django-13658/fvk/PROOF.md#L3),
  [`fvk/PROOF.md` machine-check section](../results/verified013-codex-XC-MINI-PRO-AHP-20260616T004115Z/django__django-13658/fvk/PROOF.md#L36)).
  We therefore claim **proof-structured reasoning** (a formal spec with obligations
  discharged by source inspection), **not** a machine-checked proof. The bug-detection
  value does not depend on the unrun `kprove`.
- **Attribution.** The defect-detection claim rests on the spec/finding/obligation chain
  in §3-§4, all on the record. The fix's *correctness* is argued by frame conditions
  (PO3/PO4 preserve registered options, parse input, and return behavior), not by an
  executed test — there is no harness coverage of the `utils.py` path for this instance,
  so the repair is verified by inspection, not by observation.

## Artifact map

| Claim | Source |
|---|---|
| Issue text, repro context | [`prompts/fvk.md`](../results/verified013-codex-XC-MINI-PRO-AHP-20260616T004115Z/django__django-13658/prompts/fvk.md#L2) |
| Baseline patch | [`solutions/solution_baseline.patch`](../results/verified013-codex-XC-MINI-PRO-AHP-20260616T004115Z/django__django-13658/solutions/solution_baseline.patch) |
| Baseline scoping rationale | [`reports/baseline_notes.md`](../results/verified013-codex-XC-MINI-PRO-AHP-20260616T004115Z/django__django-13658/reports/baseline_notes.md#L17) |
| FVK patch | [`solutions/solution_fvk.patch`](../results/verified013-codex-XC-MINI-PRO-AHP-20260616T004115Z/django__django-13658/solutions/solution_fvk.patch) |
| Intent invariant (explicit-argv pre-parsers) | [`fvk/SPEC.md#L16`](../results/verified013-codex-XC-MINI-PRO-AHP-20260616T004115Z/django__django-13658/fvk/SPEC.md#L16) |
| Evidence E5 (helper docstring audit) | [`fvk/SPEC.md#L30`](../results/verified013-codex-XC-MINI-PRO-AHP-20260616T004115Z/django__django-13658/fvk/SPEC.md#L30) |
| Obligation PO4 | [`fvk/PROOF_OBLIGATIONS.md#L83`](../results/verified013-codex-XC-MINI-PRO-AHP-20260616T004115Z/django__django-13658/fvk/PROOF_OBLIGATIONS.md#L83) |
| Finding F2 | [`fvk/FINDINGS.md#L14`](../results/verified013-codex-XC-MINI-PRO-AHP-20260616T004115Z/django__django-13658/fvk/FINDINGS.md#L14) |
| Iteration decision (V1→V2) | [`fvk/ITERATION_GUIDANCE.md#L11`](../results/verified013-codex-XC-MINI-PRO-AHP-20260616T004115Z/django__django-13658/fvk/ITERATION_GUIDANCE.md#L11) |
| Decision trace (utils.py) | [`reports/fvk_notes.md#L10`](../results/verified013-codex-XC-MINI-PRO-AHP-20260616T004115Z/django__django-13658/reports/fvk_notes.md#L10) |
| Proof status (constructed, not run) | [`fvk/PROOF.md#L3`](../results/verified013-codex-XC-MINI-PRO-AHP-20260616T004115Z/django__django-13658/fvk/PROOF.md#L3) |
| Unrun machine-check commands | [`fvk/PROOF.md#L36`](../results/verified013-codex-XC-MINI-PRO-AHP-20260616T004115Z/django__django-13658/fvk/PROOF.md#L36) |
| Constructed K core | [`fvk/mini-management.k`](../results/verified013-codex-XC-MINI-PRO-AHP-20260616T004115Z/django__django-13658/fvk/mini-management.k), [`fvk/management-preparse-spec.k`](../results/verified013-codex-XC-MINI-PRO-AHP-20260616T004115Z/django__django-13658/fvk/management-preparse-spec.k) |
| Official evaluation (both arms resolved) | [`eval/baseline.report.json`](../results/verified013-codex-XC-MINI-PRO-AHP-20260616T004115Z/django__django-13658/eval/baseline.report.json), [`eval/fvk.report.json`](../results/verified013-codex-XC-MINI-PRO-AHP-20260616T004115Z/django__django-13658/eval/fvk.report.json) |
