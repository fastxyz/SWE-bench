# FVK Spec: Add._eval_is_zero

Status: constructed, not machine-checked. No tests, Python code, or K tooling were run.

## Scope

Target function: `repo/sympy/core/add.py`, `Add._eval_is_zero`.

The proof scope is the local Add assumption decision after each argument has
been classified by existing SymPy assumption queries. The trusted base is that
subqueries such as `a.is_real`, `a.is_imaginary`, `a.is_zero`,
`(I*a).is_real`, and sign predicates are sound when they return `True` or
`False`. The FVK model does not attempt to verify all of SymPy assumptions.

## Intent Spec

1. `is_zero` may be incomplete. If it cannot decide, it should return `None`.
2. `is_zero` must not return an incorrect boolean.
3. For the reported expression `-2*I + (1 + I)**2`, the Add handler must not
   return `False`; `None` is acceptable because quick assumptions need not
   simplify or expand the expression.
4. Existing public behavior for one definitely imaginary nonzero term, such as
   `zero + I`, should remain `False`.
5. Existing behavior for an imaginary-or-zero term with unknown coefficient,
   such as `zero + r*I` for real unknown `r`, should remain `None`.

## Public Evidence Ledger

| Id | Source | Evidence | Obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | "`is_zero` should return `None` if it cannot decide, but should never give the wrong answer." | Soundness has priority over completeness. | Encoded by returning `None` for undecidable cancellation. |
| E2 | `benchmark/PROBLEM.md` | `e = -2*I + (1 + I)**2`; `e.is_zero` was `False`; `simplify(e).is_zero` was `True`. | Multi-term imaginary cancellation must not be classified as definitely nonzero. | Encoded by claim `addZero(true,false,T,false,2,U,NoSS) => U`. |
| E3 | `benchmark/PROBLEM.md` | Release note: "Fix `is_zero` becoming `False` on some expressions with `Add`." | The fix is a family-level Add zero-soundness fix, not only the literal expression. | Encoded by multi-imaginary rules. |
| E4 | `repo/sympy/core/assumptions.py` | The docs say `0` is not considered imaginary. | A single `is_imaginary=True` addend is nonzero. | Encoded by singleton imaginary claim. |
| E5 | `repo/sympy/core/tests/test_assumptions.py` | `(a + I).is_zero is False`; `(a + r*I).is_zero is None`. | Preserve public compatibility for known single imaginary and unknown imaginary-or-zero cases. | Checked in proof obligations PO6 and PO7. |
| E6 | `repo/sympy/core/add.py` | The implementation returns `None` for noncommutative Add. | Noncommutative zero remains out of local proof scope. | Preserved as a frame condition. |

## Formal Model

The local model abstracts an `Add` into summary facts used by the handler:

- `COMM`: whether the Add is commutative.
- `ALL_ZERO`: all arguments are known real zero.
- `REAL_ZERO`: tri-valued zero status of the known-real nonzero part.
- `HAS_MAYBE`: at least one term is only known to be imaginary-or-zero.
- `IM_COUNT`: number of definitely imaginary terms.
- `IM_ZERO`: tri-valued zero status of the sum of imaginary coefficients after
  multiplying each imaginary addend by `I`.
- `SIGN`: a local same-sign certificate for the imaginary coefficients:
  `SSPos`, `SSNeg`, or `NoSS`.

This abstraction preserves the property under audit. Passing instance:
`zero + I` maps to one imaginary term and returns `False`. Failing legacy
instance: `-2*I + (1 + I)**2` maps to two imaginary terms with no same-sign
certificate and unknown coefficient-zero status, which returns `None`.

Formal files:

- `fvk/mini-add-is-zero.k`
- `fvk/add-is-zero-spec.k`

Expected machine-check commands, not executed:

```sh
kompile fvk/mini-add-is-zero.k --backend haskell
kast --backend haskell fvk/add-is-zero-spec.k
kprove fvk/add-is-zero-spec.k
```

## Contract

`Add._eval_is_zero` is locally correct when every `False` it returns is
justified by one of these facts:

1. The known real part is nonzero, so imaginary-or-zero terms cannot cancel it.
2. The real part is zero and there is exactly one definitely imaginary addend.
   Since zero is not imaginary, that addend is nonzero.
3. The real part is zero and all definitely imaginary coefficients are
   nonnegative with at least one positive, or nonpositive with at least one
   negative. Their sum cannot be zero.

It may return `True` when all terms are known zero, when the real part is zero
and there are no imaginary terms, or when the imaginary coefficient sum is
known zero.

It must return `None` for unsupported, noncommutative, unknown, or cancellation
possible cases not covered by the sound `True`/`False` facts above.

## Formal Spec English

The K claim for the reported class says: a commutative Add with zero known-real
part, two definitely imaginary addends, no imaginary-or-zero term, an unknown
imaginary coefficient sum, and no same-sign certificate returns `U` (`None`).

The singleton claim says: a commutative Add with zero known-real part and
exactly one definitely imaginary addend returns `F` (`False`).

The same-sign claims say: if there are at least two definitely imaginary
addends and their real coefficients are all same-sign with a strict member,
the Add returns `F`.

The real-part claim says: if the known-real part is definitely nonzero, the Add
returns `F`.

The coefficient-zero claim says: if the known-real part is zero and the
imaginary coefficients are known to sum to zero, the Add returns `T`.

## Spec Audit

All formal claims pass the adequacy gate against the intent spec:

- The reported class is not weakened to legacy `False`; it is explicitly `U`.
- The singleton `False` behavior has independent public evidence from
  assumption docs and existing public tests.
- The same-sign `False` behavior is justified by real arithmetic, not by the
  candidate implementation.
- No claim relies on hidden tests or upstream patches.

The proof is partial correctness over the local handler. It does not prove
termination of all SymPy assumption recursion and does not prove soundness of
the entire assumptions lattice.

## Public Compatibility Audit

No public method signature, return type, or dispatch protocol changed.
`Add._eval_is_zero` still returns Python `True`, `False`, or `None`.

Publicly visible compatibility checks from source evidence:

- `zero + I`: still returns `False`, covered by the singleton imaginary
  obligation.
- `zero + r*I` with unknown real `r`: still returns `None`, because the term is
  classified as imaginary-or-zero rather than definitely imaginary.
- Noncommutative Add: still returns `None`.
