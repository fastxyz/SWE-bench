# FVK Notes

## Decision

V1 stands unchanged. No V2 production source edit was made.

The public issue requires list-valued `through_fields` to be normalized before it
enters `ManyToManyRel.identity`'s hash path. V1 does exactly that:

```python
make_hashable(self.through_fields)
```

Trace: `fvk/FINDINGS.md` F-001 and F-002; `fvk/PROOF_OBLIGATIONS.md` PO-1 and
PO-2.

## Decisions and Traceability

### Kept the V1 source fix

Reason:

`ForeignObjectRel.__hash__()` hashes `self.identity`, and Python tuple hashing
recursively hashes tuple elements. If `through_fields` remains a list in the
identity tuple, hashing fails. V1 replaces that identity element with
`make_hashable(self.through_fields)`, which maps `["child", "parent"]` to
`("child", "parent")`.

Trace:

- Finding: F-001 describes the pre-V1 failure.
- Finding: F-002 confirms V1 discharges the issue case.
- Obligation: PO-1 requires hashability for list-valued `through_fields`.
- Obligation: PO-2 requires normalization at the `ManyToManyRel.identity`
  extension point.

### Did not convert `self.through_fields` in `ManyToManyRel.__init__`

Reason:

The public issue asks for identity hashability, not a stored-attribute type
change. Other Django code validates and resolves `self.remote_field.through_fields`
with length checks, indexing, and slicing. Keeping the stored value unchanged is
the narrower compatibility-preserving fix.

Trace:

- Finding: F-003 rejects initialization-time conversion.
- Obligation: PO-3 requires identity evaluation not to mutate
  `self.through_fields`.

### Did not change `ForeignObjectRel.__hash__()`

Reason:

Normalizing the entire identity at hash time would be broader than the public
issue and would hide future identity components that should be made hashable
where they are introduced. The existing base identity already normalizes
`limit_choices_to` locally, so V1 follows that pattern for `through_fields`.

Trace:

- Finding: F-004 rejects global hash normalization.
- Obligation: PO-4 keeps the repair local to `ManyToManyRel.identity`.

### Added FVK artifacts

Reason:

The FVK pass required explicit public intent, findings, proof obligations,
constructed proof, and iteration guidance. I added the requested five markdown
artifacts under `fvk/`, plus a small K-style formal core:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`
- `fvk/mini-python.k`
- `fvk/many-to-many-rel-spec.k`

Trace:

- Finding: F-005 records the constructed-but-not-machine-checked status.
- Obligation: PO-6 lists the exact K commands and states that they were not run.

## Commands Not Run

Per the benchmark constraint, I did not run tests, Python, `kompile`, `kast`, or
`kprove`. The proof remains constructed, not machine-checked.
