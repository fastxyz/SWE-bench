# Baseline Notes

## Root cause

`AdminReadonlyField.get_admin_url()` builds the change URL for a related object
shown through a readonly relation field. It used `reverse(url_name, ...)` without
passing the current admin application namespace. Because the URL name is in the
`admin:` namespace, Django resolved it against the default admin site instead of
the `AdminSite` instance that owns the current `ModelAdmin`. In a custom admin
site, that produced `/admin/...` links for readonly `ForeignKey` or one-to-one
values instead of links under the custom admin path.

## Changed files

`repo/django/contrib/admin/helpers.py`

Updated `AdminReadonlyField.get_admin_url()` to pass
`current_app=self.model_admin.admin_site.name` to `reverse()`. This matches the
pattern used elsewhere in `django.contrib.admin` when reversing admin URLs from a
specific `AdminSite`, and keeps the existing `NoReverseMatch` fallback unchanged.

## Assumptions and alternatives considered

I assumed `AdminReadonlyField` has a usable `model_admin` when rendering admin
forms, since the class already dereferences `model_admin` during initialization
for `get_empty_value_display()`. I therefore did not add a defensive fallback for
a missing `model_admin`.

I considered changing the URL namespace or deriving the admin site from request
state, but this helper already receives the owning `ModelAdmin`, and other admin
code uses `self.admin_site.name`/`self.model_admin.admin_site.name` as the
current app when reversing admin URLs. Passing `current_app` is the smallest
targeted change and addresses custom admin sites without changing behavior for
the default admin.

Tests were not run because the task instructions prohibit running tests or code
in this workspace.
