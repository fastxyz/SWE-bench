# PROOF

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Summary

V1 proves the intended local contract for `AdminReadonlyField.get_admin_url()`:
when a readonly related object is rendered from a custom admin site, URL reversal
uses the owning `AdminSite.name` as `current_app`; when the owning site is the
default admin, default behavior is preserved; when the owning site has no
related change route, the existing `NoReverseMatch` fallback is preserved.

No source change beyond V1 is justified by the FVK findings or proof obligations.

## Formal files

- Semantics: `fvk/mini-django-admin-url.k`
- Claims: `fvk/readonly-admin-url-spec.k`

The model is intentionally small. It abstracts Django objects into strings,
route keys, and route maps, but it preserves the property under verification:
whether the rendered result is an anchor using the active admin-site route prefix
or a different/default route prefix.

## PO-1 proof: custom admin site controls the link

Initial symbolic state:

- `<k> getAdminUrl(ACTIVE, APP, MODEL, PK, OBJ, ROUTES) </k>`
- `routeKey(ACTIVE, APP, MODEL)` exists in `ROUTES`.
- `ROUTES[routeKey(ACTIVE, APP, MODEL)] == PREFIX`.

Symbolic execution:

1. Apply the V1 helper rule:
   `getAdminUrl(...)` rewrites to
   `reverseWithCurrentApp(ACTIVE, APP, MODEL, PK, ROUTES) ~> renderRemoteObject(OBJ)`.
2. Apply the successful reverse rule under the route-exists side condition:
   `reverseWithCurrentApp(...)` rewrites to
   `url(PREFIX + PK + "/change/")`.
3. Apply the render rule:
   `url(URL) ~> renderRemoteObject(OBJ)` rewrites to `anchor(URL, OBJ)`.
4. By transitivity, the initial state reaches
   `anchor(PREFIX + PK + "/change/", OBJ)`.

Conclusion:

- The rendered anchor uses the active admin site's route prefix for all route
  maps satisfying the precondition.
- This discharges PO-1 and resolves F1 for V1.

## PO-2 proof: default admin behavior is preserved

Instantiate PO-1 with `ACTIVE == "admin"`.

The same three symbolic steps produce
`anchor(DEFAULT_PREFIX + PK + "/change/", OBJ)` when
`ROUTES[routeKey("admin", APP, MODEL)] == DEFAULT_PREFIX`.

Conclusion:

- Passing `current_app="admin"` selects the same default admin route that was
  selected implicitly before V1.
- This discharges PO-2 and F2.

## PO-3 proof: unresolved routes keep the fallback

Initial symbolic state:

- `<k> getAdminUrl(ACTIVE, APP, MODEL, PK, OBJ, ROUTES) </k>`
- `routeKey(ACTIVE, APP, MODEL)` is not present in `ROUTES`.

Symbolic execution:

1. Apply the V1 helper rule:
   `getAdminUrl(...)` rewrites to
   `reverseWithCurrentApp(ACTIVE, APP, MODEL, PK, ROUTES) ~> renderRemoteObject(OBJ)`.
2. Apply the failed reverse rule under the route-missing side condition:
   `reverseWithCurrentApp(...)` rewrites to `noReverseMatch`.
3. Apply the fallback render rule:
   `noReverseMatch ~> renderRemoteObject(OBJ)` rewrites to `text(OBJ)`.

Conclusion:

- The helper returns the object representation when the owning admin site cannot
  reverse the related change URL.
- Since the reverse is scoped to `ACTIVE`, this proof also excludes accidental
  fallback to a different admin site.
- This discharges PO-3 and F3.

## Legacy counterexample

Initial symbolic state:

- `DEFAULT != ACTIVE`.
- Both `routeKey(DEFAULT, APP, MODEL)` and `routeKey(ACTIVE, APP, MODEL)` exist.
- The default route prefix differs from the active route prefix.
- `<k> legacyGetAdminUrl(DEFAULT, ACTIVE, APP, MODEL, PK, OBJ, ROUTES) </k>`.

Symbolic execution:

1. The legacy helper ignores `ACTIVE` and calls
   `reverseWithCurrentApp(DEFAULT, APP, MODEL, PK, ROUTES)`.
2. Since the default route exists, it renders
   `anchor(DEFAULT_PREFIX + PK + "/change/", OBJ)`.

Conclusion:

- The old behavior produces a default-admin URL even when a distinct active
  custom-admin URL exists. This is the reported defect.
- V1 removes the counterexample by replacing `DEFAULT` with `ACTIVE` in the
  reverse call.

## PO-4 and PO-5 proof: compatibility and frame conditions

Source-level proof:

1. `ModelAdmin.changeform_view()` constructs `helpers.AdminForm(...,
   model_admin=self)`.
2. `AdminForm.__iter__()` passes `model_admin` to `Fieldset`.
3. `Fieldset.__iter__()` passes `model_admin` to `Fieldline`.
4. `Fieldline.__iter__()` passes `model_admin` to `AdminReadonlyField` for
   readonly fields.
5. `AdminReadonlyField.__init__()` already dereferences `model_admin` through
   `model_admin.get_empty_value_display()`, so using
   `self.model_admin.admin_site.name` in `get_admin_url()` adds no new
   normal-path object requirement.
6. V1 does not change `get_admin_url(remote_field, remote_obj)`, `contents()`,
   any public `ModelAdmin` method, or the returned HTML/text shape.
7. The source diff is limited to the `reverse()` call inside `get_admin_url()`.
   All other branches in `contents()` remain byte-for-byte unchanged.

Conclusion:

- Existing callers and readonly rendering paths remain compatible.
- PO-4 and PO-5 are discharged.

## Machine-check commands

These commands are intentionally not executed in this workspace:

```sh
kompile fvk/mini-django-admin-url.k --backend haskell
kast --backend haskell fvk/readonly-admin-url-spec.k
kprove fvk/readonly-admin-url-spec.k
```

Expected result after a successful machine check:

- `kprove` returns `#Top` for the claims in `fvk/readonly-admin-url-spec.k`.

Current proof status:

- Constructed, not machine-checked.

## Test recommendation

No tests were inspected, edited, classified as redundant, or removed. The task
forbids modifying test files and provides no test execution results. Any future
test-removal recommendation would require a successful `kprove` run and is out
of scope for this workspace.
