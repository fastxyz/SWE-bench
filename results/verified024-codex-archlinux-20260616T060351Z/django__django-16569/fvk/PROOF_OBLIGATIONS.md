# Proof Obligations

Status: constructed, not machine-checked.

## PO1 - Domain

`initial_form_count` is a nonnegative integer. `index` is either `None` for
the empty template form or a nonnegative integer form index.

Trace: I2, I8, E3, E6.

## PO2 - Empty-form safety

For all `N >= 0`, evaluating the delete-field decision with
`can_delete=True`, `can_delete_extra=False`, and `index=None` does not compare
`None` to `N`, does not raise `TypeError`, and does not add `DELETE`.

Trace: I1, I2, I3, E1, E2, E3, E4, E6. Finding: F1.

## PO3 - Delete-field truth table

For all in-domain indexes and `N >= 0`, `DELETE` is added exactly according to:

```text
can_delete and (
    can_delete_extra or (index is not None and index < N)
)
```

Sub-obligations:

- PO3a: `can_delete=False` implies no `DELETE`.
- PO3b: `can_delete=True` and `can_delete_extra=True` implies `DELETE`.
- PO3c: `can_delete=True`, `can_delete_extra=False`, `index=None` implies no
  `DELETE` and no exception.
- PO3d: `can_delete=True`, `can_delete_extra=False`, `0 <= index < N` implies
  `DELETE`.
- PO3e: `can_delete=True`, `can_delete_extra=False`, `index >= N` implies no
  `DELETE`.

Trace: I3, I4, I5, I6, E4, E5. Findings: F1, F2.

## PO4 - Frame conditions

The V1 edit must not change:

- ordering-field insertion or ordering initial values;
- non-delete fields added by the form or by subclass overrides;
- behavior for numeric indexes except for using the same comparison only after
  proving `index is not None`.

Trace: I7, E5, E7. Findings: F2, F3.

## PO5 - Public compatibility

The V1 edit must preserve:

- `add_fields(self, form, index)` signature;
- `empty_form` calling `add_fields(form, None)`;
- `BaseModelFormSet` and `BaseInlineFormSet` delegation through `super()`;
- documented subclass override style.

Trace: I2, I7, E6, E8 and `PUBLIC_COMPATIBILITY_AUDIT.md`. Finding: F3.

## PO6 - Termination and exceptions

The modeled delete-field condition is straight-line and terminates under the
domain assumptions. Partial correctness is sufficient for this FVK pass. The
proof explicitly tracks the absence of the reported exception on `index=None`.

Trace: I1, E1, E2. Finding: F1.

## PO7 - Machine-check commands

The following commands would machine-check the constructed K artifacts in an
environment with K installed. Run them from `fvk/`. They were not executed.

```sh
kompile mini-python-formset.k --main-module MINI-PYTHON-FORMSET --syntax-module MINI-PYTHON-FORMSET-SYNTAX --backend haskell
kast --backend haskell formset-add-fields-spec.k
kprove formset-add-fields-spec.k --spec-module FORMSET-ADD-FIELDS-SPEC
```
