# PUBLIC EVIDENCE LEDGER

Status: constructed, not machine-checked.

E1. `benchmark/PROBLEM.md` reports that readonly `ForeignKey` links in a custom
admin site render `/admin/...` instead of `/custom-admin/...`.
Obligation: custom admin readonly relation links must resolve against the active
custom admin site. Encoded by PO-1.

E2. `benchmark/PROBLEM.md` proposes passing
`current_app=self.model_admin.admin_site.name`.
Obligation: the owning `ModelAdmin` supplies the admin-site namespace. Encoded by
PO-1 and PO-4.

E3. `repo/django/contrib/admin/sites.py` stores `AdminSite.name` and exposes
admin URLs as `(urlpatterns, 'admin', self.name)`.
Obligation: `admin:` is the app namespace; `self.name` is the instance namespace.
Encoded by PO-1 and PO-2.

E4. `repo/django/urls/base.py` uses `current_app` to select a namespace instance
when reversing a namespaced URL.
Obligation: admin URL reversal must pass the active admin-site instance name.
Encoded by PO-1.

E5. `repo/django/contrib/admin/helpers.py` already catches `NoReverseMatch` in
`get_admin_url()` and returns `str(remote_obj)`.
Obligation: preserve the unresolved-route fallback. Encoded by PO-3.

E6. Neighboring admin modules pass `current_app` when reversing URLs owned by an
`AdminSite`.
Obligation: V1 follows the local admin URL convention. Supports PO-1, PO-2, and
PO-4.
