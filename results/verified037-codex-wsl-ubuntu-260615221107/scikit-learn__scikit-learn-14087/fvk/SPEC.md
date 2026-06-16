# FVK Spec: LogisticRegressionCV refit=False

Status: constructed from public intent and source inspection; not
machine-checked.

## Scope

This FVK pass audits the `LogisticRegressionCV.fit` no-refit selection block in
`repo/sklearn/linear_model/logistic.py`. The model covers the control decisions
that determine:

- whether OvR or multinomial coefficient-path indexing is used;
- whether `l1_ratio_` is computed from elastic-net ratios or recorded as
  absent;
- whether the public coefficient/scores/n_iter attributes receive an
  elastic-net l1-ratio dimension.

The proof abstracts away numerical optimization and cross-validation scoring.
Those upstream computations are assumed to have produced `scores`,
`coefs_paths`, `Cs_`, and `l1_ratios_` with the shapes documented by the local
comments and public docstring.

## Intent-Only Requirements

1. Fitting `LogisticRegressionCV(..., refit=False)` on an otherwise valid
   binary problem must not raise the reported `IndexError`.
2. `multi_class='auto'` selects OvR when the problem is binary or the solver is
   `liblinear`, and selects multinomial otherwise.
3. With `refit=False`, coefficients, intercepts, and `C_` are averaged from
   the per-fold winners.
4. `l1_ratios` is only used for `penalty='elasticnet'`.
5. When no elastic-net penalty is active, `l1_ratios_` is `[None]` and the
   public path/scores/n_iter attributes do not gain an l1-ratio dimension.
6. Estimator constructor parameters and public signatures are preserved.

## Public Evidence Ledger

| ID | Source | Evidence | Semantic obligation | Status |
|---|---|---|---|---|
| E-001 | issue | "IndexError thrown with LogisticRegressionCV and refit=False" | Valid no-refit fit must not use an invalid coefficient-path index. | Encoded in O-001 and O-002. |
| E-002 | issue | The reproducer uses default `multi_class='auto'`, binary `y`, `solver='saga'`; comment says same error with `liblinear`. | The fix must cover auto-to-OvR resolution for binary data and liblinear. | Encoded in O-001. |
| E-003 | issue | "Expected Results: No error is thrown." | No `IndexError` or follow-on no-refit error on the reported valid input family. | Encoded in O-001, O-003, O-004. |
| E-004 | docstring | "`auto` selects `ovr` if the data is binary, or if solver=`liblinear`, and otherwise selects `multinomial`." | Later branch decisions must use the resolved multiclass strategy, not the raw constructor string. | Encoded in O-001 and O-002. |
| E-005 | docstring | For `refit=False`, "the coefs, intercepts and C that correspond to the best scores across folds are averaged." | Best per-fold score indices drive coefficient and C selection. | Encoded in O-002 and O-003. |
| E-006 | docstring | "`l1_ratios` ... Only used if `penalty='elasticnet'`." | Non-elastic-net fits must not select or shape attributes as if l1 ratios were active. | Encoded in O-004 and O-005. |
| E-007 | docstring | "`l1_ratios_` ... If no l1_ratio is used ... this is set to `[None]`." | Non-elastic-net no-refit should append `None` for `l1_ratio_`. | Encoded in O-004. |
| E-008 | docstring | `coefs_paths_`/`scores_` gain an l1-ratio dimension "If `penalty='elasticnet'`." | Final attribute reshaping is guarded by active penalty, not by ignored constructor input. | Encoded in O-005. |
| E-009 | source | `_check_multi_class` returns the effective strategy before coefficient paths are reshaped. | Implementation fact: the local `multi_class` variable is the shape discriminator. | Used by O-001/O-002. |

## Preconditions and Domain

The audited contract ranges over valid calls that have passed the existing
input validation in `fit`: at least two classes, valid solver/penalty
combination, valid CV splits, and successfully computed scoring paths.
The contract is partial correctness only: if the upstream fit/scoring process
returns normally to the no-refit block, the no-refit block preserves valid
indexing and documented attribute shapes.

## Human-Readable Contract

For every valid no-refit fit:

- Resolve `multi_class` exactly once using `_check_multi_class`.
- If the resolved mode is OvR, each class's coefficient path is treated as a
  three-axis path `(fold, candidate, coefficient)`.
- If the resolved mode is multinomial, the coefficient path is treated as a
  four-axis path `(class, fold, candidate, coefficient)`.
- The branch deciding between those two index forms uses the resolved mode.
- `C_` is the mean of the `Cs_` entries selected by the per-fold best score
  indices modulo `len(Cs_)`.
- If the active penalty is elastic-net, `l1_ratio_` is the mean of the
  per-fold selected l1 ratios, with list-like ratios converted to an array for
  vector indexing.
- If the active penalty is not elastic-net, `l1_ratio_` records `None`, and the
  public attributes are not reshaped to expose an l1-ratio axis.

## Formal Artifacts

- `fvk/mini-logregcv.k` defines the reduced K semantics fragment.
- `fvk/logregcv-refit-false-spec.k` defines the constructed claims.
- `fvk/INTENT_SPEC.md`, `fvk/PUBLIC_EVIDENCE_LEDGER.md`,
  `fvk/FORMAL_SPEC_ENGLISH.md`, `fvk/SPEC_AUDIT.md`, and
  `fvk/PUBLIC_COMPATIBILITY_AUDIT.md` provide the FVK adequacy audit.

All formal artifacts are constructed, not machine-checked in this environment.
