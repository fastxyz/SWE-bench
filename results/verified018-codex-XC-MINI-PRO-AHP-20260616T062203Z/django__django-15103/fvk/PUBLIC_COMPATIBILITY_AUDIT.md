# Public Compatibility Audit

Status: source-inspection only; no code was executed.

## Changed Symbol: django.utils.html.json_script

Change: `element_id` now has a default value of `None`.

Public compatibility:

- Existing calls with `(value, element_id)` keep the same positional binding.
- Existing ID-present output remains on the non-`None` branch.
- Calls without `element_id` are newly accepted.

Verdict: compatible.

## Changed Symbol: django.template.defaultfilters.json_script

Change: `element_id` now has a default value of `None`.

Public compatibility:

- Existing templates using `{{ value|json_script:"test_id" }}` still pass one explicit filter argument.
- New templates using `{{ value|json_script }}` now pass argument validation.
- The wrapper still delegates to `django.utils.html.json_script`.

Verdict: compatible.

## Public Callsite Search

Production source references found:

- `repo/django/template/defaultfilters.py` imports the utility as `_json_script`.
- `repo/django/template/defaultfilters.py` defines the template filter wrapper.
- `repo/django/utils/html.py` defines the utility helper.

No public production callsite requires a signature update.

Verdict: compatible.

## Public Tests and Docs

Public tests currently cover only the ID-present behavior. V1 preserves that behavior.

Docs currently show only the ID-present behavior. This is a documentation follow-up, not a runtime compatibility break.
