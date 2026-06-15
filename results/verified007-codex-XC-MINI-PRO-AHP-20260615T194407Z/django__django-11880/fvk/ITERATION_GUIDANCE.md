# Iteration Guidance

## Decision

V1 stands unchanged.

The FVK audit did not surface a missing source change. Findings F-001 and F-002
identify the original bug and the insufficient shallow-copy alternative; both
are discharged by the V1 line:

```python
result.error_messages = copy.deepcopy(self.error_messages, memo)
```

Finding F-003 and PO-5 confirm that no public compatibility change is needed.

## Recommended tests for a normal test-writing pass

Do not edit tests in this benchmark task. In a normal development pass, keep or
add tests for:

- direct `copy.deepcopy(field)` isolation of `error_messages`,
- nested mutable values inside `error_messages`,
- two instances of the same `Form` class mutating field messages independently,
- subclass paths that call the base deepcopy implementation.

## Machine-checking follow-up

When a K environment is available, run:

```sh
kompile fvk/mini-field-copy.k --backend haskell
kast --backend haskell fvk/field-deepcopy-spec.k
kprove fvk/field-deepcopy-spec.k
```

Until `kprove` returns `#Top`, the proof remains constructed rather than
machine-checked, and no test removal should be based on it.
