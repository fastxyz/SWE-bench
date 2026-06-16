# Proof Obligations

Status: constructed, not machine-checked. No tests, Python code, or K tooling were executed.

## PO-001: Hash Stability Across Model Attachment

Intent trace: I-001.

Precondition: a Django-managed `Field` has a stable `creation_counter = C`; model attachment may change only the model component from `noModel` to `model(M)`.

Claim:

```text
hash(field(C, noModel)) == hash(attach(field(C, noModel), model(M)))
```

V1 discharge:

```text
hash(field(C, noModel)) = C
attach(field(C, noModel), model(M)) = field(C, model(M))
hash(field(C, model(M))) = C
```

Result: proved by symbolic rewriting in the mini semantics.

Finding trace: F-001 and F-003.

## PO-002: Dictionary Membership Preservation For The Reported Scenario

Intent trace: I-001 and I-003.

Precondition: the same `Field` object is inserted into a dictionary before model attachment and looked up after model attachment; Python dictionary lookup requires the object's hash to remain stable and equality to identify the key.

Claim:

```text
hash_before(field) == hash_after(field)
field == field
```

V1 discharge: PO-001 gives hash stability. Object equality is reflexive for the same instance because `creation_counter` and model are the same at lookup time.

Result: the reported `assert f in d` scenario is satisfied by the model.

Finding trace: F-001.

## PO-003: Hash Compatibility With `Field.__eq__()`

Intent trace: I-003.

Precondition: two fields are in the Django-managed domain.

Claim:

```text
if field_a == field_b, then hash(field_a) == hash(field_b)
```

V1 discharge: `Field.__eq__()` requires equal `creation_counter` values and equal model values. `Field.__hash__()` depends only on `creation_counter`, so equality implies equal hashes.

Result: Python's equality/hash contract is preserved.

Finding trace: F-001.

## PO-004: Hash Uniqueness For Unequal Fields Is Not Required

Intent trace: I-002.

Precondition: two fields have the same `creation_counter` but different model values, as can happen for abstract-inherited field copies.

Claim:

```text
field(C, model(A)) != field(C, model(B)) when A != B
hash(field(C, model(A))) may equal hash(field(C, model(B)))
```

V1 discharge: equality remains false because the model values differ. The hash values collide because both are `hash(C)`. Python permits this and the issue text explicitly accepts it.

Result: no source edit is justified to preserve unequal hash values for unequal fields.

Finding trace: F-002.

## PO-005: Public API Compatibility

Intent trace: I-002 and I-003.

Claim: changing the internals of `Field.__hash__()` must not change the method signature, return type, or equality semantics.

V1 discharge:

- Signature remains `def __hash__(self)`.
- Return type remains an `int`.
- `Field.__eq__()` is unchanged.
- Ordering via `Field.__lt__()` is unchanged.

Result: source compatibility is preserved. Hash distribution changes are acceptable under PO-004.

Finding trace: F-002.

## PO-006: Honesty Gate

Intent trace: FVK methodology.

Claim: the proof must be labeled constructed, not machine-checked, because K tooling was not run.

V1 discharge: all FVK artifacts carry the "constructed, not machine-checked" status, and `fvk/PROOF.md` records the commands that would be run later.

Finding trace: F-004.
