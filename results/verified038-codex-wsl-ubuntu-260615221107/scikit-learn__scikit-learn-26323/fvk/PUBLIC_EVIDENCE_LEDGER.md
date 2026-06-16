# Public Evidence Ledger

Status: constructed for FVK audit, not machine-checked.

| ID | Source | Evidence | Obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | "`ColumnTransformer.set_output` ignores the `remainder` if it's an estimator" | A remainder estimator must be included in output propagation. | Encoded by PO-1 and K claim `REMAINDER-PROPAGATED`. |
| E2 | `benchmark/PROBLEM.md` | "sets the output to its sub-transformers but it ignores the transformer defined in `remainder`" | `remainder` is semantically a sub-transformer when it is an estimator. | Encoded by SPEC.md and PO-1. |
| E3 | `benchmark/PROBLEM.md` | The expected `out1` and explicit-transformer-only `out2` are identical pandas displays. | A remainder-estimator path should behave like an explicit transformer path for output container purposes. | Encoded by PO-3 and K claim `PANDAS-HSTACK`. |
| E4 | `repo/sklearn/compose/_column_transformer.py` docstring | `remainder` may be an estimator and transforms remaining non-specified columns. | The formal domain includes estimator-valued remainder with nonempty remaining columns. | Encoded in SPEC.md domain. |
| E5 | `repo/sklearn/compose/_column_transformer.py` implementation | `_validate_remainder` stores `("remainder", self.remainder, remaining)` and `_fit_transform` clones transformers when not fitted. | Pre-fit configuration must be attached to `self.remainder` so the later clone inherits it. | Encoded by PO-2 and K claim `CLONED-REMAINDER-PANDAS`. |
| E6 | `repo/sklearn/base.py` implementation | `clone` deep-copies `_sklearn_output_config` when present. | Setting output on the constructor-level remainder is sufficient for fit-time clones. | Encoded by PO-2. |
| E7 | `repo/sklearn/compose/_column_transformer.py` implementation | `_hstack` uses pandas concatenation only when config is pandas and all `Xs` have `iloc`. | The proof must preserve the "all child outputs are pandas" discriminator. | Encoded by PO-3 and K claim `PANDAS-HSTACK`. |
| E8 | `repo/sklearn/utils/_set_output.py` docstring | "If `None`, this operation is a no-op." | `_safe_set_output(..., transform=None)` must not require child `set_output`. | V1 gap, fixed by V2; encoded by PO-4 and K claim `NONE-NOOP`. |
| E9 | `repo/sklearn/utils/tests/test_set_output.py` | Estimator with transform but without set_output raises for `transform="pandas"`. | Preserve non-`None` error behavior for unconfigurable transformers. | Encoded by PO-5. |
| E10 | Repository compatibility search | No `ColumnTransformer` subclass or `set_output` override under `repo/sklearn`; `_safe_set_output` callsites are `ColumnTransformer`, `Pipeline`, and `FeatureUnion`. | Signature and virtual dispatch compatibility must be unchanged. | Encoded in `PUBLIC_COMPATIBILITY_AUDIT.md`. |
