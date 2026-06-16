# Baseline Notes

## Root cause

`UserChangeForm` always formatted the read-only password help link as
`../password/`. That works only when the admin change page URL is addressed by
the user's primary key, for example `/auth/user/1/change/`. When the same change
page is reached through a related admin using a non-primary `to_field`, the URL
can be `/auth/user/<uuid>/change/?_to_field=uuid`. The relative
`../password/` link then targets `/auth/user/<uuid>/password/`, but
`UserAdmin.user_change_password()` resolves its `<id>` path segment as a
primary key, producing a 404.

## Files changed

`repo/django/contrib/auth/forms.py`

Changed `UserChangeForm.__init__()` so the password help text points to the
password-change URL for the instance primary key when the form is bound to a
saved user. The generated relative URL now walks back from the current change
URL to the model admin root and then enters `<pk>/password/`. Unsaved instances
keep the previous `../password/` fallback. The primary key is passed through the
admin `quote()` helper so string primary keys with characters that are special
in admin object URLs remain valid path segments.

## Assumptions and alternatives

I assumed `UserAdmin.user_change_password()` intentionally continues to accept
only primary-key object IDs, matching its current `get_object(request,
unquote(id))` call and the named password-change URL that is registered as
`<id>/password/`.

I considered changing `UserAdmin.user_change_password()` to honor `_to_field`,
but rejected it because the password-change URL is not reached only from the
change form and changing that view's lookup semantics would broaden the
behavior beyond the reported broken link.

I considered using `reverse()` to build the password-change URL, but
`UserChangeForm` does not know the active admin site name or request context.
A relative URL keeps the fix local to the form and consistent with the existing
implementation.

I considered using the raw `self.instance.pk` directly, but rejected it because
admin object URLs already use `django.contrib.admin.utils.quote()` for primary
keys; using the same helper avoids regressing unusual but valid primary-key
values.
