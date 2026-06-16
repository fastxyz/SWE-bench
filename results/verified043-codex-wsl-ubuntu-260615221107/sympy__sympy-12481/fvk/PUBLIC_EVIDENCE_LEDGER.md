# Public Evidence Ledger

Status: evidence-only ledger for the FVK run. Candidate implementation behavior is listed only as implementation evidence, not as intent by itself.

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt | "`Permutation` constructor fails with non-disjoint cycles" | The target branch is `Permutation.__new__` handling cyclic list input. | Encoded in SPEC and K claims. |
| E2 | prompt | "`Permutation([[0,1],[0,1]])` raises a `ValueError` instead of constructing the identity permutation" | This concrete input is in domain and should return identity, not raise. | Encoded as PO-4 and claim `ISSUE-IDENTITY`. |
| E3 | prompt | "If the cycles passed in are non-disjoint, they should be applied in left-to-right order" | Cross-cycle repeated elements are allowed; order of the list is semantically significant. | Encoded as PO-1, PO-2, PO-3. |
| E4 | prompt | "I don't see a reason why non-disjoint cycles should be forbidden" | No disjointness precondition may be imposed on list-of-cycles input. | Encoded as PO-2. |
| E5 | docs | `Permutation(1, 2)(1, 3)(2, 3)` and comparison to products of separate cyclic permutations | Cycle composition is public behavior and order-sensitive. | Used to justify left-to-right fold through existing `Cycle` composition. |
| E6 | docs/tests | Singletons and `size` examples such as `Permutation([[1, 2]], size=10)` | Size-extension and singleton sizing behavior are frame conditions. | Encoded as PO-6. |
| E7 | public-test | `raises(ValueError, lambda: Permutation([1, 1, 0]))` | Array-form duplicates are still invalid. | Encoded as PO-5. |
| E8 | public-test, suspect | `raises(ValueError, lambda: Permutation([[1], [1, 2]]))` | Legacy test encodes cross-cycle duplicate rejection. | Marked SUSPECT because it conflicts with E2-E4. Not used as spec. |
| E9 | implementation | The constructor composes cyclic input with `c = c(*ci)` inside `for ci in args`. | Implementation mechanism for left-to-right fold; not intent by itself. | Modeled in mini-K and proof. |
| E10 | implementation | `Cycle.__init__` rejects duplicates within one cycle and negative integers. | Individual-cycle validity remains enforced. | Encoded as PO-7. |
