# Public Compatibility Audit

Status: source-inspection only. No tests or project code were run.

## Changed public behavior

`BaseFormSet.full_clean()` now calls the configured `error_class` with
`error_class='nonform'` when constructing `_non_form_errors`.

This changes the rendered class string of `formset.non_form_errors()` from
`errorlist` to `errorlist nonform`.

## Public call sites and consumers

`BaseFormSet.non_form_errors()`

- Shape consumed: returns an `ErrorList` instance or custom `error_class`
  instance.
- Status: compatible. The return type is unchanged.

Admin templates:

- `repo/django/contrib/admin/templates/admin/change_list.html`
- `repo/django/contrib/admin/templates/admin/edit_inline/stacked.html`
- `repo/django/contrib/admin/templates/admin/edit_inline/tabular.html`
- Shape consumed: template renders `{{ ...non_form_errors }}`.
- Status: compatible. Rendering now includes the requested extra class.

Admin helpers:

- `repo/django/contrib/admin/helpers.py` exposes
  `inline_formset.non_form_errors()` and extends `AdminErrorList` with its
  contents.
- Shape consumed: iteration/list extension over the errors.
- Status: compatible. Error contents are unchanged.

Testing helpers:

- `repo/django/test/testcases.py` inspects `formset.non_form_errors()` for
  membership of expected messages.
- Shape consumed: list membership and truthiness.
- Status: compatible. Error contents and truthiness are unchanged.

Custom `ErrorList` classes:

- Shape consumed: Django's documented extension point is an `ErrorList`
  compatible class. Existing form non-field errors already call this class with
  `error_class='nonfield'`.
- Status: acceptable compatibility change. The issue explicitly asks for custom
  `ErrorList` classes to distinguish formset non-form errors, which requires
  passing the class signal at construction time.

## Suspect legacy public tests

`repo/tests/admin_views/tests.py::test_non_form_errors_is_errorlist` compares
the old rendering to `ErrorList(["Grace is not a Zombie"])`, which has no
extra class. This conflicts with the issue's public intent and is recorded as
FINDINGS.md F2. It must not block the fix.

## Compatibility conclusion

No public call site or subclass/override requires a source change beyond V1.
The only observed conflict is a legacy rendering expectation that encodes the
reported missing class.
