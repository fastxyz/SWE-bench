# Public Evidence Ledger

Status: constructed, not machine-checked.

E1. Source: prompt / issue.
Quoted evidence: "if I construct a similar ConditionSet with an ImageSet instead
of a FiniteSet, a plain `subs` gives a strange result (`Out[75]`)."
Semantic obligation: identify and remove the branch that creates the malformed
`ConditionSet` for external parameter substitution through an `ImageSet`.
Status: encoded by PO1 and PO2; resolved by F1.

E2. Source: prompt / issue.
Quoted evidence: "`xreplace({y: Rational(1,3)})`" and
"`subs({y: Rational(1,3)}, simultaneous=True)`" both produce
`{2*pi*n + asin(1/3) | n in Integers}`.
Semantic obligation: ordinary non-simultaneous `subs` should reach the same
substituted `ImageSet` for the reported external guard case.
Status: encoded by PO1 and PO2.

E3. Source: prompt / issue.
Quoted evidence: "a subs on the plain ImageSet is working as intended" with
`ImageSet(... asin(y) ...).subs(y, Rational(1,3))` producing the substituted
`ImageSet`.
Semantic obligation: the bug is not in `ImageSet.subs`; the surrounding
`ConditionSet` must not obscure the already-correct base substitution.
Status: encoded by PO2; supports rejecting an `ImageSet` edit.

E4. Source: implementation.
Quoted evidence: `ConditionSet.__new__` returns `base_set` when `condition is
S.true` at `repo/sympy/sets/conditionset.py:144-147`.
Semantic obligation: a true guard independent of the dummy has an existing
constructor-level interpretation: the whole base set.
Status: encoded by PO1.

E5. Source: public in-repo test.
Quoted evidence: `ConditionSet(n, n < x, Interval(0, oo)).subs(x, p) ==
Interval(0, oo)` and the corresponding negative-interval case returns
`S.EmptySet` in `repo/sympy/sets/tests/test_conditionset.py:125-128`.
Semantic obligation: dummy-dependent true conditions caused by assumptions use
the legacy membership fallback; a global `return base` for every true condition
would over-change behavior.
Status: encoded by PO3.

E6. Source: implementation.
Quoted evidence: `Basic._subs` calls `_eval_subs` first and does not continue
recursing if `_eval_subs` returns a value.
Semantic obligation: `ConditionSet._eval_subs` must return the fully intended
substitution result for its special cases; it cannot rely on fallback recursion
after returning the malformed set.
Status: encoded by PO1, PO2, and PO4.

