# Proof Obligations

Status: constructed for FVK audit, not machine-checked.

## PO-1: Correct branch is audited

Show that the issue path reaches `augment_descriptions_with_types()`, not
`modify_field_list()`: `autodoc_typehints_description_target = "documented"`
selects the documented-only branch in `merge_typehints()`.

Evidence: `repo/sphinx/ext/autodoc/typehints.py` branches on
`autodoc_typehints_description_target == "all"` and otherwise calls
`augment_descriptions_with_types()`.

## PO-2: Field-scan invariant recognizes both return aliases

For every scanned prefix of the field list:

- canonical return description is present iff the prefix contains field name
  `return` or `returns`;
- canonical return type is present iff the prefix contains field name `rtype`.

V1 discharges this by using `parts[0] in ('return', 'returns')`.

## PO-3: Return `rtype` append condition is exact

After scanning, if:

- annotations contain key `return`;
- canonical return description is present;
- canonical return type is absent;

then append exactly one `rtype` field whose body is `annotations['return']`.

If any of those conditions is false, do not append a return `rtype` field in the
return augmentation step.

## PO-4: No duplicate `rtype`

If the original field list already contains `rtype`, the append condition must
be false even when `return` or `returns` is present.

## PO-5: Frame the non-defective branch and producer

The `"all"` branch and Napoleon output format are not changed. The `"all"` branch
already adds missing `rtype` based on annotations and existing `rtype`; Napoleon
already emits valid `:returns:` syntax.

## PO-6: Parameter behavior is preserved

The source change must not alter branches for `param`, typed `param`, or `type`
fields. Parameter type injection remains controlled by the existing
`has_description` and `has_type` checks for parameter names.

## PO-7: Existing `return` spelling remains accepted

The pre-existing `return` behavior must still mark the canonical return
description and trigger `rtype` insertion when the other append conditions hold.

## PO-8: Public compatibility

No public function signatures, events, config values, domain field names,
Napoleon output, or caller protocols may change.
