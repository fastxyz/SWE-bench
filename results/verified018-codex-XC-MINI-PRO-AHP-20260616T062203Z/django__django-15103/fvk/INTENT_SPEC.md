# Intent Spec

Status: intent-only; current implementation behavior is used only as something to check later.

## Required Behaviors

`INT-1`: `element_id` is optional for `json_script`.

Evidence: `benchmark/PROBLEM.md` says "Make the element_id argument of json_script optional."

Implication: The Python helper must be callable without `element_id`, and the template filter must be usable as `{{ value|json_script }}`.

`INT-2`: The optional form does not need an `id` attribute.

Evidence: `benchmark/PROBLEM.md` says the reporter "didn't need any id for it."

Implication: The omitted-ID output should be a `<script type="application/json">` tag without `id="..."`.

`INT-3`: The output remains safe JSON in a script tag.

Evidence: `repo/docs/ref/templates/builtins.txt` says the filter "Safely outputs a Python object as JSON, wrapped in a `<script>` tag."

Implication: The fix must preserve the `<script type="application/json">JSON</script>` output shape.

`INT-4`: Provided IDs remain supported.

Evidence: docs and public tests show ID-present output when an ID argument is supplied.

Implication: Existing callers using an ID should receive the same ID-bearing output shape.

`INT-5`: JSON body escaping remains unchanged.

Evidence: docs say XSS is mitigated by escaping `<`, `>`, and `&`; public tests assert these escapes.

Implication: The fix must not alter `_json_script_escapes` or bypass `DjangoJSONEncoder`.

`INT-6`: Provided IDs remain escaped.

Evidence: the existing helper uses `format_html()`, whose public contract is HTML escaping of arguments.

Implication: The fix must not interpolate a provided ID raw.

## Explicitly Under-Specified

`AMB-1`: Public intent does not specify whether an explicitly supplied empty string should render `id=""` or omit the ID attribute. The positive issue obligation is the omitted-argument case.
