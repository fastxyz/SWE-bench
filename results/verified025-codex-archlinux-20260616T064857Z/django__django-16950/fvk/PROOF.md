# Constructed Proof

Status: constructed, not machine-checked. No commands in this file were run.

## Formal Claims

The K artifacts are:

- `fvk/mini-inline-formset.k`
- `fvk/inline-formset-spec.k`

Exact commands to machine-check later:

```sh
kompile fvk/mini-inline-formset.k --backend haskell
kast --backend haskell fvk/inline-formset-spec.k
kprove fvk/inline-formset-spec.k
```

Expected machine-check result, if the K files are accepted and the claims
discharge: `#Top`.

## Proof Sketch

### PO-001 and PO-002: defaulted non-PK `to_field`

Assume:

- `self.instance._state.adding` is true;
- `kwargs["to_field"]` names the parent alternate key;
- `to_field.has_default()` is true;
- `to_field.primary_key` is false.

In V1, `BaseInlineFormSet.add_fields()` enters the `has_default()` branch and
then the `else` arm of `if to_field.primary_key`. That arm writes only
`kwargs["initial"] = None`; it does not call `setattr()` on the parent. Therefore
the parent alternate key remains unchanged.

`InlineForeignKeyField(self.instance, **kwargs)` then receives an explicit
`initial=None`. V1's constructor checks
`self.parent_instance is not None and "initial" not in kwargs` before deriving
initial from the parent, so the explicit empty initial is preserved. Thus the
parent value is preserved while the hidden inline field initial is empty.

This discharges PO-001 and PO-002 and resolves F-001/F-002.

### PO-003: defaulted primary key

Assume the same adding/defaulted state, but the target field is the parent
primary key. V1 enters `if to_field.primary_key` and executes
`setattr(self.instance, to_field.attname, None)`, matching the pre-V1 behavior
for defaulted primary keys. Because no explicit `initial` is supplied, the
`InlineForeignKeyField` constructor derives initial from the now-empty parent
key, so the inline field initial remains empty.

This preserves the public UUID primary-key behavior and discharges PO-003.

### PO-004 and PO-005: constructor and validation compatibility

V1 changes only the guard around automatic initial derivation:

```python
if self.parent_instance is not None and "initial" not in kwargs:
```

When no caller supplies `initial`, this condition is equivalent to the old
condition and the constructor derives initial from `to_field` or `pk` exactly as
before. When a caller supplies `initial`, Django's base `Field` constructor
already accepts it, so V1 lets that explicit value pass through.

`InlineForeignKeyField.clean()` is unchanged. Non-empty values are still compared
against the current parent value; empty values still return `None` for
`pk_field` and the parent instance otherwise.

This discharges PO-004, PO-005, and F-003.

### PO-006: downstream FK assignment

`BaseInlineFormSet._construct_form()` runs after `add_fields()` and computes:

```python
fk_value = getattr(self.instance, self.fk.remote_field.field_name)
```

when the FK points to a non-PK target. Since PO-001 proves the parent alternate
key was not cleared, `_construct_form()` reads the preserved UUID and assigns it
to the child form instance FK attname before validation. On save,
`save_new()` also assigns the latest parent instance to the child, preserving the
relationship after the parent has been saved.

This discharges PO-006.

### PO-007: public compatibility

No method signature changed. The new behavior is activated only when
`BaseInlineFormSet.add_fields()` supplies an explicit `initial` for the
defaulted non-PK `to_field` case. Existing callers that omit `initial` still
derive initial from the parent. Therefore there is no public compatibility
regression found by the audit.

This discharges PO-007.

## Test Redundancy Recommendation

No tests should be removed. The proof was not machine-checked, and the task
forbids modifying tests. Existing UUID inline formset tests remain valuable,
especially because they cover the empty hidden initial behavior while the issue
also requires parent-value preservation.

## Residual Risk

The proof is partial correctness over a reduced state-transition model. It does
not machine-check real Python or Django. It does distinguish the property that
caused the issue: pre-fix mutation of a defaulted non-PK parent target collapses
to `parentTarget=noneValue`, while V1 keeps `parentTarget=someValue`.
