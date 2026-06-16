# FVK Notes

## Decisions

FVK finding F1 and proof obligations PO1-PO3 confirm the core V1 approach:
`ProductSet.is_subset(FiniteSet)` needs a dedicated subset-dispatch rule. The
handler should return `False` for definitely non-finite products and should use
elementwise finite-set membership for definitely finite, enumerable products.
That V1 behavior is kept.

FVK finding F2 and proof obligation PO4 showed V1 was incomplete. A product can
be known finite while iteration still fails for symbolic/undecidable
constituents. I changed `repo/sympy/sets/handlers/issubset.py` to cache
`a_product.is_finite_set` and wrap finite-product enumeration in
`try`/`except (TypeError, ValueError)`, returning `None` on enumeration failure.
This preserves SymPy's fuzzy-indeterminate behavior instead of leaking an
iterator exception from `is_subset`.

FVK finding F3 and proof obligation PO5 justify keeping the V1 equality
handlers in `repo/sympy/sets/handlers/comparison.py`. Equality between a
`ProductSet` and a `FiniteSet` is resolved by mutual subsethood, which covers
the issue's equivalent finite Cartesian product and prevents the public
`Eq(...).simplify()` traceback from reaching generic set subtraction.

FVK finding F4 records the verification status: the K proof artifacts and
commands were constructed but not executed. No tests, Python, or K tooling were
run, per the task constraints, and no test files were modified.

## Code Changes Since V1

Only `repo/sympy/sets/handlers/issubset.py` changed during the FVK pass. The
V2 change is the enumeration-failure guard required by F2/PO4.

`repo/sympy/sets/handlers/comparison.py` remains as in V1 because PO5 covers
the equality behavior and the compatibility audit in `fvk/SPEC.md` found no
signature or dispatch-shape break.

## Artifacts

The FVK package is under `fvk/`:

- `SPEC.md`
- `FINDINGS.md`
- `PROOF_OBLIGATIONS.md`
- `PROOF.md`
- `ITERATION_GUIDANCE.md`
- `mini-sympy-sets.k`
- `productset-finiteset-spec.k`

