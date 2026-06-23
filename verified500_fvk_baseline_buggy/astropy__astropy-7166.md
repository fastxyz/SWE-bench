# astropy__astropy-7166

## Summary

**Severity:** Low — baseline can abort class creation for the uncommon case of a
data descriptor whose `__doc__` is read-only, because it assigns the inherited
docstring unconditionally.

Baseline correctly broadened `InheritDocstrings` to inherit docstrings for data
descriptors (properties), fixing the reported issue. The residual defect: it copies
`super_method.__doc__` onto the descriptor with an unguarded assignment, so a
descriptor that rejects `__doc__` assignment raises during metaclass `__init__` and
aborts class creation. FVK located this by formalizing a frame condition — an
ineligible-for-assignment descriptor must be left unchanged, not crash — and added a
guarded assignment.

| Arm | inherited-doc assignment to a read-only `__doc__` descriptor | Resolved |
|---|---|---|
| baseline | unguarded `val.__doc__ = ...` → raises, class creation aborts | no |
| **fvk** | `try/except (AttributeError, TypeError)` → descriptor left unchanged | yes |

## 1. The issue and the real defect

The issue: the `InheritDocstrings` metaclass "doesn't work for properties" — a
subclass `property` overriding a documented inherited property without its own
docstring keeps `None` instead of inheriting
([`fvk/SPEC.md` E1](../results/verified002-codex-XC-MINI-PRO-AHP-20260615T143019Z/astropy__astropy-7166/fvk/SPEC.md#L18)).
The cause is the eligibility filter: `InheritDocstrings` only considered members for
which `inspect.isfunction(member)` was `True`, and a `property` is a data descriptor,
not a function, so it was skipped
([`reports/baseline_notes.md`](../results/verified002-codex-XC-MINI-PRO-AHP-20260615T143019Z/astropy__astropy-7166/reports/baseline_notes.md#L5)).

## 2. Baseline's fix — and where it stopped

[Baseline](../results/verified002-codex-XC-MINI-PRO-AHP-20260615T143019Z/astropy__astropy-7166/solutions/solution_baseline.patch)
broadened the inheritable-member check to data descriptors and looked them up
statically — the right shape for the fix:

> *Expanded the inheritable-member check in `InheritDocstrings` to include data*
> *descriptors via `inspect.isdatadescriptor` … Uses `inspect.getattr_static` when*
> *copying docstrings … without invoking their `__get__`.*
> — [`reports/baseline_notes.md`](../results/verified002-codex-XC-MINI-PRO-AHP-20260615T143019Z/astropy__astropy-7166/reports/baseline_notes.md#L14)

The unmet obligation: baseline assigns `val.__doc__ = super_method.__doc__`
**unconditionally**. It widened the *eligibility* set to all data descriptors but did
not establish that every such descriptor can *accept* `__doc__` assignment. A
descriptor whose `__doc__` is read-only raises on that line, aborting class creation —
when the intended behavior is to leave it unchanged.

## 3. How FVK formally captured the gap

The intent spec includes a clause that goes beyond the reported symptom — an
assignability frame condition over the broadened eligibility set:

> *6. If an otherwise eligible descriptor cannot accept assignment to `__doc__`* […]
> *[the member is left unchanged].*
> — [`fvk/SPEC.md`](../results/verified002-codex-XC-MINI-PRO-AHP-20260615T143019Z/astropy__astropy-7166/fvk/SPEC.md#L41)

The intent ledger pins this to the audit finding about the V1 patch itself — the
broadening assigns `__doc__` unconditionally:

> **E8:** *V1 broadened eligibility to all data descriptors and assigned `__doc__`*
> *unconditionally. A descriptor with read-only `__doc__` must not abort class*
> *creation. Encoded by PO-07 and fixed in V2.*
> — [`fvk/SPEC.md`](../results/verified002-codex-XC-MINI-PRO-AHP-20260615T143019Z/astropy__astropy-7166/fvk/SPEC.md#L25)

Which discharges into the obligation baseline does not meet:

> **PO-07 — Read-Only Descriptor Doc Does Not Abort Class Creation.** *if an eligible*
> *data descriptor cannot accept `__doc__` assignment, [it is left unchanged and no*
> *exception propagates].*
> — [`fvk/PROOF_OBLIGATIONS.md`](../results/verified002-codex-XC-MINI-PRO-AHP-20260615T143019Z/astropy__astropy-7166/fvk/PROOF_OBLIGATIONS.md#L76)

The gap was located by reasoning: broadening eligibility to *all* data descriptors
introduces descriptors whose `__doc__` may be read-only, and the spec demands those
be skipped, not crashed on — a case the reported test never exercises.

## 4. From formal output to the fix

The completeness audit raised the finding:

> **F-01: V1 Could Raise On Read-Only Descriptor Doc Assignment.** *`x.__doc__ =*
> *"base doc"` is executed unguarded; class creation aborts if the descriptor doc is*
> *read-only … V2 wraps the assignment in `try/except (AttributeError, TypeError)`.*
> — [`fvk/FINDINGS.md`](../results/verified002-codex-XC-MINI-PRO-AHP-20260615T143019Z/astropy__astropy-7166/fvk/FINDINGS.md#L6)

The iteration guidance turned it into a code decision (keep V1 core, add one guard):

> *Apply one V2 guard: catch `AttributeError` and `TypeError` around `__doc__`*
> *assignment. This is justified by F-01 and PO-07.*
> — [`fvk/ITERATION_GUIDANCE.md`](../results/verified002-codex-XC-MINI-PRO-AHP-20260615T143019Z/astropy__astropy-7166/fvk/ITERATION_GUIDANCE.md#L11)

And the decision trace records the applied change and its provenance:

> *Added `try/except (AttributeError, TypeError)` around inherited docstring*
> *[assignment] … This change is traced to F-01 and PO-07.*
> — [`reports/fvk_notes.md`](../results/verified002-codex-XC-MINI-PRO-AHP-20260615T143019Z/astropy__astropy-7166/reports/fvk_notes.md#L19)

```
SPEC clause 6 / E8  ->  F-01 (V1 assigns __doc__ unguarded; read-only descriptor aborts)
                    ->  PO-07 (read-only doc must not abort class creation)
                    ->  ITERATION_GUIDANCE / fvk_notes  ->  V2 guarded assignment
```

The [FVK patch](../results/verified002-codex-XC-MINI-PRO-AHP-20260615T143019Z/astropy__astropy-7166/solutions/solution_fvk.patch)
keeps the eligibility broadening and wraps the assignment:

```python
try:
    val.__doc__ = super_method.__doc__
except (AttributeError, TypeError):
    # Some descriptors expose a read-only __doc__.
    pass
```

The V2 guard was driven by finding F-01 / obligation PO-07, **not** by a new failing
test.

## 5. Verification

**Source-and-artifact reviewed; not executed.** Not on the harness (`proof=no`), not
curated — no RED/GREEN report, no executed demonstration. What was inspected:

- The FVK patch vs baseline patch (`diff`): baseline assigns `val.__doc__` unguarded;
  FVK wraps it in `try/except (AttributeError, TypeError)`.
- F-01 / PO-07: the read-only-descriptor case is argued by static symbolic path, not
  run here.

Both arms passed the official SWE-bench evaluation; the residual is outside the
public test set.

## 6. Boundaries & honesty

- **Severity: Low.** The trigger is narrow: an *eligible data descriptor whose*
  `__doc__` *is read-only* defined under an `InheritDocstrings` class. Such
  descriptors are uncommon, so the practical blast radius is small. The value here is
  completeness of the frame condition (every broadened-eligibility member handled
  safely), not impact magnitude.
- **Evidence is static.** The crash claim rests on reading the unguarded assignment
  and the spec/obligation, plus F-01's symbolic path analysis — no read-only
  descriptor was constructed and run in this environment.
- **Why the tests missed it.** The reported test exercises an ordinary property whose
  `__doc__` is assignable; no test defines a read-only-`__doc__` descriptor, so both
  arms pass.
- **Proof status: constructed, not machine-checked.** No `kompile`/`kprove`/`kast`
  were run
  ([`fvk/PROOF.md`](../results/verified002-codex-XC-MINI-PRO-AHP-20260615T143019Z/astropy__astropy-7166/fvk/PROOF.md#L3)).
  Cited as proof-structured reasoning.

## Artifact map

| Claim | Source |
|---|---|
| Issue (properties not inherited) | [`fvk/SPEC.md#L18`](../results/verified002-codex-XC-MINI-PRO-AHP-20260615T143019Z/astropy__astropy-7166/fvk/SPEC.md#L18) |
| Baseline root cause (`isfunction` only) | [`reports/baseline_notes.md#L5`](../results/verified002-codex-XC-MINI-PRO-AHP-20260615T143019Z/astropy__astropy-7166/reports/baseline_notes.md#L5) |
| Baseline broadening to descriptors | [`reports/baseline_notes.md#L14`](../results/verified002-codex-XC-MINI-PRO-AHP-20260615T143019Z/astropy__astropy-7166/reports/baseline_notes.md#L14) |
| Baseline patch | [`solutions/solution_baseline.patch`](../results/verified002-codex-XC-MINI-PRO-AHP-20260615T143019Z/astropy__astropy-7166/solutions/solution_baseline.patch) |
| Intent clause 6 (assignability frame) | [`fvk/SPEC.md#L41`](../results/verified002-codex-XC-MINI-PRO-AHP-20260615T143019Z/astropy__astropy-7166/fvk/SPEC.md#L41) |
| Evidence E8 (V1 assigns unconditionally) | [`fvk/SPEC.md#L25`](../results/verified002-codex-XC-MINI-PRO-AHP-20260615T143019Z/astropy__astropy-7166/fvk/SPEC.md#L25) |
| Obligation PO-07 | [`fvk/PROOF_OBLIGATIONS.md#L76`](../results/verified002-codex-XC-MINI-PRO-AHP-20260615T143019Z/astropy__astropy-7166/fvk/PROOF_OBLIGATIONS.md#L76) |
| Finding F-01 | [`fvk/FINDINGS.md#L6`](../results/verified002-codex-XC-MINI-PRO-AHP-20260615T143019Z/astropy__astropy-7166/fvk/FINDINGS.md#L6) |
| Iteration instruction (V2 guard) | [`fvk/ITERATION_GUIDANCE.md#L11`](../results/verified002-codex-XC-MINI-PRO-AHP-20260615T143019Z/astropy__astropy-7166/fvk/ITERATION_GUIDANCE.md#L11) |
| Decision trace (try/except added) | [`reports/fvk_notes.md#L19`](../results/verified002-codex-XC-MINI-PRO-AHP-20260615T143019Z/astropy__astropy-7166/reports/fvk_notes.md#L19) |
| FVK patch | [`solutions/solution_fvk.patch`](../results/verified002-codex-XC-MINI-PRO-AHP-20260615T143019Z/astropy__astropy-7166/solutions/solution_fvk.patch) |
| Proof not machine-checked | [`fvk/PROOF.md#L3`](../results/verified002-codex-XC-MINI-PRO-AHP-20260615T143019Z/astropy__astropy-7166/fvk/PROOF.md#L3) |
