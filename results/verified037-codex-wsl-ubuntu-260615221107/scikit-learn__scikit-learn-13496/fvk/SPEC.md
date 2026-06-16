# FVK Spec

Status: constructed, not machine-checked.

## Scope

This FVK pass audits the public API change for
`sklearn.ensemble.IsolationForest.__init__` and the pass-through to inherited
`BaseBagging` warm-start behavior. It does not re-prove the full anomaly
detection algorithm or tree-building semantics.

The formal core is API-level because the issue is constructor exposure and
parameter plumbing:

- `mini-iforest-api.k` defines a small constructor-state transition model.
- `iforest-warm-start-spec.k` defines reachability claims for default behavior,
  explicit `warm_start`, and positional compatibility.

## Intent Ledger

| ID | Source | Public evidence | Obligation |
| --- | --- | --- | --- |
| E1 | Problem | "Expose warm_start in Isolation forest" | Public constructor accepts `warm_start`. |
| E2 | Problem | The issue says the parent `BaseBagging` already supports incremental addition. | Forward the value to `BaseBagging`; do not duplicate fit logic. |
| E3 | Problem | "default `False`" | Omitted parameter stores `False`. |
| E4 | Problem | Requested RandomForest-style documentation text. | Document the parameter in the class docstring. |
| E5 | Source | `BaseBagging.__init__` stores `self.warm_start`; `_fit` branches on it. | Constructor pass-through is sufficient for behavior. |
| E6 | Source | `RandomForestClassifier` places `warm_start` after `verbose` and documents the requested wording. | Match the comparable estimator where it preserves compatibility. |
| E7 | Public API compatibility | `IsolationForest.__init__` is not keyword-only in this version. | Preserve old positional argument mapping. |

The standalone ledger is also recorded in `PUBLIC_EVIDENCE_LEDGER.md`.

## Contract

For all old constructor argument values accepted by the existing public
signature:

1. If `warm_start` is omitted, the constructed estimator state has
   `warm_start=False` and all old constructor fields keep their old values.
2. If `warm_start=W` is provided, the constructed estimator state has
   `warm_start=W` and all old constructor fields keep their old values.
3. The newly exposed value is passed to `BaseBagging`, whose inherited `_fit`
   implementation is responsible for reusing or rebuilding estimators.
4. The added parameter is appended after `verbose` to avoid remapping old
   positional calls.
5. The docstring states the warm-start behavior using the requested wording.

## Formal Claims

- `IFOREST-DEFAULT-WARM-START`: `oldCtor(..., verbose)` reaches an estimator
  state with `warm_start=false`.
- `IFOREST-EXPLICIT-WARM-START`: `newCtor(..., verbose, W)` reaches an
  estimator state with `warm_start=W`.
- `IFOREST-POSITIONAL-COMPAT`: an old positional call carrying distinct values
  for `n_jobs`, `behaviour`, `random_state`, and `verbose` reaches a state where
  those values still occupy those fields.

There are no loops in the modeled constructor path, so no circularity claim is
needed.

## Adequacy

The formal model keeps the property under audit observable: the constructor
argument order and the stored `warm_start` value. A failing V1 instance and a
passing V2 instance map to different states in the model:

- V1 failing abstraction: old sixth positional argument becomes `warm_start`.
- V2 passing abstraction: old sixth positional argument remains `n_jobs`.

This satisfies the FVK discriminator rule for the property being verified.
