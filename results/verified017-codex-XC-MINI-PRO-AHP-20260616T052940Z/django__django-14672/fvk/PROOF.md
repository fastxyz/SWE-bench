# FVK Proof

Status: constructed, not machine-checked.

## Claim

V1 satisfies the public issue contract:

```python
ManyToManyRel.identity
== super().identity + (
    self.through,
    make_hashable(self.through_fields),
    self.db_constraint,
)
```

Therefore a list-valued `through_fields` does not remain in the tuple passed to
`hash(self.identity)`.

## Symbolic Proof Sketch

### P-001: Base relation identity

`ForeignObjectRel.identity` returns a tuple whose `limit_choices_to` component is
already normalized with `make_hashable(self.limit_choices_to)`.

This establishes the inherited pattern used by V1: unhashable identity elements
are normalized where they enter the identity tuple.

Discharges: PO-2, PO-4.

### P-002: Hash path

`ForeignObjectRel.__hash__()` is:

```python
return hash(self.identity)
```

During model checks, reverse relation objects can be used as dictionary keys.
Therefore every element of `self.identity` must be hashable, because Python
hashes tuple elements recursively.

Discharges: PO-1.

### P-003: V1 transition

For the reported input:

```python
self.through_fields == ["child", "parent"]
```

`make_hashable(self.through_fields)` follows the helper's list path:

```text
list(["child", "parent"])
-> tuple(map(make_hashable, ["child", "parent"]))
-> ("child", "parent")
```

Strings are already hashable, so the normalized contribution is hashable.

Discharges: PO-1, PO-2, PO-5.

### P-004: Frame condition

V1 computes `make_hashable(self.through_fields)` only inside the returned
identity tuple. It does not assign to `self.through_fields`.

Existing validation and resolution paths that use the stored attribute for
`len()`, indexing, and slicing are preserved.

Discharges: PO-3.

### P-005: Alternative rejection

Changing `ForeignObjectRel.__hash__()` would make the proof less local and would
hide identity components that fail to normalize themselves. Converting
`through_fields` in `__init__` would also discharge hashability but would change
the stored attribute. Neither broader change is required by the public issue.

Discharges: PO-3, PO-4.

## Adequacy Result

The formal claims match the intent spec:

- the issue's list-valued `through_fields` case is in domain;
- the observed pre-fix `TypeError` is removed by local normalization;
- the stored attribute is not mutated;
- no unrelated relation behavior is changed.

No finding blocks `V2 == V1`. V1 stands unchanged.

## Machine-Check Commands

These commands are provided for later verification and were not executed:

```sh
kompile fvk/mini-python.k --backend haskell
kast --backend haskell fvk/many-to-many-rel-spec.k
kprove fvk/many-to-many-rel-spec.k --backend haskell
```

Expected result if the model and claims are accepted by K: `#Top`.

## Test Recommendation

No test files were inspected or modified in this FVK pass. Hidden tests are out
of scope. Any future test-removal recommendation is conditional on actually
running the machine check above; until then, keep tests.
