# Intent Specification

The public issue requires admin list-editable primary-key POST key selection to
work when the formset prefix contains regex metacharacters. The prefix is a
literal component of a generated form field name, not a regex fragment.

Required behavior:

1. A prefix may contain regex metacharacters.
2. `_get_edited_object_pks()` must select primary-key values for POST keys whose
   literal shape is `prefix-index-pk_name`.
3. It must not select keys merely because an unescaped prefix happens to match
   them as regex syntax.
4. The existing selected value order, return shape, and caller protocol should
   be preserved.

