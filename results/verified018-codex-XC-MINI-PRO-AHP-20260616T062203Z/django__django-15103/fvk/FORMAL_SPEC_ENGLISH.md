# Formal Spec English

Status: English paraphrase of the claims in `fvk/json-script-spec.k`.

## Claim C-1

Formal claim: `jsonScript(V, omitted)` rewrites to a script tag with `type="application/json"` and no `id` attribute.

English meaning: Calling `django.utils.html.json_script(value)` without `element_id` returns `<script type="application/json">JSONESC(value)</script>`.

## Claim C-2

Formal claim: `jsonScript(V, noneId)` rewrites to the same no-ID script tag.

English meaning: Calling `django.utils.html.json_script(value, None)` returns `<script type="application/json">JSONESC(value)</script>`.

## Claim C-3

Formal claim: `jsonScript(V, id(E))` rewrites to a script tag with `id="HTMLESC(E)"` and `type="application/json"`.

English meaning: Calling `django.utils.html.json_script(value, element_id)` with a non-`None` ID returns the existing ID-bearing wrapper, with the ID escaped for an HTML attribute and the JSON body escaped by the existing JSON-script escaping path.

## Claim C-4

Formal claim: `filterJsonScript(V, I)` rewrites to `jsonScript(V, I)`.

English meaning: The template filter wrapper delegates to the utility helper with the same value and optional ID argument.

## Static Argument-Validation Claim

Formal claim source: `PO-5`, reasoned directly from `FilterExpression.args_check()`.

English meaning: Since the filter function has one defaulted parameter after the implicit input value, Django accepts both `{{ value|json_script }}` and `{{ value|json_script:"test_id" }}`.
