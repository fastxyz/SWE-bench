# Intent Spec

Status: constructed for FVK audit, not machine-checked.

## Scope

The audited behavior is the autodoc type-hint description merge path changed by
V1: `sphinx.ext.autodoc.typehints.augment_descriptions_with_types()` when
`autodoc_typehints = "description"` and
`autodoc_typehints_description_target = "documented"`.

## Intent Obligations

I-1. In documented-description mode, autodoc should add a return type to the
description only when the return value is already documented and the return type
is not already documented.

I-2. The valid Python-domain return-description field names `return` and
`returns` are aliases. Either spelling documents the return value.

I-3. Napoleon's Google-style return section emits a `returns` field, so that
field must be accepted by autodoc's documented-description detection.

I-4. If a return annotation exists and the field list contains `returns` but not
`rtype`, the output field list must receive exactly one `rtype` field whose body
is the recorded return annotation.

I-5. If `rtype` is already present, autodoc must not add a duplicate return type
field.

I-6. If the return value is not documented, documented-description mode must not
add an `rtype` field merely because a return annotation exists.

I-7. The fix must preserve existing parameter behavior: parameter descriptions
receive missing type fields only when those parameters are documented, and return
handling must not affect parameter handling.

I-8. The fix must not change public APIs, extension hooks, configuration names,
or Napoleon output format.
