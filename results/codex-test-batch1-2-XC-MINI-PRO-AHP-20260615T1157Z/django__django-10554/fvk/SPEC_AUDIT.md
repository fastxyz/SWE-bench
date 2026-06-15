# Spec Audit

Status: constructed, not machine-checked.

| Formal statement | Intent entry | Verdict | Notes |
| --- | --- | --- | --- |
| Derived values-list query must not change the source ordered union's child select widths. | I-1, I-2, I-3 | Pass | This is the exact behavior reported as broken. |
| The source ordered union must remain orderable after derived query evaluation. | I-1, I-3 | Pass | Matches the desired post-reproduction `qs` evaluation. |
| Derived query children may be narrowed to width 1. | I-3 | Pass | The derived `values_list('pk')` should be allowed to select only `pk`. |
| The fix is at `Query.clone()`. | I-2 plus E-5 | Pass | Public hint says copy before query mutation; source shows queryset derivation goes through `Query.clone()`. |
| No `_combinator_query()` construction change is required. | I-4 plus E-7 | Pass | The reported sequence derives after the union exists; changing construction semantics is unnecessary for the specified behavior. |
| Two-child model represents the issue. | Domain statement | Pass | `union()` reproduction has two branches; n-ary combined queries extend pointwise. |

No formal-English obligation is candidate-derived without public evidence. No
legacy/pre-fix behavior is preserved as a desired outcome.
