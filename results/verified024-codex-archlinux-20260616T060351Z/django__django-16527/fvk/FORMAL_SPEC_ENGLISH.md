# Formal Spec in English

Status: paraphrase of `submit-row-spec.k`.

## Claim `NO_ADD`

For any popup state, change permission, change-form state, and `save_as` value,
if `has_add_permission` is false, then `show_save_as_new` is false.

## Claim `NO_CHANGE`

For any popup state, add permission, change-form state, and `save_as` value, if
`has_change_permission` is false, then `show_save_as_new` is false.

## Claim `NO_CHANGE_FORM`

For any popup state, add permission, change permission, and `save_as` value, if
`change` is false, then `show_save_as_new` is false.

## Claim `POPUP`

For any add permission, change permission, change-form state, and `save_as`
value, if `is_popup` is true, then `show_save_as_new` is false.

## Claim `SAVE_AS_DISABLED`

For any popup state, add permission, change permission, and change-form state,
if `save_as` is false, then `show_save_as_new` is false.

## Claim `POSITIVE`

If `is_popup` is false and add permission, change permission, change form, and
`save_as` are all true, then `show_save_as_new` is true.
