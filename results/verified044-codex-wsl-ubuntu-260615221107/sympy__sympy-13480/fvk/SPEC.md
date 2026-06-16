# FVK Specification

Status: constructed, not machine-checked.

## Scope

This FVK pass audits the V1 change in
`repo/sympy/functions/elementary/hyperbolic.py`, specifically
`coth.eval` lines 586-593. The verified unit is the additive-period branch
entered after:

- `arg` is not handled by the numeric, infinity, imaginary-coefficient, or
  negative-argument branches;
- `arg.is_Add` is true;
- `_peeloff_ipi(arg)` returns `(x, m)`;
- `m` is truthy.

The proof is partial correctness for that branch. It does not attempt to prove
all mathematical identities of `coth`, all of `subs`, or termination.

## Intent-Only Spec

Public intent requires that substituting integral values into
`coth(log(tan(x)))` must not raise `NameError` from `coth.eval`. When the
additive-period branch computes `cothm = coth(m)`, the following condition must
read that same local value:

- if `cothm is S.ComplexInfinity`, return `coth(x)`;
- otherwise return `tanh(x)`.

No public requirement changes the `coth.eval` API, the public return type shape,
or unrelated branches.

## Public Evidence Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt | ".subs on coth(log(tan(x))) errors for certain integral values" | The in-domain substitution/evaluation path must not raise the reported `NameError`. | Encoded by PO1 and claims in `coth-eval-spec.k`. |
| E2 | prompt traceback | `if cotm is S.ComplexInfinity` then `NameError: name 'cotm' is not defined` | `cotm` is the faulty unbound read to remove. | Finding F1. |
| E3 | public hint | "`cotm` should be `cothm`" | The condition must use the just-computed `cothm`. | Encoded by PO1. |
| E4 | code docstring/name | `coth` is the hyperbolic cotangent function. | The branch is about hyperbolic `coth`, not trigonometric `cot`. | Supports rejecting the `cot(m)` alternative. |
| E5 | code helper docstring | `_peeloff_ipi` splits an Add into rest plus a multiple of `I*pi/2`. | The branch is a periodic-offset simplification over `(x, m)`. | Modeled as the spec pre-state. |
| E6 | implementation analogy | Neighboring `tanh.eval` computes `tanhm` and tests `tanhm`; trigonometric `cot.eval` computes `cotm` and tests `cotm`. | Local branch discriminators should test their own assigned local value. | Implementation evidence consistent with E3, not an independent public requirement. |
| E7 | public tests | `test_coth` covers special values such as `coth(pi*I/2) == 0` and `coth(k*pi*I) == -cot(k*pi)*I`. | Existing public behavior has established special-value handling; this fix should not change it. | Compatibility/frame condition PO4. |

## Formal Model

The formal core is in:

- `fvk/mini-sympy-coth.k`
- `fvk/coth-eval-spec.k`

`CothValue(M)` abstracts the recursive SymPy call `coth(m)`. The model keeps
the defect-relevant observable: whether the branch reads the bound `cothm`
value and returns `Coth(X)` or `Tanh(X)`.

The intentionally reduced model does not encode every SymPy expression type.
That is acceptable for this audit because the public issue and traceback
localize the failure to the local-name read inside this branch.

## Formal Spec English

Claim 1, complex-infinity branch: for any additive-branch state with parts
`X` and `M`, if the computed value `CothValue(M)` is `ComplexInfinity`, then
evaluation reaches a return value equivalent to `coth(X)`, and the branch does
not read an unbound name.

Claim 2, non-complex-infinity branch: for any additive-branch state with parts
`X` and `M`, if the computed value `CothValue(M)` is not `ComplexInfinity`,
then evaluation reaches a return value equivalent to `tanh(X)`, and the branch
does not read an unbound name.

No loop or recursion circularity is needed in the focused branch model.

## Adequacy Audit

| Formal obligation | Intent match | Result |
| --- | --- | --- |
| Read `cothm` after assigning `cothm = coth(m)` | Directly entailed by public hint E3 and by the traceback E2. | Pass |
| Return `coth(x)` when `cothm is S.ComplexInfinity` | Matches the existing intended branch structure once the typo is corrected. | Pass |
| Return `tanh(x)` in the non-infinity branch | Matches existing branch comment and neighboring periodic simplification structure; no public evidence suggests changing it. | Pass |
| Preserve public API and unrelated branches | No public requirement asks for API or branch changes. | Pass |

No adequacy failure or ambiguous obligation blocks the conclusion that V1 can
stand unchanged.

## Public Compatibility Audit

Changed symbol: `coth.eval(cls, arg)`.

- Signature: unchanged.
- Public call sites: unchanged because the method is still called through the
  existing `Function` evaluation mechanism.
- Return shape: unchanged except that the previously failing branch now returns
  the branch result already encoded in the surrounding implementation.
- Overrides/subclasses: no new virtual dispatch or keyword arguments added.
- Tests: no test files modified.

Compatibility status: pass.
