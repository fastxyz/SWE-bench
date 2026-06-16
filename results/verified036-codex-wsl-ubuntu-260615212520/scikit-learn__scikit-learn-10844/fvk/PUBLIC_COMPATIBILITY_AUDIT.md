# PUBLIC COMPATIBILITY AUDIT

Changed public symbol: `sklearn.metrics.cluster.supervised.fowlkes_mallows_score`.

Compatibility status:

- Signature unchanged: `(labels_true, labels_pred, sparse=False)`.
- Return shape unchanged: scalar score.
- Imports unchanged:
  - `sklearn.metrics.cluster.__init__` still exports `fowlkes_mallows_score`.
  - `sklearn.metrics.__init__` still imports it through cluster metrics.
  - `sklearn.metrics.scorer` still builds a scorer from the same callable.
- No subclass or virtual-dispatch compatibility issue applies; this is a module
  function, not an overridable method.

Verdict: compatible. No source change needed.
