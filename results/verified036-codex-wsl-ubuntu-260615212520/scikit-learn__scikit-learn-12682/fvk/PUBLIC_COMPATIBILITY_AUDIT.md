# Public Compatibility Audit

## Changed Public Symbols

- `SparseCoder.__init__`: added final parameter `transform_max_iter=1000`.
- `DictionaryLearning.__init__`: added final parameter
  `transform_max_iter=1000`.
- `MiniBatchDictionaryLearning.__init__`: added final parameter
  `transform_max_iter=1000`.
- `sparse_encode`: documentation changed to say existing `max_iter` applies to
  `lasso_lars` as well as `lasso_cd`; its signature was already present.

## Compatibility Checks

- Existing positional constructor calls remain compatible because the new
  parameter is appended at the end of each public constructor signature.
- Existing keyword constructor calls remain compatible because no parameter was
  renamed or removed.
- Internal calls to `_set_sparse_coding_params` in all in-repo subclasses were
  updated to pass the new value.
- No in-repo subclass or override of `_set_sparse_coding_params` was found.
- Existing `sparse_encode(..., max_iter=...)` callers keep the same signature;
  the behavior is extended only for `algorithm='lasso_lars'`.

## Result

No compatibility blockers were found. The change is additive at the public API
surface and targeted in the internal forwarding path.
