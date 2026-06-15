# Proof Obligations

Status: constructed, not machine-checked.

## PO1: Chain coverage

For every finite primary-key parent-link chain
`F0 -> F1 -> ... -> Fn` rooted at `self._meta.pk`, `_set_pk_val(value)` writes
`value` to every `Fi.attname`.

- Evidence: E3 and E4.
- V1 discharge: the loop writes the current field's attname before following
  `field.target_field`; it stops only when the current field is not a parent
  link.
- Finding link: F2.

## PO2: Loop termination

The `_set_pk_val()` loop terminates.

- Evidence: Django model inheritance metadata is finite; parent-link targets
  move from child to concrete parent fields.
- V1 discharge: each iteration follows a target field toward an ancestor; the
  final concrete parent PK has no `remote_field.parent_link`.
- Residual risk: malformed metadata with a cycle is outside normal Django model
  construction.

## PO3: Frame condition

Fields outside the active primary-key parent-link chain are not assigned by
`_set_pk_val()`.

- Evidence: E5 and compatibility audit.
- V1 discharge: the loop starts only at `self._meta.pk` and follows only
  `target_field` while that field is a parent-link primary key.
- Finding link: F3 and F5.

## PO4: Save-path consequence

After `instance.pk = None`, ordinary `save()` must not update the old parent
row through stale PK values in the active primary-key chain.

- Evidence: E2 and E7.
- V1 discharge: PO1 makes every chain PK value `None`; `_save_table()` only
  attempts an update when the class-specific `pk_val` is not `None`.
- Assumption: ordinary save means no `force_update` and no `update_fields`, as
  in the issue reproduction and Django's copy idiom.

## PO5: Compatibility with non-MTI and non-primary parent links

The patch must preserve existing behavior for ordinary primary keys and avoid
the all-parent reset rejected by public discussion.

- Evidence: E5 and `PUBLIC_COMPATIBILITY_AUDIT.md`.
- V1 discharge: if `_meta.pk` is not a parent link, exactly one assignment is
  performed. Parent links not reachable from `_meta.pk.target_field` are
  untouched.

## PO6: Formal adequacy

The formal model must retain the distinction between the failing state and the
fixed state.

- Failing abstraction: child PK link is `None`, parent PK field remains `old`.
- Fixed abstraction: child PK link and parent PK field are both `None`.
- V1 discharge: the K model represents both field ids and attribute values, so
  it can distinguish those states.
