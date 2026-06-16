# Public Evidence Ledger

## E1 - User-visible missing control

- Source: `benchmark/PROBLEM.md`
- Quote: "`SparseCoder` doesn't expose `max_iter` for `Lasso`"
- Obligation: expose a transform-time maximum-iteration parameter through the
  public sparse-coding estimator path.
- Status: encoded as `transform_max_iter` in `SparseCoder`,
  `DictionaryLearning`, and `MiniBatchDictionaryLearning`.

## E2 - Missing LassoLars forwarding

- Source: `benchmark/PROBLEM.md`
- Quote: "`max_iter` is ... not passed to `LassoLars`"
- Obligation: when the selected algorithm is `lasso_lars`, the value received
  by `sparse_encode` must be the value passed to `LassoLars(max_iter=...)`.
- Status: encoded in K claim `LASSO-LARS-FORWARD` and proof obligation PO-3.

## E3 - Existing Lasso forwarding must be preserved

- Source: `repo/sklearn/decomposition/dict_learning.py`
- Quote: V1 and pre-fix code construct `Lasso(..., max_iter=max_iter, ...)` in
  the `algorithm == 'lasso_cd'` branch.
- Obligation: the V1 change must not break the existing coordinate-descent
  forwarding path.
- Status: encoded in K claim `LASSO-CD-PRESERVE` and proof obligation PO-4.

## E4 - Transform naming convention

- Source: `repo/sklearn/decomposition/dict_learning.py`
- Quote: existing public parameters `transform_algorithm`,
  `transform_n_nonzero_coefs`, and `transform_alpha`.
- Obligation: name the new estimator-level control `transform_max_iter` rather
  than overloading `max_iter`, because `DictionaryLearning.max_iter` already
  controls the fit loop.
- Status: encoded as audit finding F-002 and proof obligation PO-1.

## E5 - Public compatibility

- Source: public source callsites found under `repo/sklearn`, `repo/examples`,
  and `repo/doc`.
- Quote: existing calls use keywords or positional arguments before the newly
  added final parameter.
- Obligation: adding the parameter must not invalidate existing calls.
- Status: encoded in `PUBLIC_COMPATIBILITY_AUDIT.md` and proof obligation PO-8.
