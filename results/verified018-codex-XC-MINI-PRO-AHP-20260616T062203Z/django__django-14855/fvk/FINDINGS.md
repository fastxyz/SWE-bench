# FINDINGS

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## F1: Pre-fix readonly relation links used the default admin namespace

Classification: code bug in V0, fixed by V1.

Concrete input:

- Root URLconf includes a default admin site at `/admin/` with namespace
  `"admin"` and a custom admin site at `/custom-admin/` with namespace
  `"custom-admin"`.
- A model is displayed in the custom admin site.
- A non-null `ForeignKey` field is listed in `readonly_fields`.
- The related model has a change route in the custom admin site.

Observed before V1:

- `AdminReadonlyField.get_admin_url()` called `reverse(url_name, args=[...])`
  without `current_app`.
- `reverse()` selected the default `admin` instance for `admin:app_model_change`.
- The rendered link pointed to `/admin/...`.

Expected:

- The rendered link points to the related object's change page under
  `/custom-admin/...`.

Resolution:

- V1 passes `current_app=self.model_admin.admin_site.name`, so URL reversal is
  scoped to the owning `AdminSite` instance.
- Discharged by PO-1.

## F2: Default admin behavior must remain unchanged

Classification: frame condition, confirmed.

Concrete input:

- The owning `AdminSite.name` is `"admin"`.
- The related model's default admin change route exists.
- The readonly relation value is non-null.

Observed in V1:

- `reverse('admin:app_model_change', current_app='admin', args=[...])` resolves
  the default admin instance.

Expected:

- The generated default-admin link is unchanged except for the explicit namespace
  argument that selects the same site.

Resolution:

- No source edit beyond the `current_app` keyword is required.
- Discharged by PO-2.

## F3: Unresolved related admin URLs must keep the string fallback

Classification: frame condition, confirmed.

Concrete input:

- The owning custom admin site has no change URL for the related model.
- The readonly relation value is non-null.

Observed in V1:

- `reverse(..., current_app=owning_site_name)` raises `NoReverseMatch`.
- The existing `except NoReverseMatch` branch returns `str(remote_obj)`.

Expected:

- The helper renders plain object text, not a link to another admin site.

Resolution:

- V1 keeps the existing `NoReverseMatch` handling unchanged.
- Discharged by PO-3.

## F4: Public API and call graph compatibility are preserved

Classification: compatibility finding, confirmed.

Concrete input:

- Admin change-form rendering constructs `helpers.AdminForm(..., model_admin=self)`.
- `AdminForm` passes `model_admin` through `Fieldset` and `Fieldline`.
- `Fieldline.__iter__()` constructs `AdminReadonlyField(..., model_admin=self.model_admin)`.

Observed in V1:

- `AdminReadonlyField.get_admin_url()` retains the same method signature.
- The only changed call is to `django.urls.reverse()`, which already accepts the
  `current_app` keyword.
- `AdminReadonlyField.__init__()` already dereferences `model_admin` for
  `get_empty_value_display()`, so the V1 dereference in `get_admin_url()` does
  not introduce a new normal-path requirement.

Expected:

- Existing admin callers and readonly-field rendering continue to work without a
  signature, return-type, or dispatch-shape change.

Resolution:

- No compatibility code edit is required.
- Discharged by PO-4.

## F5: Verification remains constructed, not machine-checked

Classification: proof honesty caveat, not a source-code bug.

Concrete input:

- The K-style files `fvk/mini-django-admin-url.k` and
  `fvk/readonly-admin-url-spec.k` are present.

Observed:

- The proof was constructed from source inspection and the FVK method.
- The task forbids running `kompile`, `kast`, `kprove`, Python, or tests.

Expected:

- The artifacts must include the commands a maintainer could run later, but must
  not claim machine-checked proof status now.

Resolution:

- `fvk/PROOF.md` lists the exact commands and labels the result as constructed,
  not machine-checked.
- No test-removal recommendation is made.
