# Proof Obligations

Status: constructed, not machine-checked. These obligations are traced to `fvk/SPEC.md` and `fvk/FINDINGS.md`.

## PO-1 - Utility signature admits omission

Intent: `INT-1`

Code: `repo/django/utils/html.py`

Obligation: `json_script` must be callable without an `element_id` argument.

Discharge: V1 changes the signature from `def json_script(value, element_id):` to `def json_script(value, element_id=None):`.

Finding coverage: resolves `F-01`.

## PO-2 - Utility omitted argument omits the id attribute

Intent: `INT-2`

Code: `repo/django/utils/html.py`

Obligation: When `element_id` is omitted or `None`, the rendered string has the exact wrapper shape:

```html
<script type="application/json">JSONESC(value)</script>
```

Discharge: V1 adds the `if element_id is None:` branch and returns `format_html('<script type="application/json">{}</script>', mark_safe(json_str))`.

Finding coverage: resolves `F-01`.

## PO-3 - Utility preserves ID-present output

Intent: `INT-4`, `INT-6`

Code: `repo/django/utils/html.py`

Obligation: When a non-`None` `element_id` is supplied, the rendered string has the existing wrapper shape:

```html
<script id="HTMLESC(element_id)" type="application/json">JSONESC(value)</script>
```

Discharge: V1 leaves the existing `format_html()` call on the non-`None` branch. `format_html()` continues escaping `element_id`.

Finding coverage: satisfies `F-02`; avoids broadening behavior for `F-03`.

## PO-4 - Utility preserves JSON escaping

Intent: `INT-3`, `INT-5`

Code: `repo/django/utils/html.py`

Obligation: Both output branches must use the same `json.dumps(..., cls=DjangoJSONEncoder).translate(_json_script_escapes)` result, with `<`, `>`, and `&` translated.

Discharge: V1 computes `json_str` once before the branch and both branches insert `mark_safe(json_str)`.

Finding coverage: supports `F-01` and `F-02`.

## PO-5 - Template filter signature admits zero explicit filter arguments

Intent: `INT-1`

Code: `repo/django/template/defaultfilters.py`, `repo/django/template/base.py`

Obligation: `{{ value|json_script }}` must pass template filter argument validation.

Discharge: V1 changes the wrapper signature to `def json_script(value, element_id=None):`. `FilterExpression.args_check()` calculates required arguments as `alen - dlen`; with two positional parameters and one default, the implicit input value alone satisfies the minimum.

Finding coverage: resolves `F-01`.

## PO-6 - Template filter delegates without altering semantics

Intent: `INT-2`, `INT-4`, `INT-5`

Code: `repo/django/template/defaultfilters.py`

Obligation: The template filter must render the same no-ID and ID-present forms as the utility.

Discharge: V1 keeps `return _json_script(value, element_id)`, so the wrapper has no independent string construction.

Finding coverage: resolves `F-01` and satisfies `F-02`.

## PO-7 - Source compatibility for existing public callers

Intent: `INT-4`

Code search evidence: production source references to `json_script` are limited to the utility definition and template filter wrapper; public tests use the ID-present path.

Obligation: Existing two-argument Python calls and one-argument template-filter calls must keep working.

Discharge: Adding a default does not change positional binding for existing callers, and the non-`None` branch preserves the old output.

Finding coverage: satisfies `F-02`.

## PO-8 - Empty-string ID remains outside the proven intent

Intent: none; ambiguity recorded in `F-03`.

Obligation: Do not use the explicit empty-string case to justify either success or failure of the required optional-argument behavior.

Discharge: V1 preserves existing provided-argument semantics for `""`; the proof and spec do not claim that this is the only valid design.

Finding coverage: records `F-03` without requiring a code change.
