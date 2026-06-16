# FVK Spec

Status: constructed, not machine-checked. No tests, Python code, or K tooling were executed.

## Target

Primary source target: `repo/django/forms/models.py`, class `ModelChoiceIteratorValue`.

Observable issue path:

1. `ModelChoiceIterator.choice(obj)` creates `ModelChoiceIteratorValue(self.field.prepare_value(obj), obj)`.
2. `ChoiceWidget.optgroups()` passes that value to `create_option()`.
3. User overrides of `create_option()` can perform dictionary membership and lookup with that value.

## Public intent ledger

The public evidence ledger is mirrored in `fvk/PUBLIC_EVIDENCE_LEDGER.md`.

- E1: The issue reports `TypeError: unhashable type: 'ModelChoiceIteratorValue'`; hashability is required for hashable wrapped values.
- E2: The concrete failing container is a dictionary `{1: [...]}`; dictionary membership and lookup by the wrapper must behave like lookup by the wrapped value.
- E3: List membership already works; existing value-based equality must be preserved.
- E4: The public hint proposes `def __hash__(self): return hash(self.value)`; hash must use the wrapped prepared value.
- E5: The source constructs the wrapper with both prepared value and model instance; the wrapper must not be replaced with the primitive value.
- E6: Widget code passes the choice value through to `create_option()` unchanged; the customized option path is the relevant observable.

## Contract

For all Python objects `V` and model instances `O`, let `W = ModelChoiceIteratorValue(V, O)`.

S1. If `hash(V)` is defined, then `hash(W) == hash(V)`.

S2. For any object `X`, `W == X` has the same truth value as `V == X`, except that when `X` is another `ModelChoiceIteratorValue(V2, O2)`, comparison is against `V2`.

S3. If dictionary key `K` is hashable, `hash(K) == hash(V)`, and Python equality between `K` and `W` resolves true as it does for the issue's integer key, then a dictionary entry keyed by `K` is reachable by membership and lookup using `W`.

S4. `W.value is V` and `W.instance is O` remain available. The fix must not change the choice tuple shape or widget option context shape.

S5. If `hash(V)` is not defined, `hash(W)` may raise `TypeError`. This is not a violation because hash-based containers cannot use unhashable keys.

S6. The proof does not claim support for deliberately asymmetric custom dictionary keys whose equality returns false for the wrapper even though they compare equal to the primitive wrapped value. The public issue's `{1: ...}` key is within scope.

## Reduced formal model

The supporting K artifacts are:

- `fvk/mini-python-hash.k`: a mini semantics for wrapper values, value-based equality, hashing, and singleton dictionary membership/getitem.
- `fvk/model-choice-iterator-value-spec.k`: reachability claims for hash, equality, dictionary membership, dictionary getitem, and the unhashable domain boundary.

The model intentionally excludes rendering, querysets, and form validation. Those paths are frame context for this issue: the reported failure is caused by Python hash lookup on the wrapper object after it has already reached `create_option()`.

## Exact commands not run

These are the commands a human could run in an environment with K installed. They were not executed in this task.

```sh
kompile fvk/mini-python-hash.k --backend haskell
kast --backend haskell fvk/model-choice-iterator-value-spec.k
kprove fvk/model-choice-iterator-value-spec.k
```

Expected machine-check result if the mini semantics is accepted: `#Top` for all claims.
