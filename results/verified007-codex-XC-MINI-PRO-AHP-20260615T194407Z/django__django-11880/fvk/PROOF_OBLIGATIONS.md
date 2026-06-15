# Proof Obligations

Constructed, not machine-checked.

## PO-1: Fresh `error_messages` identity

The copied field must not point to the same `error_messages` object as the
source field.

Formal claim: `FIELD-DEEPCOPY-COPY-ERRORS` ensures `(N +Int 2) =/=Int EO`.

Source discharge: `Field.__deepcopy__()` assigns
`result.error_messages = copy.deepcopy(self.error_messages, memo)`.

Status: discharged by V1.

## PO-2: Deep copy of message contents

The copy must be recursive enough that nested mutable message values supplied in
`error_messages` are not shared merely because the top-level dictionary was
copied.

Formal representation: the model allocates a fresh `ErrorMessagesObj` for the
copy while preserving the source payload. Python's `copy.deepcopy()` is the
source-level operation that recursively copies the mapping and its contents.

Status: discharged by V1. A `dict.copy()` alternative would not discharge this
obligation.

## PO-3: Preserve existing non-error-message copy behavior

The fix must not regress the existing widget and validator behavior in
`Field.__deepcopy__()`.

Source discharge: V1 preserves `result.widget = copy.deepcopy(self.widget, memo)`
and `result.validators = self.validators[:]`.

Status: discharged by unchanged surrounding code.

## PO-4: Compose with form instance cloning

Because `BaseForm.__init__()` constructs `self.fields` with
`copy.deepcopy(self.base_fields)`, the field-level copy contract must apply when
forms are instantiated.

Source discharge: `Field.__deepcopy__()` is the base method used by normal field
subclasses. `ChoiceField`, `MultiValueField`, and `ModelChoiceField` all route
through it before applying subclass-specific copy steps.

Status: discharged by V1.

## PO-5: Public compatibility

The fix must not change the public deepcopy protocol, method signature, return
shape, or dispatch behavior.

Source discharge: V1 changes only the method body and adds one attribute copy.

Status: discharged by compatibility audit.

## PO-6: No loop or termination obligation

`Field.__deepcopy__()` contains no loop or recursion in the audited behavior.

Status: no circularity required; partial correctness only.
