# FVK Notes

## Decision Summary

The FVK audit confirmed V1's central repair: `explicit_or_implicit_cause()` must stop at `None` when `__suppress_context__` is true. It also surfaced one adjacent consistency issue, recorded as F2 in `fvk/FINDINGS.md`: V1 used identity-based cause resolution, but the chain loop and explicit-cause metadata still used truthiness.

I revised the source to V2 rather than leaving V1 unchanged.

## Source Changes

### `repo/django/views/debug.py`

Kept V1's ordered cause resolver:

```python
explicit = getattr(exc_value, '__cause__', None)
if explicit is not None:
    return explicit
if getattr(exc_value, '__suppress_context__', False):
    return None
return getattr(exc_value, '__context__', None)
```

Reason: F1 and PO1 require PEP 415 cause resolution: explicit cause first, suppressed context stops traversal, unsuppressed context remains visible.

Changed:

```python
while exc_value:
```

to:

```python
while exc_value is not None:
```

Reason: F2 and PO2 require the traversal loop to use the same `None` sentinel semantics as the resolver. The issue is about whether a context edge exists, not whether an exception object is truthy.

Changed:

```python
'exc_cause_explicit': getattr(exc_value, '__cause__', True),
```

to:

```python
'exc_cause_explicit': getattr(exc_value, '__cause__', None) is not None,
```

Reason: F2 and PO3 require the frame metadata to be an explicit-cause predicate. The compatibility audit found the templates consume this key as a boolean branch flag, so returning a boolean preserves the consumer contract while matching the spec.

## Decisions Not To Change

I did not edit the technical 500 templates. PO4 and `fvk/PUBLIC_COMPATIBILITY_AUDIT.md` show the existing templates already branch on `exc_cause` and `exc_cause_explicit`; the source now supplies values matching that contract.

I did not alter cycle-warning behavior. The cycle branch is outside the reported `raise ... from None` failure and remains guarded by existing cycle detection. FVK modeled finite visible-chain traversal and recorded broader cycle-warning behavior as residual risk in `fvk/PROOF.md`.

I did not modify tests, per the benchmark instructions.

## Verification Status

The FVK proof is constructed, not machine-checked. The intended commands are recorded in `fvk/PROOF.md` and `fvk/ITERATION_GUIDANCE.md`, but were not run because this session forbids K tooling and test execution.
