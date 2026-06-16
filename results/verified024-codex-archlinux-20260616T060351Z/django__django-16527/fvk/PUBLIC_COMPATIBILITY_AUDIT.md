# Public Compatibility Audit

Status: pass.

## Changed Symbol

`django.contrib.admin.templatetags.admin_modify.submit_row(context)`

## Compatibility Checks

* Signature: unchanged.
* Return shape: unchanged `Context` with the same keys as before.
* New required context keys: none. `has_add_permission` was already read by the
  function for `show_save_and_add_another`.
* Template variable names: unchanged. `submit_line.html` still reads
  `show_save_as_new`.
* Public template behavior: only the visibility of the existing `_saveasnew`
  submit input changes for users lacking add permission.
* Subclass/override compatibility: no virtual method signature or dispatch shape
  changed.

No compatibility finding blocks keeping V1.
