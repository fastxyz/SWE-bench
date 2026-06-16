# Formal Spec in English

Status: constructed for FVK audit, not machine-checked.

## Mini Semantics

`hasReturnDescription(fields)` means that the field list contains either a
`return` field or a `returns` field. Both names map to the canonical return
description marker.

`hasReturnType(fields)` means that the field list contains an `rtype` field.

`augmentReturn(fields, hasReturnAnnotation, annotation)` models the return part
of `augment_descriptions_with_types()`.

## Claims

C-1. General add claim: for any field list, if a return annotation exists, a
return description exists, and no return type exists, return augmentation emits
`addRtype(annotation)`.

C-2. `returns` alias claim: for any tail field list with no `rtype`, a field list
beginning with `returns` and a return annotation emits `addRtype(annotation)`.

C-3. `return` alias claim: for any tail field list with no `rtype`, a field list
beginning with `return` and a return annotation emits `addRtype(annotation)`.

C-4. Existing `rtype` claim: if the field list contains `rtype`, return
augmentation emits `noRtype`, so no duplicate return type is created.

C-5. Missing return description claim: if no `return` or `returns` field is
present, return augmentation emits `noRtype` in documented-description mode.

C-6. Missing return annotation claim: if no return annotation exists, return
augmentation emits `noRtype` regardless of field names.

## Frame Conditions

F-C-1. Parameter augmentation is not represented in the return-only mini
semantics except as a frame condition: the code change does not touch the `param`
or `type` branches.

F-C-2. Public symbols, signatures, configuration names, event names, and Napoleon
output are unchanged.
