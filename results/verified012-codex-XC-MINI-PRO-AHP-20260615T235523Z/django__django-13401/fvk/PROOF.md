# Constructed Proof

Status: constructed, not machine-checked. No tests, Python, `kompile`, `kast`,
or `kprove` were run.

## Machine-Check Commands Not Run

These are the commands to run later in an environment with K installed:

```sh
kompile fvk/mini-field-comparison.k --backend haskell
kast --backend haskell fvk/field-comparison-spec.k
kprove fvk/field-comparison-spec.k
```

Expected machine-check result after any needed syntax adjustments for the local
K version: `#Top` for the claims in `fvk/field-comparison-spec.k`.

## Proof Sketch

### PO-EQ-OWNER

V1 source:

```python
return (
    self.creation_counter == other.creation_counter and
    getattr(self, 'model', None) == getattr(other, 'model', None)
)
```

Symbolic execution of `fieldEq(Field(C1, M1), Field(C2, M2))` rewrites to
`(C1 == C2) and sameModel(M1, M2)`. If `C1 == C2` and `M1 != M2`, the result is
`false`. Therefore same-counter fields copied onto different model owners do
not compare equal.

### PO-HASH-CONSISTENCY

V1 source:

```python
return hash((self.creation_counter, getattr(self, 'model', None)))
```

If `f == g`, PO-EQ-OWNER gives equal counters and equal owners. The hash tuple
components are therefore identical, so Python's hash contract for equal tuples
gives equal hashes. This proves hash consistency for the new equality relation.

### PO-SET-CARDINALITY

For the issue reproduction, abstract inheritance creates two field objects with
the same copied counter but different owners `B` and `C`. PO-EQ-OWNER gives
`B.myfield != C.myfield`. Python set insertion retains a new element whenever
no existing element compares equal to it. Therefore the set cardinality is 2.

### PO-LT-PRIMARY-COUNTER

V1 source:

```python
if self.creation_counter != other.creation_counter:
    return self.creation_counter < other.creation_counter
```

For all different-counter fields, symbolic execution takes this branch before
the model key is evaluated. Thus different-counter ordering is exactly the old
counter ordering, satisfying the issue's preservation warning.

### PO-LT-COLLISION

For equal counters, V1 source rewrites to comparison of:

```python
self._model_sort_key(getattr(self, 'model', None))
other._model_sort_key(getattr(other, 'model', None))
```

For attached model fields, `_model_sort_key()` is
`(model._meta.label_lower, id(model))`; for unattached fields it is `()`. Thus
same-counter fields from different model labels have a strict label ordering,
and same-label distinct model objects have an identity tie-breaker. This
matches the required "model only after counter" behavior.

### PO-ABSTRACT-CLONE

`ModelBase` copies fields from abstract bases with `copy.deepcopy(field)`, so
the copied fields keep the abstract field's `creation_counter`. The copied
field is then added through `new_class.add_to_class()`, and
`Field.contribute_to_class()` assigns `self.model = cls` before calling
`cls._meta.add_field()`. Therefore owner-sensitive equality has the data it
needs when model metadata stores and orders fields.

## Completeness Check

The proof covers the full public intent of the issue:

- equality for same-counter/different-owner abstract field copies;
- set retention of both copied fields;
- hash consistency with equality;
- creation-counter-primary ordering;
- no public signature change.

No additional production edit is justified by the FVK findings.

## Residual Risk

The proof is constructed, not machine-checked. Termination is irrelevant for
these comparison methods because the modeled methods are straight-line and
finite, but this session still did not execute Python or K tooling.

Test deletion is not recommended. If public tests are later added for this
bug, they should be kept until the K commands above are machine-checked.
