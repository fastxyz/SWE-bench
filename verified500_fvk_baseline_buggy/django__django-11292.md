# django__django-11292

## Summary

**Severity:** Medium — command-line `testserver` can inherit `call_command()`'s
programmatic `skip_checks=True` default and silently skip the system check, but
only on the single `testserver` delegation path and only at development time, so
the blast radius is bounded.

Baseline and FVK both passed the official SWE-bench evaluation for this issue,
with **different** patches. The baseline patch wired `--skip-checks` into the
automatic-check parser and into `runserver`, but left `testserver` — which runs
the server by delegating through `call_command('runserver')` — without its own
flag. The FVK patch closes that one residual path: it exposes `--skip-checks` on
`testserver` and forwards the parsed decision explicitly, so a command-line
`testserver` run no longer absorbs the programmatic skip-by-default. FVK located
the gap by **formalizing the check-skipping contract and auditing the one command
that reaches checks through a programmatic delegate**, not by running a test.

| Arm | command-line `testserver` (no flag) delegates `skip_checks` | Resolved |
|---|---|---|
| baseline | `True` (inherited from `call_command`) — checks wrongly skipped | no |
| gold (human oracle) | runs checks | — |
| **fvk** | [`False`](../results/verified005-codex-XC-MINI-PRO-AHP-20260615T181744Z/django__django-11292/solutions/solution_fvk.patch#L74) — checks run | **yes** |

## 1. The issue and the real defect

The task asks for a `--skip-checks` option on management commands: Django already
carries a `skip_checks` *stealth* option for programmatic `call_command()`, and
the issue wants the same skip exposed on the command line so users can suppress
system checks when running a command directly
([`prompts/fvk.md`](../results/verified005-codex-XC-MINI-PRO-AHP-20260615T181744Z/django__django-11292/prompts/fvk.md#L2)).

The subtlety is that two defaults are in play for the *same* option name:

- **CLI default** — argparse `store_true` gives `skip_checks=False` when the flag
  is omitted, i.e. checks run.
- **Programmatic default** — `call_command()` injects `skip_checks=True` when the
  caller omits the key, i.e. checks are skipped.

`testserver.Command.handle()` does not run the server itself; it delegates with
`call_command('runserver', ...)`. So any command-line option that `testserver`
fails to forward is filled in by `call_command()`'s programmatic default. For
`skip_checks` that default is `True`. A command-line `testserver` that never
parses `--skip-checks` therefore hands the delegated `runserver` a stealth
`skip_checks=True` and **skips the system check the user never asked to skip**.

## 2. Baseline's fix — and where it stopped

[Baseline](../results/verified005-codex-XC-MINI-PRO-AHP-20260615T181744Z/django__django-11292/solutions/solution_baseline.patch)
did the two structurally necessary things and did them correctly. It added the
flag to the common parser for automatic-check commands and to the help-ordering
set in `base.py`
([`reports/baseline_notes.md`](../results/verified005-codex-XC-MINI-PRO-AHP-20260615T181744Z/django__django-11292/reports/baseline_notes.md#L18)),
and it gave `runserver` its own `--skip-checks` plus a guard on the explicit
`self.check()` call
([`reports/baseline_notes.md`](../results/verified005-codex-XC-MINI-PRO-AHP-20260615T181744Z/django__django-11292/reports/baseline_notes.md#L22)),
because `runserver` sets `requires_system_checks = False` and checks explicitly
inside `inner_run()`.

Baseline was not careless about scope. Its notes show it deliberately decided
*not* to add the flag to every command, and singled out `runserver` as the one
explicit-check exception:

> *"I considered adding `--skip-checks` unconditionally to every management
> command, but rejected that because commands with `requires_system_checks =
> False` would receive an irrelevant no-op option … I treated `runserver` as the
> one built-in exception that should expose the option despite
> `requires_system_checks = False`."*
> — [`reports/baseline_notes.md`](../results/verified005-codex-XC-MINI-PRO-AHP-20260615T181744Z/django__django-11292/reports/baseline_notes.md#L33)

That reasoning is **almost complete**: it correctly identified that
`requires_system_checks = False` commands need special handling, but it treated
`runserver` as the *only* such case. `testserver` is a second one — it reaches a
system check not through its own `execute()` but through a programmatic delegate,
and that delegate carries the opposite default. Baseline left that path unmet.

## 3. How FVK formally captured the gap

FVK started from the check-skipping contract, not the symptom, and made the two
competing defaults an explicit intent item. The decisive ledger entry is keyed
to a source fact about `testserver`, found by audit rather than by a test:

> **I6 — Source code in `testserver.py`:** *`testserver` calls
> `call_command('runserver', ...)`* → *`testserver` must pass the command-line
> skip decision through to `runserver`; otherwise `call_command()`'s default
> changes CLI behavior.*
> — [`fvk/SPEC.md`](../results/verified005-codex-XC-MINI-PRO-AHP-20260615T181744Z/django__django-11292/fvk/SPEC.md#L31)

That intent is paired with the compatibility constraint that makes the bug
sharp — the programmatic default must *not* be changed to fix it:

> **I5 — Source code in `call_command()`:** *`if 'skip_checks' not in options:
> defaults['skip_checks'] = True`* → *Programmatic `call_command()` default
> remains skip-by-default unless an explicit `skip_checks` is supplied.*
> — [`fvk/SPEC.md`](../results/verified005-codex-XC-MINI-PRO-AHP-20260615T181744Z/django__django-11292/fvk/SPEC.md#L30)

The intent-only spec then states the required CLI behavior directly, separating
it from the programmatic default:

> *"`testserver` accepts `--skip-checks` and propagates the caller's skip
> decision to the delegated `runserver` command. Command-line `testserver`
> without the flag must not inherit `call_command()`'s programmatic
> skip-by-default behavior."*
> — [`fvk/SPEC.md`](../results/verified005-codex-XC-MINI-PRO-AHP-20260615T181744Z/django__django-11292/fvk/SPEC.md#L45)

These discharge into a proof obligation that pins all three cases of the same
option name at once:

> **PO4 — `testserver` preserves command-line default and propagates explicit
> skip.** *Command-line `testserver` without `--skip-checks` must delegate to
> `runserver` with `skip_checks=False`; command-line `testserver --skip-checks`
> must delegate with `skip_checks=True`; programmatic
> `call_command('testserver')` must preserve the existing `call_command()`
> default of `skip_checks=True`.*
> — [`fvk/PROOF_OBLIGATIONS.md`](../results/verified005-codex-XC-MINI-PRO-AHP-20260615T181744Z/django__django-11292/fvk/PROOF_OBLIGATIONS.md#L41)

This is where the reasoning beats the test: the issue text only says "let users
skip checks from the command line". FVK lifts that into an invariant over *every*
command that reaches a check — including the one that reaches it via a
programmatic delegate whose default is the opposite — and the `testserver` source
audit (I6) shows it is exactly such a command.

## 4. From formal output to the fix

The repair is iterative, and the artifacts record the exact step at which the
formalism changed the patch. The V1 fix (baseline) covered `base.py` and
`runserver.py`; the completeness audit against PO4 raised a finding against it:

> **F1: V1 changed command-line `testserver` default behavior.** *Command-line
> `testserver` without `--skip-checks` produced no `skip_checks` option in
> `testserver`'s parsed options, then delegated to `runserver` without an
> explicit value. `call_command()` would add `skip_checks=True`, and
> `runserver.inner_run()` would skip `self.check()` … Repair: add `--skip-checks`
> to `testserver` and pass `skip_checks=options.get('skip_checks', False)`.*
> — [`fvk/FINDINGS.md`](../results/verified005-codex-XC-MINI-PRO-AHP-20260615T181744Z/django__django-11292/fvk/FINDINGS.md#L6)

The same defect surfaced in the constructed model as a failed proof claim, which
is what flagged it before any code edit:

> *"The V1 proof attempt for `testserver` failed the claim
> `run(testserver, false) => <checks> N + 1`. The source delegation did not pass
> a false skip value, so the delegated programmatic `call_command('runserver')`
> path injected `skip_checks=True`. This is Finding F1 and is repaired in V2."*
> — [`fvk/PROOF.md`](../results/verified005-codex-XC-MINI-PRO-AHP-20260615T181744Z/django__django-11292/fvk/PROOF.md#L61)

Iteration guidance turned the finding into the one required edit:

> *"Finding F1 required a V2 code edit. `testserver` now exposes `--skip-checks`
> and passes the caller's skip decision to the delegated `runserver` call. This
> closes PO4 while preserving PO5."*
> — [`fvk/ITERATION_GUIDANCE.md`](../results/verified005-codex-XC-MINI-PRO-AHP-20260615T181744Z/django__django-11292/fvk/ITERATION_GUIDANCE.md#L7)

The decision log records the change and its provenance:

> *"Changed `repo/django/core/management/commands/testserver.py` … Obligation:
> PO4 requires command-line `testserver` without the flag to delegate
> `skip_checks=False` … Implementation: added `--skip-checks` to
> `testserver.add_arguments()` and passed
> `skip_checks=options.get('skip_checks', False)` to the internal `runserver`
> call."*
> — [`reports/fvk_notes.md`](../results/verified005-codex-XC-MINI-PRO-AHP-20260615T181744Z/django__django-11292/reports/fvk_notes.md#L5)

The causal chain is fully on the record:

```
SPEC I6  ->  I5 (call_command default must NOT change)
         ->  PO4 (testserver: no flag -> False, flag -> True, programmatic -> True)
         ->  F1 (V1 audit: testserver inherits programmatic skip_checks=True)
         ->  PROOF (V1 proof claim run(testserver,false) => N+1 fails)
         ->  ITERATION_GUIDANCE / fvk_notes  ->  V2 testserver patch
```

The resulting [V2 patch](../results/verified005-codex-XC-MINI-PRO-AHP-20260615T181744Z/django__django-11292/solutions/solution_fvk.patch#L53)
adds the parser argument and forwards the parsed value explicitly:

```python
parser.add_argument(
    '--skip-checks', action='store_true',
    help='Skip system checks.',
)
...
    skip_checks=options.get('skip_checks', False),
```

The `V1 -> V2` transition was driven by **finding F1 / obligation PO4**, **not**
by a new failing test — no test was written or run (see §5), and the FVK notes
state V2 differs from V1 "only where the FVK audit found a concrete defect"
([`reports/fvk_notes.md`](../results/verified005-codex-XC-MINI-PRO-AHP-20260615T181744Z/django__django-11292/reports/fvk_notes.md#L65)).

## 5. Verification

**Evidence tier 3 — source-and-artifact reviewed; not executed.** This run has no
harness proof reports and no executed demonstration. The conclusion rests on
direct review of the run artifacts:

- the two patches, confirmed to differ only in the `testserver.py` hunk
  ([`solution_baseline.patch`](../results/verified005-codex-XC-MINI-PRO-AHP-20260615T181744Z/django__django-11292/solutions/solution_baseline.patch),
  [`solution_fvk.patch`](../results/verified005-codex-XC-MINI-PRO-AHP-20260615T181744Z/django__django-11292/solutions/solution_fvk.patch#L53));
  the FVK hunk both exposes the flag and forwards
  `skip_checks=options.get('skip_checks', False)`;
- the finding, obligation, iteration guidance, and decision trace
  ([`FINDINGS.md` F1](../results/verified005-codex-XC-MINI-PRO-AHP-20260615T181744Z/django__django-11292/fvk/FINDINGS.md#L6),
  [`PROOF_OBLIGATIONS.md` PO4](../results/verified005-codex-XC-MINI-PRO-AHP-20260615T181744Z/django__django-11292/fvk/PROOF_OBLIGATIONS.md#L41),
  [`ITERATION_GUIDANCE.md`](../results/verified005-codex-XC-MINI-PRO-AHP-20260615T181744Z/django__django-11292/fvk/ITERATION_GUIDANCE.md#L5),
  [`fvk_notes.md`](../results/verified005-codex-XC-MINI-PRO-AHP-20260615T181744Z/django__django-11292/reports/fvk_notes.md#L5));
- the constructed proof and its proof-derived finding
  ([`PROOF.md`](../results/verified005-codex-XC-MINI-PRO-AHP-20260615T181744Z/django__django-11292/fvk/PROOF.md#L59)).

No RED/GREEN table is claimed because none was produced. The behavioral argument
is read off the source: with the V2 patch, omitting `--skip-checks` yields
`options.get('skip_checks', False) == False`, so the delegated `runserver` runs
its explicit check; passing the flag yields `True`; and programmatic
`call_command('testserver')` still omits the key, so `call_command()` supplies
its historical `True`. The three PO4 cases are preserved by construction, but
this was reasoned, not executed.

**Gold comparison.** The upstream human fix also wired `testserver` into the
skip-checks flow, so FVK's `testserver` edit aligns with the human oracle's
direction rather than going beyond it. No gold patch is available in this
(non-curated) run, so the comparison is by description only.

## 6. Boundaries & honesty

- **Severity: Medium.** The defect lets a valid command-line `testserver` run
  perform the wrong check behavior — a real correctness fault, not cosmetics —
  but the trigger breadth is narrow: it fires only on the single `testserver`
  delegation path, only when the flag is omitted, and only for a development-time
  command. The failure is visible in command execution (checks silently not run)
  rather than causing silent data corruption, which keeps it below High.
- **Proof status: constructed, not machine-checked.** The K artifacts
  ([`mini-django-management.k`](../results/verified005-codex-XC-MINI-PRO-AHP-20260615T181744Z/django__django-11292/fvk/mini-django-management.k),
  [`management-skip-checks-spec.k`](../results/verified005-codex-XC-MINI-PRO-AHP-20260615T181744Z/django__django-11292/fvk/management-skip-checks-spec.k))
  and the `kompile`/`kast`/`kprove` commands were *written but never run* — the
  artifacts say so explicitly
  ([`fvk/PROOF.md`](../results/verified005-codex-XC-MINI-PRO-AHP-20260615T181744Z/django__django-11292/fvk/PROOF.md#L3)).
  We therefore claim **proof-structured reasoning** (a spec with obligations
  discharged by construction), **not** a machine-checked proof. The expected
  machine-check result `#Top` is asserted, not observed.
- **Attribution.** The bug detection and the `V1 -> V2` edit are documented across
  `FINDINGS.md`, `PROOF_OBLIGATIONS.md`, `ITERATION_GUIDANCE.md`, and
  `fvk_notes.md`; the link from PO4 to the patch is traceable in those files, but
  it is reasoned, not validated by a regression run. Both arms were marked
  resolved by the official evaluation, so the value here is the residual-defect
  closure on `testserver`, established by source review rather than by a failing
  test that the harness then turns green.

## Artifact map

| Claim | Source |
|---|---|
| Issue / task statement | [`prompts/fvk.md`](../results/verified005-codex-XC-MINI-PRO-AHP-20260615T181744Z/django__django-11292/prompts/fvk.md#L2) |
| Baseline patch | [`solutions/solution_baseline.patch`](../results/verified005-codex-XC-MINI-PRO-AHP-20260615T181744Z/django__django-11292/solutions/solution_baseline.patch) |
| Baseline scope reasoning | [`reports/baseline_notes.md#L33`](../results/verified005-codex-XC-MINI-PRO-AHP-20260615T181744Z/django__django-11292/reports/baseline_notes.md#L33) |
| FVK patch (testserver hunk) | [`solutions/solution_fvk.patch#L53`](../results/verified005-codex-XC-MINI-PRO-AHP-20260615T181744Z/django__django-11292/solutions/solution_fvk.patch#L53) |
| Intent I6 (testserver delegates) | [`fvk/SPEC.md#L31`](../results/verified005-codex-XC-MINI-PRO-AHP-20260615T181744Z/django__django-11292/fvk/SPEC.md#L31) |
| Intent I5 (call_command default) | [`fvk/SPEC.md#L30`](../results/verified005-codex-XC-MINI-PRO-AHP-20260615T181744Z/django__django-11292/fvk/SPEC.md#L30) |
| Intent-only testserver clause | [`fvk/SPEC.md#L45`](../results/verified005-codex-XC-MINI-PRO-AHP-20260615T181744Z/django__django-11292/fvk/SPEC.md#L45) |
| Obligation PO4 | [`fvk/PROOF_OBLIGATIONS.md#L41`](../results/verified005-codex-XC-MINI-PRO-AHP-20260615T181744Z/django__django-11292/fvk/PROOF_OBLIGATIONS.md#L41) |
| Finding F1 | [`fvk/FINDINGS.md#L6`](../results/verified005-codex-XC-MINI-PRO-AHP-20260615T181744Z/django__django-11292/fvk/FINDINGS.md#L6) |
| Proof-derived finding | [`fvk/PROOF.md#L59`](../results/verified005-codex-XC-MINI-PRO-AHP-20260615T181744Z/django__django-11292/fvk/PROOF.md#L59) |
| Iteration instruction (V1→V2) | [`fvk/ITERATION_GUIDANCE.md#L7`](../results/verified005-codex-XC-MINI-PRO-AHP-20260615T181744Z/django__django-11292/fvk/ITERATION_GUIDANCE.md#L7) |
| Decision trace | [`reports/fvk_notes.md#L5`](../results/verified005-codex-XC-MINI-PRO-AHP-20260615T181744Z/django__django-11292/reports/fvk_notes.md#L5) |
| Proof status (not machine-checked) | [`fvk/PROOF.md#L3`](../results/verified005-codex-XC-MINI-PRO-AHP-20260615T181744Z/django__django-11292/fvk/PROOF.md#L3) |
| Constructed K core | [`fvk/mini-django-management.k`](../results/verified005-codex-XC-MINI-PRO-AHP-20260615T181744Z/django__django-11292/fvk/mini-django-management.k), [`fvk/management-skip-checks-spec.k`](../results/verified005-codex-XC-MINI-PRO-AHP-20260615T181744Z/django__django-11292/fvk/management-skip-checks-spec.k) |
