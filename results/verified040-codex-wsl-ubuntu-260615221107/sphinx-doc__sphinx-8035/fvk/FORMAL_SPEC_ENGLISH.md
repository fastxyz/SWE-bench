# Formal Spec In English

Status: paraphrase of `fvk/autodoc-private-members-spec.k`; constructed, not machine-checked.

1. Parsing `private-members` with a comma-list argument such as `_one, _two` produces a selector containing exactly `_one` and `_two`.
2. Parsing a bare `private-members` option produces the all-private selector.
3. Parsing a `True` default option value produces the all-private selector.
4. If no explicit `members` list exists and `private-members` names `_one`, the merged member request becomes exactly `_one`.
5. If an explicit `members` list already contains `public, _one` and `private-members` names `_one, _two`, the merged member request is `public, _one, _two`; `_one` is not duplicated.
6. If `members` is already the all-members selector, a finite `private-members` selector does not replace it with a finite list; the finite private selector is used later as a filter.
7. In all-members mode, a documented private member named by the finite private selector is kept.
8. In all-members mode, a documented private member not named by the finite private selector is skipped.
9. In all-members mode, the all-private selector keeps any eligible documented private member.
10. An excluded private member is skipped even if it is named by the finite private selector.
11. A mocked private member is skipped even if it is named by the finite private selector.
12. In explicit-members mode, a documented private member remains keepable even without `private-members`.
13. In all-members mode, a selected private attribute with source attribute documentation is kept even if it lacks a runtime docstring.
