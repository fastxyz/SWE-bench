# FVK Specification

Constructed, not machine-checked.

## Target

Production unit under audit:

- `repo/django/forms/fields.py`: `Field.__deepcopy__(self, memo)`

Composing callsite:

- `repo/django/forms/forms.py`: `self.fields = copy.deepcopy(self.base_fields)`

## Public intent ledger

The full ledger is in `fvk/PUBLIC_EVIDENCE_LEDGER.md`. The critical public
obligations are:

- `error_messages` must be copied during field deepcopy.
- The copy must remove object aliasing between copied fields.
- The copy must be deep enough for nested mutable message values.
- The copy must preserve configured messages and existing widget/validator
  behavior.
- The method signature and deepcopy protocol must remain compatible.

## Formal model

The mini K model in `fvk/mini-field-copy.k` represents Python object identity
with integer object ids in a heap:

- `FieldObj(WO, EO, VO)` stores references to widget, error_messages, and
  validators objects.
- `ErrorMessagesObj(EP)` stores an abstract error-message payload.
- `deepcopyField(F)` allocates a fresh field and fresh child objects using the
  `<next>` allocator cell.

This abstraction intentionally preserves the property under audit: object
identity of `error_messages`. A failing implementation that reused `EO` for the
copied field would be distinguishable from the passing implementation because
the copied field would not point to `N + 2`.

## Function contract

Claim `FIELD-DEEPCOPY-COPY-ERRORS` in `fvk/field-deepcopy-spec.k` states:

Given an allocated field `F` with allocated, distinct widget, error_messages,
and validators objects, and a fresh allocator counter `N`, executing
`deepcopyField(F)` returns a new field id `N`. The new field points to fresh
widget, error_messages, and validators ids. The new error_messages object has
the same payload as the source object but a distinct identity from the source
error_messages object.

## Preconditions

- The source field and child object ids are allocated and distinct.
- The allocator counter is fresh relative to those ids.

These preconditions are model-side allocation invariants, not new Django API
requirements.

## Postconditions

- Source field state is preserved.
- Copied field state is produced.
- `copied.error_messages` has preserved contents and fresh identity.
- Existing widget deepcopy and validators list-copy behavior are preserved.

## Loops

No loops or recursion occur in `Field.__deepcopy__()`, so there are no loop
circularities.

## Exact commands not executed

The task forbids running K tooling. These commands are the constructed commands
to machine-check later:

```sh
kompile fvk/mini-field-copy.k --backend haskell
kast --backend haskell fvk/field-deepcopy-spec.k
kprove fvk/field-deepcopy-spec.k
```
