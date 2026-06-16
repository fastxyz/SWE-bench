# PROOF

Status: constructed, not machine-checked. No commands were run.

## Claims Proved

The proof covers the obligations in `PROOF_OBLIGATIONS.md`:

- PO1: concrete no-dimension `ImageField` does not connect `post_init`.
- PO2-PO4: concrete dimension-bearing `ImageField` still connects `post_init`.
- PO5: abstract models do not directly connect the receiver.
- PO6: skipping the no-dimension receiver is behaviorally equivalent to calling
  the existing no-op update path.
- PO7: assignment-time forced updates are preserved.
- PO8: public API shape is preserved.

## Symbolic Proof Sketch

Let:

```text
Abs = cls._meta.abstract
W = bool(self.width_field)
H = bool(self.height_field)
D = W or H
```

V1 registers the receiver exactly when:

```text
Connected = (not Abs) and D
```

### PO1

For a concrete no-dimension field:

```text
Abs = false
W = false
H = false
D = false or false = false
Connected = (not false) and false = true and false = false
```

Therefore `signals.post_init.connect(...)` is not called. This satisfies
`SPEC.md` I1 and E1-E3.

### PO2

For a concrete width-only field:

```text
Abs = false
W = true
H = false
D = true or false = true
Connected = (not false) and true = true
```

Therefore the receiver is still connected.

### PO3

For a concrete height-only field:

```text
Abs = false
W = false
H = true
D = false or true = true
Connected = (not false) and true = true
```

Therefore the receiver is still connected.

### PO4

For a concrete field with both dimensions:

```text
Abs = false
W = true
H = true
D = true or true = true
Connected = (not false) and true = true
```

Therefore the receiver is still connected.

### PO5

For an abstract model with any `W` and `H`:

```text
Abs = true
Connected = (not true) and (W or H) = false and (W or H) = false
```

Therefore the receiver is not connected, preserving the previous abstract-model
guard.

### PO6

The existing body of `update_dimension_fields()` begins by computing:

```text
has_dimension_fields = self.width_field or self.height_field
```

and immediately returns when `has_dimension_fields` is false. Therefore, for the
no-dimension state in PO1, the old connected receiver had no dimension-state
effect. Removing receiver registration preserves dimension-field state while
removing signal dispatch overhead.

### PO7

`ImageFileDescriptor.__set__()` is not edited by V1. Its relevant condition
remains:

```text
if previous_file is not None:
    self.field.update_dimension_fields(instance, force=True)
```

Thus any assignment-time update that occurred before V1 still occurs after V1.

### PO8

No public method signature changes. `ImageField.__init__()`,
`ImageField.deconstruct()`, `ImageFileDescriptor.__set__()`,
`update_dimension_fields()`, and the signal call shape are unchanged. The only
removed behavior is registration of a receiver whose first relevant action for
the no-dimension case was to return.

## Adequacy and Completeness Check

The formal claims match the intent spec:

- They prove removal only for no-dimension concrete fields, which is exactly the
  performance issue in the prompt.
- They preserve all dimension-bearing receiver registrations named by code
  comments and public tests.
- They preserve the abstract-model frame condition.
- They preserve assignment-time updates because that path is unchanged.

The audited behavior space covers the full public issue: all combinations of
abstract/concrete and no/one/both dimension-field states relevant to receiver
registration.

## Machine Check Commands

These commands are recorded for a future environment with K installed. They were
not executed in this benchmark.

```sh
cd fvk
kompile mini-django-imagefield.k --backend haskell
kast --backend haskell imagefield-post-init-spec.k
kprove imagefield-post-init-spec.k
```

Expected result: `kprove` discharges the claims in
`imagefield-post-init-spec.k` to `#Top`.

## Test Recommendation

No tests were run or modified. Because this proof is constructed rather than
machine-checked, no existing tests should be removed on the basis of this audit.
Useful tests to keep or add in a normal development environment would check:

- no `post_init` receiver is registered for an `ImageField` without dimension
  fields;
- a receiver is still registered for width-only, height-only, and both-dimension
  fields;
- abstract model receiver behavior remains unchanged;
- assignment after initialization still updates dimensions.
