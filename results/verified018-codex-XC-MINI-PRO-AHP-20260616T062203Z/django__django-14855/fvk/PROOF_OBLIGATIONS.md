# PROOF OBLIGATIONS

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## PO-1: Active custom admin site controls readonly relation URL reversal

Source findings: F1.

Public intent:

- A readonly `ForeignKey` rendered in a custom `AdminSite` must link under the
  custom admin path, not `/admin/...`.

Preconditions:

- `AdminReadonlyField` is rendering a non-null related object.
- The owning `ModelAdmin.admin_site.name` is `ACTIVE`.
- The related model has a change URL in the `ACTIVE` admin-site namespace.
- The URL name is the admin app name plus the related model change view:
  `admin:<app_label>_<model_name>_change`.

Postcondition:

- `reverse()` is invoked with `current_app=ACTIVE`.
- The rendered anchor `href` is the URL belonging to the `ACTIVE` admin-site
  namespace.

Mapped formal claim:

- First claim in `fvk/readonly-admin-url-spec.k`.

## PO-2: Default admin behavior is preserved

Source findings: F2.

Public intent:

- The issue reports custom-site misrouting only; default admin URLs should keep
  resolving to the default admin instance.

Preconditions:

- `ModelAdmin.admin_site.name == "admin"`.
- The related model has a default admin change URL.
- The readonly relation value is non-null.

Postcondition:

- `reverse('admin:...', current_app='admin', args=[...])` renders the same
  default admin URL that `reverse('admin:...', args=[...])` previously selected
  by default.

Mapped formal claim:

- Second claim in `fvk/readonly-admin-url-spec.k`.

## PO-3: `NoReverseMatch` fallback remains local to the owning site

Source findings: F3.

Public intent:

- The problem asks for custom admin URLs when the related route exists; it does
  not ask readonly rendering to link to unrelated admin sites.

Preconditions:

- The owning admin site lacks the related model change URL.
- `reverse()` raises `NoReverseMatch` for
  `current_app=self.model_admin.admin_site.name`.

Postcondition:

- `AdminReadonlyField.get_admin_url()` returns `str(remote_obj)`.
- The helper does not fall through to a default-admin link.

Mapped formal claim:

- Third claim in `fvk/readonly-admin-url-spec.k`.

## PO-4: Public API, callsite, and virtual dispatch compatibility

Source findings: F4.

Public intent:

- The fix should address admin URL namespace selection without changing the
  public shape of readonly-field rendering.

Preconditions:

- `AdminForm` is constructed by `ModelAdmin` with `model_admin=self`.
- `AdminForm`, `Fieldset`, and `Fieldline` propagate the same `model_admin` to
  `AdminReadonlyField`.
- `django.urls.reverse()` accepts the `current_app` keyword.

Postcondition:

- `AdminReadonlyField.get_admin_url(remote_field, remote_obj)` keeps its
  signature and return shape.
- No caller or subclass override needs to accept a new argument.
- Existing `format_html('<a href="{}">{}</a>', url, remote_obj)` rendering is
  unchanged except for the selected URL.

Mapped evidence:

- Source-level compatibility audit in `fvk/SPEC.md` and F4.

## PO-5: Relation dispatch and non-link rendering are unchanged

Source findings: F3, F4.

Public intent:

- Only readonly related-object links are wrong; unrelated readonly rendering must
  not be refactored.

Preconditions:

- `AdminReadonlyField.contents()` receives any of the existing readonly field
  value classes: many-to-many, non-null relation, null relation, regular field,
  callable/attribute, boolean display, or read-only widget.

Postcondition:

- The V1 source edit affects only the non-null relation path that already called
  `get_admin_url()`.
- Many-to-many rendering, empty values, regular field display, boolean icons,
  read-only widget rendering, `linebreaksbr()`, and final escaping remain as in
  V0.

Mapped evidence:

- Source-level frame audit in `fvk/SPEC.md` and F4.

## PO-6: Proof-status honesty

Source findings: F5.

Public intent:

- The task forbids running tests or K tooling and requires reasoning about
  expected outcomes instead.

Preconditions:

- FVK artifacts and K-style claims are written.
- `kompile`, `kast`, `kprove`, Python, and test commands are not executed.

Postcondition:

- The proof is labeled constructed, not machine-checked.
- No tests are removed or claimed redundant without the machine check.

Mapped evidence:

- `fvk/PROOF.md` command section and F5.
