# SPEC: readonly admin related-object URLs

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Scope

This audit covers the V1 change to
`repo/django/contrib/admin/helpers.py`, specifically
`AdminReadonlyField.get_admin_url()` and the path from
`AdminReadonlyField.contents()` that uses it for non-null related objects.

The observable behavior under specification is the rendered readonly relation
value:

- a successful admin URL reversal returns an HTML anchor whose `href` targets
  the related object's change page in the owning `AdminSite`;
- an unresolved reversal returns the plain string representation of the related
  object, preserving the existing fallback.

## Intent spec

I1. In a custom `AdminSite`, a readonly `ForeignKey` relation must link to the
custom admin path, not the default `/admin/` path.

I2. The same helper must keep default admin behavior unchanged when the owning
admin site is the default site.

I3. If the related admin change URL cannot be reversed for the owning site, the
helper must keep the existing `NoReverseMatch` fallback and render `str(remote_obj)`.

I4. The fix must not change public helper signatures, relation dispatch, HTML
rendering shape, or non-readonly admin URL behavior.

## Public evidence ledger

E1. Source: `benchmark/PROBLEM.md`.
Quoted evidence: "When a model containing a ForeignKey field is viewed (or
edited) in a custom Admin Site, and that ForeignKey field is listed in
readonly_fields, the url generated for the link is /admin/... instead of
/custom-admin/...."
Semantic obligation: For readonly foreign-key relation values, URL reversal must
select the current custom `AdminSite` instance namespace.
Status: encoded by PO-1 and the first claim in `fvk/readonly-admin-url-spec.k`.

E2. Source: `benchmark/PROBLEM.md`.
Quoted evidence: the proposed repair adds
`current_app=self.model_admin.admin_site.name` to `reverse()`.
Semantic obligation: The owning `ModelAdmin`'s `admin_site.name` is the intended
source of the active admin namespace.
Status: encoded by PO-1 and PO-4.

E3. Source: `repo/django/contrib/admin/sites.py`.
Implementation evidence: `AdminSite.__init__()` stores `self.name`, and
`AdminSite.urls` returns `(self.get_urls(), 'admin', self.name)`.
Semantic obligation: Admin URL names use the app namespace `admin`; the selected
instance namespace is the `AdminSite.name`.
Status: encoded by PO-1 and PO-2.

E4. Source: `repo/django/urls/base.py`.
Implementation evidence: `reverse()` uses `current_app` to choose a matching
namespace instance from `resolver.app_dict`.
Semantic obligation: A call to `reverse('admin:...', current_app=site_name)`
resolves against the requested admin-site instance when that instance is present.
Status: encoded by PO-1.

E5. Source: `repo/django/contrib/admin/helpers.py`.
Implementation evidence: `AdminReadonlyField.contents()` calls
`get_admin_url()` for non-null relation fields whose `remote_field` is a
`ForeignObjectRel` or `OneToOneField`; `get_admin_url()` catches
`NoReverseMatch` and returns `str(remote_obj)`.
Semantic obligation: The fix applies only to the relation-link path and preserves
the unresolved-url fallback.
Status: encoded by PO-3 and PO-5.

E6. Source: neighboring admin code in `options.py`, `views/main.py`,
`widgets.py`, and `sites.py`.
Implementation evidence: admin reverse calls that belong to a particular
`AdminSite` pass `current_app=self.admin_site.name`,
`current_app=self.model_admin.admin_site.name`, or `current_app=self.name`.
Semantic obligation: V1 follows an existing admin namespace pattern rather than
introducing a new URL convention.
Status: supports PO-1, PO-2, and PO-4.

## Formal model

The FVK formal core is emitted as:

- `fvk/mini-django-admin-url.k`: a minimal K-style semantics for the observable
  behavior of this helper, URL reversal with an explicit current admin site, and
  the `NoReverseMatch` fallback.
- `fvk/readonly-admin-url-spec.k`: reachability claims for the custom-site,
  default-site, fallback, and legacy counterexample cases.

The model abstracts away unrelated Django behavior, but it retains the property
axis that distinguishes pass from fail: the rendered anchor URL uses either the
active admin-site route prefix or a different/default route prefix.

## Formal spec in English

FS1. For every active admin site name, app label, model name, object primary key,
object representation, and route map, if the active site has a registered admin
change route for that model, `getAdminUrl()` renders an anchor whose URL is built
from that active site's route prefix.

FS2. When the active site is `"admin"` and the default admin route exists,
`getAdminUrl()` renders the same default-admin anchor as before.

FS3. If the active site has no matching admin change route for the related
model, `getAdminUrl()` renders plain object text rather than linking to another
admin-site instance.

FS4. The legacy model, which ignores the active site and reverses against the
default site, produces the wrong default-site anchor when both default and custom
routes exist and differ. This is the symbolic counterexample for the reported
bug.

## Adequacy audit

FS1 passes: it is exactly the custom-admin obligation from E1 and E2.

FS2 passes: it is a frame condition over the default admin behavior, supported by
the issue's narrow custom-site complaint and by existing admin reverse patterns.

FS3 passes: it preserves the existing `NoReverseMatch` branch in the helper and
prevents a custom-site page from silently linking to a different admin instance.

FS4 passes as a negative/diagnostic claim: it models the reported pre-fix cause,
not a required final behavior.

No formal claim depends only on V1's current output. The expected active-site URL
is derived from the issue statement plus Django's namespace-resolution code.
