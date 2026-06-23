# django__django-11206

## Summary

**Severity:** High — baseline's number formatter still renders a zero-valued
`Decimal` with a large positive exponent (e.g. `Decimal('0E+200')`) as broken
scientific notation `'0.00e+200'` instead of plain `'0.00'`.

The issue was that `utils.numberformat.format()` emitted scientific notation for
very small decimals when `decimal_pos` was supplied. Baseline fixed that for *nonzero*
small magnitudes with an `exponent < 0` guard, but a `Decimal('0E+200')` has
`exponent = 200`, skips that guard, and falls through to scientific-notation
formatting. FVK located the gap by formalizing "zero is exactly representable at every
`decimal_pos`" as an obligation and auditing baseline's branch against it, then routed
any zero to the fixed-point path.

| Arm | `nformat(Decimal('0E+200'), '.', decimal_pos=2)` | Resolved |
|---|---|---|
| baseline | `'0.00e+200'` (wrong) | no |
| gold (human oracle) | `'0.00'` | yes |
| **fvk** | `'0.00'` | yes |

## 1. The issue and the real defect

The issue: `utils.numberformat.format` renders small decimals in exponential notation —
`nformat(Decimal('1e-200'), '.', decimal_pos=2)` returned `'1.00e-200'` instead of
`'0.00'`, caused by a hardcoded 200-digit cutoff
([`_materials/problem_statement.md`](../verified500_analysis/django__django-11206/_materials/problem_statement.md#L1)).
The intended behavior: when `decimal_pos` is supplied and the value is smaller than
what those decimal places can encode, the output should be `0.0000...000`.

## 2. Baseline's fix — and where it stopped

[Baseline](../verified500_analysis/django__django-11206/_materials/baseline.patch)
added a guard so that when `decimal_pos` is non-negative and the decimal's adjusted
exponent is smaller than the displayable width, it emits a zero string instead of
scientific notation:

> *if the number's adjusted exponent is smaller than the [width], … format as `0` or*
> *`-0` instead of using scientific notation.*
> — [`reports/baseline_notes.md`](../results/verified004-codex-XC-MINI-PRO-AHP-20260615T173203Z/django__django-11206/reports/baseline_notes.md#L22)

That covers the reported `1e-200` family. The unmet obligation: baseline's guard keys
off `exponent < 0` (the adjusted exponent of a *nonzero* tiny value). A zero-valued
`Decimal('0E+200')` has `exponent = 200`, so the threshold
`exponent + len(digits) <= -decimal_pos` is false, the guard is skipped, and the value
falls through to scientific-notation formatting — `'0.00e+200'`. Baseline reasoned
from the stored-exponent shape of *nonzero* small numbers and did not account for the
zero-coefficient class.

## 3. How FVK formally captured the gap

The intent spec calls out the zero case as a distinct class, separate from the nonzero
tiny family:

> *3. Zero-valued `Decimal`s are representable at every non-negative `decimal_pos` and*
> *therefore must also use the fixed zero shape.*
> — [`fvk/SPEC.md`](../results/verified004-codex-XC-MINI-PRO-AHP-20260615T173203Z/django__django-11206/fvk/SPEC.md#L23)

The audit found this is exactly the class baseline's exponent arithmetic misses —
located by inspection, not by a failing test:

> **F3 — V1 residual zero-valued Decimal gap.** *the nonzero threshold*
> *`exponent + len(digits) <= -decimal_pos` can be false for zero, allowing the*
> *200-digit cutoff to choose scientific notation. … zero is exactly representable.*
> — [`fvk/FINDINGS.md`](../results/verified004-codex-XC-MINI-PRO-AHP-20260615T173203Z/django__django-11206/fvk/FINDINGS.md#L38)

Which is the standing formal obligation baseline does not discharge:

> **PO3 — Zero-valued Decimal family.** *For any zero-valued finite `Decimal` and*
> *`decimal_pos=N >= 0`, the output must be fixed zero with width `N`, regardless of*
> *exponent.*
> — [`fvk/PROOF_OBLIGATIONS.md`](../results/verified004-codex-XC-MINI-PRO-AHP-20260615T173203Z/django__django-11206/fvk/PROOF_OBLIGATIONS.md#L33)

The defect was located by reasoning: the issue is about magnitude (small nonzero), but
the spec generalizes to "any value whose significant digits lie beyond `decimal_pos`",
and zero is the degenerate case the nonzero-exponent guard cannot see.

## 4. From formal output to the fix

The decision trace records turning F3/PO3 into the code change:

> *Finding F3 and proof obligation PO3 showed that the nonzero adjusted-exponent*
> *threshold did not cover zero-valued Decimals with large exponents. I added*
> *`number.is_zero()` to the cutoff shortcut so zero always takes the fixed-zero path.*
> — [`reports/fvk_notes.md`](../results/verified004-codex-XC-MINI-PRO-AHP-20260615T173203Z/django__django-11206/reports/fvk_notes.md#L5)

The iteration guidance states the same instruction:

> *F3 / PO3: zero-valued Decimals need an explicit `number.is_zero()` path because*
> *adjusted-exponent arithmetic describes the first significant digit of a nonzero value.*
> — [`fvk/ITERATION_GUIDANCE.md`](../results/verified004-codex-XC-MINI-PRO-AHP-20260615T173203Z/django__django-11206/fvk/ITERATION_GUIDANCE.md#L9)

```
SPEC intent 3  ->  F3 (V1 exponent guard misses zero with large exponent)
               ->  PO3 (any zero-valued Decimal must render fixed zero)
               ->  ITERATION_GUIDANCE / fvk_notes  ->  add number.is_zero() to cutoff shortcut
```

The [FVK patch](../verified500_analysis/django__django-11206/_materials/fvk.patch)
adds `number.is_zero()` to the cutoff condition, so any zero routes to the fixed-zero
path regardless of its stored exponent. The change was driven by the formal finding
F3 / obligation PO3, **not** by a new failing test — the public test set never
includes a zero-valued Decimal with a large positive exponent (see §6).

## 5. Verification

**Executed demonstration (Tier 2; not on the harness).** This run is curated
(`analysis=yes`) but has no `enhanced_tests/_proof` RED/GREEN report, so the evidence
is the executed formatter demonstration, run directly against the formatter, not the
official harness:

```python
from decimal import Decimal
from django.utils.numberformat import format as nformat
nformat(Decimal('0E+200'), '.', decimal_pos=2)
```

| variant | output |
|---|---|
| **baseline** | `'0.00e+200'`  ← wrong: the value is exactly zero |
| **fvk** | `'0.00'`  ✅ |

The output `'0.00e+200'` is unambiguously wrong — a zero shown in exponential form.
Zero-with-exponent Decimals are reachable through ordinary arithmetic
(`Decimal('0') * Decimal('1e200')`, subtraction of equal small decimals, `quantize()`),
so the trigger is realistic.

**Gold comparison.** The official [gold patch](../verified500_analysis/django__django-11206/_materials/gold.patch)
normalizes any sub-cutoff value to `Decimal('0')` (`if abs(number) < cutoff: number = Decimal('0')`),
which yields plain `0.00` for the same input — the same fixed-zero outcome FVK reaches
via `is_zero()`. **GOLD_MATCH: partial** — FVK is closer to gold than baseline and
fixes the bug as real Django does; the only residual divergence is the pre-existing
`-0.00` sign-of-zero nuance, which is shared with baseline and not introduced by FVK.

## 6. Boundaries & honesty

- **Severity: High.** The failure mode is a *silent wrong rendering* — a value that is
  exactly zero is displayed in scientific notation — and the trigger (any zero-valued
  Decimal with a large positive exponent, reachable through normal arithmetic) is not
  exotic. A formatter returning `'0.00e+200'` is user-facing wrong output, not an
  exception.
- **Evidence executed but not on the harness.** The demonstration was run directly
  against `nformat`; it is not a SWE-bench `_proof` RED/GREEN report (`proof=no`), so
  it confirms behavior but is not harness-verified.
- **Why the tests missed it.** The FAIL_TO_PASS / PASS_TO_PASS set exercises small
  nonzero magnitudes (the `1e-200` family). Baseline's `exponent < 0` guard is fully
  covered; the zero-exponent gap is untested, so baseline scores "resolved".
- **Proof status: constructed, not machine-checked.** No `kompile`/`kprove` were run
  ([`fvk/PROOF.md`](../results/verified004-codex-XC-MINI-PRO-AHP-20260615T173203Z/django__django-11206/fvk/PROOF.md#L3)).
  Cited as proof-structured reasoning; the behavioral demo and gold match are the
  independent confirmation.

## Artifact map

| Claim | Source |
|---|---|
| Issue (small decimals in exp. notation) | [`_materials/problem_statement.md#L1`](../verified500_analysis/django__django-11206/_materials/problem_statement.md#L1) |
| Baseline guard (adjusted-exponent) | [`reports/baseline_notes.md#L22`](../results/verified004-codex-XC-MINI-PRO-AHP-20260615T173203Z/django__django-11206/reports/baseline_notes.md#L22) |
| Baseline patch | [`_materials/baseline.patch`](../verified500_analysis/django__django-11206/_materials/baseline.patch) |
| Intent clause 3 (zero is representable) | [`fvk/SPEC.md#L23`](../results/verified004-codex-XC-MINI-PRO-AHP-20260615T173203Z/django__django-11206/fvk/SPEC.md#L23) |
| Finding F3 (zero-valued gap) | [`fvk/FINDINGS.md#L38`](../results/verified004-codex-XC-MINI-PRO-AHP-20260615T173203Z/django__django-11206/fvk/FINDINGS.md#L38) |
| Obligation PO3 | [`fvk/PROOF_OBLIGATIONS.md#L33`](../results/verified004-codex-XC-MINI-PRO-AHP-20260615T173203Z/django__django-11206/fvk/PROOF_OBLIGATIONS.md#L33) |
| Decision trace (`is_zero()`) | [`reports/fvk_notes.md#L5`](../results/verified004-codex-XC-MINI-PRO-AHP-20260615T173203Z/django__django-11206/reports/fvk_notes.md#L5) |
| Iteration instruction | [`fvk/ITERATION_GUIDANCE.md#L9`](../results/verified004-codex-XC-MINI-PRO-AHP-20260615T173203Z/django__django-11206/fvk/ITERATION_GUIDANCE.md#L9) |
| FVK patch | [`_materials/fvk.patch`](../verified500_analysis/django__django-11206/_materials/fvk.patch) |
| Gold patch (normalize to `Decimal('0')`) | [`_materials/gold.patch`](../verified500_analysis/django__django-11206/_materials/gold.patch) |
| Proof not machine-checked | [`fvk/PROOF.md#L3`](../results/verified004-codex-XC-MINI-PRO-AHP-20260615T173203Z/django__django-11206/fvk/PROOF.md#L3) |
