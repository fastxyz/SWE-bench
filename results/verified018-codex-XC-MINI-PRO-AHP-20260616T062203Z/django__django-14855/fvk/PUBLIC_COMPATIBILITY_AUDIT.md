# PUBLIC COMPATIBILITY AUDIT

Status: constructed, not machine-checked.

Changed symbol: `AdminReadonlyField.get_admin_url(remote_field, remote_obj)`.

Compatibility result: pass.

- The method signature is unchanged.
- The method still returns formatted anchor HTML on successful reversal and
  `str(remote_obj)` on `NoReverseMatch`.
- The only changed call is to `django.urls.reverse()`, which already accepts
  `current_app`.
- `ModelAdmin.changeform_view()` constructs `AdminForm(..., model_admin=self)`,
  and the helper chain propagates that `model_admin` into `AdminReadonlyField`.
- `AdminReadonlyField.__init__()` already dereferences `model_admin`, so V1 adds
  no new normal-path requirement.

Unhandled public callsites or overrides: none found in the allowed source.
