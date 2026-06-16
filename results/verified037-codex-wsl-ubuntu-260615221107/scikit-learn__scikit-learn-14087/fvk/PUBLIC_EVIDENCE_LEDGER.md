# Public Evidence Ledger

| ID | Source | Evidence | Obligation |
|---|---|---|---|
| E-001 | issue | "IndexError thrown with LogisticRegressionCV and refit=False" | Remove invalid no-refit indexing. |
| E-002 | issue | Reproducer uses binary data, `solver='saga'`, `refit=False`; note says same error with `liblinear`. | Cover auto-to-OvR cases for binary and liblinear. |
| E-003 | issue | "Expected Results: No error is thrown." | Valid fit must complete past this no-refit selection block. |
| E-004 | docstring | "`auto` selects `ovr` if the data is binary, or if solver=`liblinear`, and otherwise selects `multinomial`." | Use resolved multiclass strategy for branch semantics. |
| E-005 | docstring | With `refit=False`, coefficients, intercepts, and `C` corresponding to best scores across folds are averaged. | Preserve per-fold winner averaging. |
| E-006 | docstring | "`l1_ratios` ... Only used if `penalty='elasticnet'`." | Non-elastic-net fits do not use l1 ratios. |
| E-007 | docstring | If no l1 ratio is used, `l1_ratios_` is `[None]`. | Store absence as `None`. |
| E-008 | docstring | l1-ratio dimension is documented only "If `penalty='elasticnet'`." | Shape expansion depends on active penalty. |
| E-009 | source | `_check_multi_class` returns the local resolved `multi_class`. | Local resolved variable is implementation fact needed for proof. |
