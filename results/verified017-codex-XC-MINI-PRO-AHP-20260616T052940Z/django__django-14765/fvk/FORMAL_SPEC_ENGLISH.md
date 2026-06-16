# FORMAL SPEC ENGLISH

Status: paraphrase of `fvk/projectstate-spec.k`.

## PROJECTSTATE-NONE

If the constructor is called with the `real_apps` shape `none`, it terminates
successfully. The object has `models` assigned, `real_apps` assigned to an
empty set value, `is_delayed` assigned to false, and `relations` assigned to
none.

## PROJECTSTATE-EMPTY-SET

If the constructor is called with the `real_apps` shape `emptySet`, it
terminates successfully. The object has `real_apps` assigned to that provided
empty set shape, and the unrelated successful-construction fields are assigned.

## PROJECTSTATE-NONEMPTY-SET

If the constructor is called with the `real_apps` shape `nonEmptySet`, it
terminates successfully. The object has `real_apps` assigned to that provided
non-empty set shape, and the unrelated successful-construction fields are
assigned.

## PROJECTSTATE-NONSET-ASSERTS

If the constructor is called with the `real_apps` shape `nonSet`, construction
reaches an assertion-error result after assigning `models`. It does not assign
`real_apps` by converting the non-set value, and it does not execute the later
successful-construction field assignments.

