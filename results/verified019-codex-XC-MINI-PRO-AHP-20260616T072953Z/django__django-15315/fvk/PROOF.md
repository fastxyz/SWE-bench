# Constructed Proof

Status: constructed, not machine-checked. No tests, Python code, or K tooling were executed.

## Machine-Check Commands Not Run

The FVK method would machine-check the formal core with:

```sh
cd fvk
kompile mini-field-hash.k --backend haskell
kast --backend haskell field-hash-spec.k
kprove field-hash-spec.k
```

Expected result after a successful machine check: `kprove` returns `#Top` for the claims in `field-hash-spec.k`.

These commands were intentionally not executed because the task forbids running K tooling.

## Proof Summary

The audited behavior has no loops or recursion, so no circularity claim is required. The proof is a direct symbolic rewrite over a two-component field model: `field(creation_counter, model_key)`.

The V1 implementation corresponds to:

```text
hash(field(C, M)) = C
attach(field(C, M0), M1) = field(C, M1)
eq(field(C1, M1), field(C2, M2)) = (C1 == C2 and M1 == M2)
```

## PO-001: Hash Stability Across Attachment

Start:

```text
hash(attach(field(C, noModel), model(M)))
```

Apply `attach`:

```text
hash(field(C, model(M)))
```

Apply `hash`:

```text
C
```

This is equal to the pre-attachment hash:

```text
hash(field(C, noModel)) = C
```

Therefore model attachment does not change the hash in the V1 model.

## PO-002: Dictionary Membership Preservation

The reported program inserts the exact same `Field` object into a dictionary and later looks up that same object after model contribution.

PO-001 proves the hash bucket remains stable across that transition. `Field.__eq__()` is unchanged and is reflexive for the same object state at lookup. The dictionary membership condition used by the issue is therefore preserved.

## PO-003: Equality/Hash Compatibility

Assume:

```text
field_a == field_b
```

By the unchanged `Field.__eq__()` definition:

```text
field_a.creation_counter == field_b.creation_counter
field_a.model == field_b.model
```

By V1 `Field.__hash__()`:

```text
hash(field_a) = hash(field_a.creation_counter)
hash(field_b) = hash(field_b.creation_counter)
```

Since the creation counters are equal, the hash values are equal. The Python hash contract is discharged.

## PO-004: Unequal Fields May Collide

For abstract-inherited fields:

```text
field_a = field(C, model(A))
field_b = field(C, model(B))
A != B
```

Equality remains false because model keys differ:

```text
eq(field_a, field_b) = false
```

Hash values collide:

```text
hash(field_a) = C
hash(field_b) = C
```

This is valid because Python dictionaries resolve collisions with equality checks. The public issue explicitly accepts this outcome, so the proof does not preserve the legacy stronger property that unequal fields must have unequal hashes.

## Adequacy Gate

Formal English: "Attaching a model changes only the model component of a field and leaves the hash equal to the construction counter."
Intent match: passes I-001.

Formal English: "Equal fields have equal hashes because equality includes equal construction counters."
Intent match: passes I-003.

Formal English: "Unequal fields can share a hash."
Intent match: passes I-002.

No formal claim is candidate-derived without public support. The only conflicting public evidence is the legacy test expectation recorded in F-002, and it is classified as SUSPECT because it conflicts with I-002.

## Test Recommendations

Do not modify tests in this task.

Recommended future regression coverage:

- Add a test matching the issue reproducer: create a field, insert it into a dictionary, attach it to a model, and assert the field is still in the dictionary.
- Update any legacy test that asserts unequal hashes for unequal abstract-inherited fields to assert only field inequality and ordering.

No test removal is recommended until the K claims are machine-checked.

## Residual Risk

The proof is constructed over a mini semantics, not the full Python or Django runtime. It directly models the state components relevant to this issue: `creation_counter`, model attachment, equality, and hash.

Termination is not a concern for the audited unit because `Field.__hash__()` has no loop or recursion.

The proof remains un-machine-checked until the commands above are run in an environment with K.
