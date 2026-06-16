# FVK Proof

Status: constructed, not machine-checked. No tests, Python, `kompile`, or
`kprove` were run.

## Artifacts

- Semantics: `fvk/mini-sympy-coth.k`
- Claims: `fvk/coth-eval-spec.k`
- Specification: `fvk/SPEC.md`
- Obligations: `fvk/PROOF_OBLIGATIONS.md`
- Findings: `fvk/FINDINGS.md`

Exact commands for a later environment:

```sh
cd fvk
kompile mini-sympy-coth.k --backend haskell
kast --backend haskell coth-eval-spec.k
kprove coth-eval-spec.k
```

Expected machine-check result, if the focused mini-semantics and claims parse
as written: `#Top`.

## Proof Target

The target is the additive-period branch of `coth.eval` after
`_peeloff_ipi(arg)` has produced `(x, m)` and `m` is truthy. The verified
property is that the branch uses the just-computed `cothm = coth(m)` value as
the discriminator and returns the corresponding existing branch result.

## Claim 1 - `cothm` is `ComplexInfinity`

Precondition: `CothValue(M) ==K ComplexInfinity`.

Symbolic execution:

1. Start with `<k> cothEvalAddBranch(A, X, M) </k>`,
   `<cothm> NoExpr </cothm>`, and `<result> NoExpr </result>`.
2. Apply the entry rule:
   `cothEvalAddBranch(A, X, M) => bindCothm(M, X)`.
3. Apply the binding rule:
   `bindCothm(M, X) => chooseCothBranch(X)` and update
   `<cothm>` to `CothValue(M)`.
4. By the precondition, `<cothm>` is `ComplexInfinity`, so the
   complex-infinity rule applies:
   `chooseCothBranch(X) => return Coth(X)`.
5. Apply the return rule and update `<result>` to `Coth(X)`.

Postcondition: `<k> .K </k>`, `<cothm> ComplexInfinity </cothm>`, and
`<result> Coth(X) </result>`.

This discharges PO1 and PO2 for the modeled branch.

## Claim 2 - `cothm` is not `ComplexInfinity`

Precondition: `CothValue(M) =/=K ComplexInfinity`.

Symbolic execution:

1. Start with the same branch entry state.
2. Apply the entry rule to reach `bindCothm(M, X)`.
3. Apply the binding rule and update `<cothm>` to `CothValue(M)`.
4. The non-infinity side condition permits the second branch rule:
   `chooseCothBranch(X) => return Tanh(X)`.
5. Apply the return rule and update `<result>` to `Tanh(X)`.

Postcondition: `<k> .K </k>`, `<cothm> CothValue(M) </cothm>`, and
`<result> Tanh(X) </result>`.

This discharges PO1 and PO3 for the modeled branch.

## No Circularity

The focused branch has no loop and the recursive call `coth(m)` is abstracted
as the value `CothValue(M)`. No circularity or termination argument is required
for this local-name proof. Full recursive reasoning for all of SymPy's
evaluation machinery is outside this issue-localized proof target.

## Adequacy and Compatibility

The English meaning of the claims matches the public issue and hint: the
reported failure is an unbound read of `cotm`, and the required behavior is to
use `cothm`. The proof does not rely on hidden tests, prior results, or the
current implementation as an oracle for the bug.

The patch preserves API compatibility because it changes one local identifier
inside an existing condition and does not alter any signature or public dispatch
shape.

## Test Guidance

No tests are removed or edited. If machine-checking is later available, the
formal claims cover only the focused branch and should not be used to remove
broader SymPy tests. A regression test for the public issue would still be
valuable, but this benchmark forbids test edits.
