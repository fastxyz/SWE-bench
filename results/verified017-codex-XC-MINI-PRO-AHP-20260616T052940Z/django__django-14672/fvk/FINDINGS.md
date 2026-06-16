# FVK Findings

Status: constructed, not machine-checked.

## Findings

### F-001: Pre-V1 identity could contain an unhashable list

Input:

```python
models.ManyToManyField(
    to=Parent,
    through="ManyToManyModel",
    through_fields=["child", "parent"],
)
```

Observed before V1:

```text
ForeignObjectRel.__hash__ -> hash(self.identity)
TypeError: unhashable type: 'list'
```

Expected:

The `ManyToManyRel` identity is hashable because relation objects are compared
and used in hash-based checks.

Classification: code bug fixed by V1.

Trace: E1, E2, E3 in `fvk/SPEC.md`; PO-1 and PO-2 in
`fvk/PROOF_OBLIGATIONS.md`.

### F-002: V1 discharges the list-valued `through_fields` obligation

Input:

```python
through_fields = ["child", "parent"]
```

Observed in V1:

```python
ManyToManyRel.identity
== super().identity + (
    self.through,
    make_hashable(self.through_fields),
    self.db_constraint,
)
```

Expected:

`make_hashable(["child", "parent"])` contributes `("child", "parent")`, making
the identity tuple hashable under the same local-normalization pattern already
used for `limit_choices_to`.

Classification: confirmed fix.

Trace: PO-1, PO-2, and proof step P-003.

### F-003: Converting `self.through_fields` at initialization is unnecessary and riskier

Candidate alternative:

```python
self.through_fields = make_hashable(through_fields)
```

Observed risk:

Other source paths validate and resolve `self.remote_field.through_fields` using
length checks, indexing, and slicing. A tuple would work for the common list of
strings case, but changing the stored attribute is broader than the public issue
requires and changes observable attribute shape for callers that inspect it.

Expected:

Only the identity contribution should be normalized.

Classification: rejected alternative, not a V2 source change.

Trace: E6 in `fvk/SPEC.md`; PO-3 in `fvk/PROOF_OBLIGATIONS.md`.

### F-004: A global `ForeignObjectRel.__hash__()` normalization would be overbroad

Candidate alternative:

```python
return hash(make_hashable(self.identity))
```

Observed risk:

This would silently normalize every relation identity after construction. The
issue identifies one missing identity element in `ManyToManyRel`, and the base
class already documents the intended local pattern by normalizing
`limit_choices_to` in `identity`.

Expected:

Each identity property should expose a hashable tuple by construction, with
unhashable elements normalized where they are added.

Classification: rejected alternative, not a V2 source change.

Trace: E4 and E5 in `fvk/SPEC.md`; PO-4 in `fvk/PROOF_OBLIGATIONS.md`.

### F-005: Proof is constructed but not machine-checked

Input:

The K-style model and claims in `fvk/mini-python.k` and
`fvk/many-to-many-rel-spec.k`.

Observed:

Per the benchmark constraint, no `kompile`, `kast`, `kprove`, Python, or tests
were executed.

Expected:

The proof remains an FVK constructed proof until the emitted commands are run in
an environment with K tooling.

Classification: proof honesty caveat, not a code defect.

Trace: PO-6 in `fvk/PROOF_OBLIGATIONS.md`.
