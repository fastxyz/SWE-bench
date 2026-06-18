# Intent Spec

Status: intent-first specification for auditing V1 of `dmp_ext_factor`.

## Scope

The audited behavior is multivariate factorization over an algebraic extension,
as reached by `factor(..., extension=[I])` through `dmp_ext_factor`.

## Intent-derived obligations

1. Extension factorization must not drop factors that are present in the input.
   For the public issue example, `(x - 1)*(y - 1)` factored with
   `extension=[I]` must include both `x - 1` and `y - 1`.
2. Factors independent of the main variable are still polynomial factors. They
   must not be treated as disposable scalar content when returning a
   multivariate factorization.
3. Multiplicities must be computed from the original polynomial. A single
   candidate for an irreducible factor is enough only if trial division checks
   and records the full power.
4. The scalar coefficient returned by factorization must combine the original
   leading coefficient with any coefficient introduced by recursively factoring
   main-variable content.
5. Existing behavior for polynomials with no main-variable content should be
   preserved: V1 should continue to use the existing square-free norm path for
   primitive factors.
6. The internal API shape of `dmp_ext_factor(f, u, K)` must remain
   `(coefficient, [(factor, multiplicity), ...])`, because its callers rebuild
   public `factor` and `factor_list` results from that shape.

## Domain assumptions

- `K` is an exact algebraic field and `u > 0`; the univariate case is delegated
  to `dup_ext_factor` and is outside this audit.
- The input is a valid dense recursive multivariate polynomial accepted by the
  surrounding SymPy factorization pipeline.
- This is a partial-correctness audit. Termination of SymPy's algebraic
  factorization algorithms is not proved here.

## Explicit non-intent

- The reported pre-fix output `x - 1` is a symptom, not an expected behavior.
- Factor ordering is not specified by the public issue. The audit checks factor
  presence, coefficient reconstruction, and multiplicity, not display order.
