# FVK Specification

Status: constructed, not machine-checked. No Python, tests, `kompile`, or `kprove` were run.

## Scope

The audited units are:

- `repo/django/utils/html.py`: `json_script(value, element_id=None)`
- `repo/django/template/defaultfilters.py`: `json_script(value, element_id=None)`

The audited observable is the rendered `<script type="application/json">...</script>` string and whether the `id` attribute is present.

## Intent-Only Specification

`INT-1` Source: `benchmark/PROBLEM.md`

Quoted evidence: "Make the element_id argument of json_script optional"

Obligation: Calling the Python helper without `element_id`, and using the template filter without a filter argument, must be in-domain behavior.

`INT-2` Source: `benchmark/PROBLEM.md`

Quoted evidence: "I didn't need any id for it"

Obligation: The no-argument form must render a script tag without an `id` attribute.

`INT-3` Source: `repo/docs/ref/templates/builtins.txt`

Quoted evidence: "Safely outputs a Python object as JSON, wrapped in a `<script>` tag"

Obligation: The output remains a `<script type="application/json">` tag containing JSON.

`INT-4` Source: `repo/docs/ref/templates/builtins.txt` and public tests under `repo/tests`

Quoted evidence: docs and tests show `<script id="hello-data" type="application/json">...` or `<script id="test_id" type="application/json">...` when an ID is provided.

Obligation: Supplying a concrete ID must preserve the existing ID-bearing output shape.

`INT-5` Source: `repo/docs/ref/templates/builtins.txt` and public tests under `repo/tests`

Quoted evidence: "XSS attacks are mitigated by escaping the characters `<`, `>` and `&`."

Obligation: JSON content must still translate `<`, `>`, and `&` to Unicode escapes before insertion in the script body.

`INT-6` Source: implementation and API convention

Quoted evidence: `format_html()` applies `conditional_escape()` to its arguments.

Obligation: A provided ID must continue to be attribute-escaped rather than interpolated raw.

## Domain

This is a partial-correctness spec. It covers inputs for which Django's existing JSON serialization path terminates:

- `value` is any value accepted by `json.dumps(value, cls=DjangoJSONEncoder)`.
- `element_id` is omitted, `None`, or a provided value accepted by `format_html()` through `conditional_escape()`.

The spec does not add validation for whether a provided ID is a conforming HTML identifier. The existing public contract did not validate that before V1.

## Postconditions

Let `JSONESC(value)` mean `json.dumps(value, cls=DjangoJSONEncoder).translate(_json_script_escapes)`, where `_json_script_escapes` maps `<`, `>`, and `&` to Unicode escapes.

Let `HTMLESC(element_id)` mean the attribute escaping performed by `format_html()`.

`POST-1`: `django.utils.html.json_script(value)` returns:

```html
<script type="application/json">JSONESC(value)</script>
```

`POST-2`: `django.utils.html.json_script(value, None)` returns the same no-ID form as `POST-1`.

`POST-3`: `django.utils.html.json_script(value, element_id)` for non-`None` `element_id` returns:

```html
<script id="HTMLESC(element_id)" type="application/json">JSONESC(value)</script>
```

`POST-4`: `django.template.defaultfilters.json_script(value)` delegates to the utility with no `element_id`, so it has `POST-1`.

`POST-5`: `django.template.defaultfilters.json_script(value, element_id)` delegates to the utility with the supplied `element_id`, so it has `POST-2` or `POST-3` depending on whether the supplied value is `None`.

## Formal Core

The mini semantics is in `fvk/mini-python-json-script.k`.

The K claims are in `fvk/json-script-spec.k`.

The fragment abstracts full Python JSON serialization and HTML escaping as `JSONESC` and `HTMLESC`. This abstraction is property-complete for the audited defect because it preserves the output-shape axis that distinguishes passing from failing behavior:

- Failing legacy no-ID case: no call path or parser-accepted no-argument filter form exists.
- Passing V1 no-ID case: the observable has no `id="..."` attribute.
- Passing compatibility case: the observable has the existing escaped `id="..."` attribute.

## Compatibility Audit

`COMPAT-1`: The Python utility signature only adds a default value for `element_id`; existing two-argument calls still bind the same parameters.

`COMPAT-2`: The template filter signature only adds a default value. Django's `FilterExpression.args_check()` counts defaulted parameters, so the filter now accepts either zero or one explicit filter argument.

`COMPAT-3`: Source search found no production callers of `json_script` outside the utility and template filter wrapper.

`COMPAT-4`: Existing public tests exercise the ID-present path only; V1 preserves that path.

`COMPAT-5`: Existing docs show the ID-present path and should be updated in a normal documentation pass, but this is not a runtime source-code defect.

## Adequacy Audit

The formal English postconditions above match the intent entries:

- `POST-1`, `POST-4` satisfy `INT-1` and `INT-2`.
- `POST-2` applies the Python default-domain convention that `None` is the absent optional value.
- `POST-3`, `POST-5` satisfy `INT-4` and `INT-6`.
- All postconditions retain `JSONESC(value)`, satisfying `INT-3` and `INT-5`.

The explicit empty-string ID case is under-specified by public intent. V1 leaves it on the provided-ID path because the issue only requires omitted IDs to be optional, and preserving existing provided-argument behavior is the narrower compatibility choice.
