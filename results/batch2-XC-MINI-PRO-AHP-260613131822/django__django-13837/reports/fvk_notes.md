# FVK notes — django__django-13837 (`get_child_arguments`)

Outcome of applying the Formal Verification Kit to the V1 fix: **V1 is confirmed correct
on its specified domain and is left unchanged (byte-for-byte).** This file justifies that
decision by tracing each judgment to a specific entry in [`fvk/FINDINGS.md`](../fvk/FINDINGS.md)
and [`fvk/PROOF_OBLIGATIONS.md`](../fvk/PROOF_OBLIGATIONS.md).

## What was audited

`repo/django/utils/autoreload.py :: get_child_arguments()`, whose V1 change replaces the
django-only, `__file__`-based `-m` detection with the documented
`__main__.__spec__.parent` mechanism. I formalized it in intent-spec mode against the
ticket's own operational criterion ("started with `-m pkg` iff
`__main__.__spec__.parent == 'pkg'`; directory/zipfile ⇒ `parent == ''`"). Because the
function has **no loop and no recursion**, the spec is a four-way branch contract (M/X/R/S
+ error) and the proof is **Case Analysis**, not a loop circularity (see
[`fvk/SPEC.md`](../fvk/SPEC.md) §1, §6 and [`fvk/PROOF.md`](../fvk/PROOF.md) §1).

## Decision log (each traced to an artifact)

1. **Keep the core `-m` detection as `__main__.__spec__.parent`.**
   Trace: **PO-M** discharged — branch M reaches `base ++ ['-m', P] ++ argv[1:]` for
   `spec=spec(P), P≠""`; **F4** confirms backward-compat (`P="django"` reproduces the
   legacy output) and the removal of `__file__` reliance (the ticket's second defect).
   ⇒ no change.

2. **Keep `getattr(__main__, '__spec__', None)` (the default), not bare
   `__main__.__spec__`.**
   Trace: **F2** (positive / needed-guard) + the guard-falsification step in
   [`fvk/PROOF.md`](../fvk/PROOF.md) §3: without the `None` default, environments lacking
   `__spec__` (Conda/embedded) would `AttributeError`. The detail is load-bearing and is
   already exactly as required. ⇒ no change.

3. **Keep the second conjunct `and __main__.__spec__.parent`.**
   Trace: **F3** (positive / needed-guard) + **PO-EXH** + the `specParentEmpty` fold:
   directory/zipfile launches have `parent == ""`, and this truthiness test is the precise
   mechanism that routes them to branch S (re-run `sys.argv`) instead of fabricating a
   bogus `-m ''`. Dropping it re-opens that branch incorrectly. ⇒ no change.

4. **Do not "fix" the non-package `python -m pkg.module` case (Finding F1).**
   Trace: **F1** + **PO-D3 [ESCALATION BOUNDARY]**. The proof of branch M needs
   precondition **D3** ("the `-m` target is a package", i.e. `spec.name ==
   parent+'.__main__'`) for the reconstruction to be faithful. D3 is exactly the ticket's
   stated scope ("a package with its own `__main__` sub-module overriding runserver"). Its
   complement — running a *non-package* sub-module via `-m` — is out of domain; deciding it
   needs an OS/import model (escalation), and it is recorded as a kept-test Finding, **not**
   admitted as `[trusted]` and **not** patched. Rationale that this is the *right* call and
   not laziness:
   - The ticket *defines* correctness as `__main__.__spec__.parent`; V1 matches it.
   - The optional refinement that would also cover F1 (use `spec.name` unless it ends in
     `.__main__`) reads `spec.name` and would **break** a test that mocks `__spec__` with
     only `.parent` set — higher risk against hidden tests for a benign-rare case
     ([`fvk/ITERATION_GUIDANCE.md`](../fvk/ITERATION_GUIDANCE.md) §3). Rejected for this
     ticket, preserved there for a future one.

5. **Do not refactor (e.g. bind `spec` once) and do not add input guards.**
   Trace: **F5** (out-of-scope, pre-existing) + [`fvk/ITERATION_GUIDANCE.md`](../fvk/ITERATION_GUIDANCE.md)
   §2. Cosmetic dedup deviates from the ticket-mandated form for zero correctness gain;
   `sys.argv==[]` is a pre-existing CPython-impossible case. Both rejected to keep the
   change minimal and test-faithful.

6. **Recommend keeping all tests (zero removals).**
   Trace: [`fvk/PROOF.md`](../fvk/PROOF.md) §8. Although PO-M/PO-S etc. nominally subsume
   single input/output unit tests, the honesty gate forbids removal before `kprove`
   returns `#Top` (the proof is *constructed, not machine-checked*), and the contract is
   proved over a *modeled* fragment with filesystem/interpreter **oracles** that the unit
   tests are exactly what pin down. Net CI time saved: 0 s.

## Why the audit did **not** force a code edit

The FVK loop's job is to surface intent/code/spec mismatches. The single substantive
mismatch it surfaced (F1) is a mismatch between V1 and an *unstated, out-of-scope* intent
(non-package `-m` sub-modules), **not** between V1 and the ticket's stated contract. On
the stated domain every obligation discharges (PO-M, PO-X, PO-R, PO-S, PO-!, PO-EXH,
PO-WF, PO-TERM — [`fvk/PROOF_OBLIGATIONS.md`](../fvk/PROOF_OBLIGATIONS.md) summary table).
Per the kit's own guidance ("do not silently regenerate or patch the code... the default
goal is to gather feedback"), and the task's allowance that a V1 "already correct
according to your spec and proof obligations ... may stand unchanged", the correct action
is to **confirm V1** and route F1 to the iteration guidance.

## Honesty / status

All proofs are **constructed, not machine-checked** — no K toolchain (or any code) was
run, per the task constraints. The Findings (F1–F6, and the positive confirmations of the
two load-bearing guards) do **not** depend on machine-checking and stand today. The
mini-Python fragment and its `exists`/path/`base` oracles are the trusted base; PO-D3 is
an explicit escalation boundary, not a hidden assumption.

## Net change to `repo/`

**None.** `get_child_arguments()` is unchanged from V1 (the
`baseline_notes.md` fix). The FVK pass added only the `fvk/` artifacts and this report.
