# Public Evidence Ledger

E-001, prompt: "`polylog(2, Rational(1,2))` ... Out: `polylog(2, 1/2)` ... The answer should be `-log(2)**2/2 + pi**2/12`." Semantic obligation: construction-path closed form. Status: PO-001.

E-002, prompt: "`polylog(2, Rational(1,2)).expand(func=True)` ... Out: `polylog(2, 1/2)`." Semantic obligation: expansion path must not leave this concrete value hidden. Status: PO-001.

E-003, prompt: "`polylog(1, z)` and `-log(1-z)` are exactly the same function for all purposes." Semantic obligation: order-one function expansion should be `-log(1 - z)`. Status: PO-002.

E-004, prompt: "`exp_polar` here" is not meaningful inside the logarithm argument. Semantic obligation: remove `exp_polar(-I*pi)` from the order-one expansion. Status: PO-002.

E-005, source docstring: `z in {0, 1, -1}` is automatically expressed; order `1`, `0`, and negative integer forms are documented under `expand_func`. Semantic obligation: preserve automatic-vs-opt-in placement except for the concrete issue value. Status: PO-004.

E-006, public tests/comments: old tests/comments still encode the unevaluated or polarized behavior. Semantic obligation: mark as SUSPECT because the issue identifies that behavior as buggy. Status: F-004.

E-007, implementation and proof finding: `lerchphi._eval_expand_func` delegated by direct private method call on `polylog(...)`. Semantic obligation: use an expression-level expansion helper after `polylog(...)` can evaluate to an ordinary expression. Status: PO-003.
