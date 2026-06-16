# INTENT SPEC

Status: constructed, not machine-checked.

I1. A readonly `ForeignKey` rendered in a custom `AdminSite` must generate a
link under that custom admin site's URL path, not under the default `/admin/`
path.

I2. The active admin-site namespace is the owning `ModelAdmin.admin_site.name`.

I3. Default admin behavior must remain unchanged when
`ModelAdmin.admin_site.name == "admin"`.

I4. If the owning admin site cannot reverse the related model change URL, the
helper must keep rendering `str(remote_obj)`.

I5. The fix must not alter public helper signatures, relation dispatch, or
unrelated readonly rendering branches.
