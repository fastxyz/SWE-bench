# ITERATION GUIDANCE

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## V2 decision

Keep V1 unchanged.

Reasoning:

- F1 is the only source-code bug identified by the FVK audit.
- PO-1 proves the V1 edit addresses F1 by passing the owning admin site's
  namespace to `reverse()`.
- PO-2 through PO-5 prove the relevant frame conditions: default-admin behavior,
  unresolved-route fallback, public API compatibility, and unrelated readonly
  rendering paths are preserved.
- F5 is a proof-status caveat only. It requires honest labeling and commands for
  later checking, not another source edit.

## Source changes

No additional source changes are recommended.

Rejected alternatives:

- Add a defensive `model_admin is None` branch: rejected because PO-4 shows the
  normal admin rendering path already requires `model_admin`, and
  `AdminReadonlyField.__init__()` already dereferences it before
  `get_admin_url()` can run.
- Pre-check the related model in `admin_site._registry`: rejected because PO-3
  preserves the existing `NoReverseMatch` fallback and correctly avoids linking
  to another admin site if the active site lacks the route.
- Use the concrete namespace string
  `"%s:%s_%s_change" % (admin_site.name, app_label, model_name)`: rejected
  because PO-1 is already satisfied by the established Django admin pattern
  `reverse('admin:...', current_app=admin_site.name)`, which matches neighboring
  admin code and the issue's proposed fix.

## Suggested tests for maintainers

These are recommendations only. Do not add them in this benchmark because test
files are fixed and hidden.

1. Custom admin readonly `ForeignKey` link:
   - Register the parent and related model in a custom `AdminSite`.
   - Put the `ForeignKey` in `readonly_fields`.
   - Assert the rendered link starts with the custom admin path.

2. Default admin preservation:
   - Render the same readonly relation in the default admin.
   - Assert the link still starts with `/admin/`.

3. Active-site fallback:
   - Render a readonly relation in an admin site where the related model change
     URL cannot be reversed.
   - Assert the readonly value is plain object text rather than a link to the
     default admin site.

## Future verification

A maintainer with K tooling can run:

```sh
kompile fvk/mini-django-admin-url.k --backend haskell
kast --backend haskell fvk/readonly-admin-url-spec.k
kprove fvk/readonly-admin-url-spec.k
```

Expected result:

- `kprove` returns `#Top`.

Until then, the proof remains constructed, not machine-checked, and no test
removal is recommended.
