# Public Evidence Ledger

## E-1

Source: prompt

Quote: "Make the element_id argument of json_script optional"

Semantic obligation: `element_id` omission is in domain for both the Python utility and template filter.

Status: encoded in `PO-1`, `PO-2`, `PO-5`, and `PO-6`.

## E-2

Source: prompt

Quote: "I didn't need any id for it"

Semantic obligation: the omitted-ID path emits no `id` attribute.

Status: encoded in `PO-2`.

## E-3

Source: docs

Quote: "Safely outputs a Python object as JSON, wrapped in a `<script>` tag"

Semantic obligation: output remains a script tag containing JSON.

Status: encoded in `PO-2`, `PO-3`, and `PO-4`.

## E-4

Source: docs and public tests

Quote: ID-present examples render `<script id="..." type="application/json">...`.

Semantic obligation: existing ID-present behavior is preserved.

Status: encoded in `PO-3` and `PO-7`.

## E-5

Source: docs and public tests

Quote: "XSS attacks are mitigated by escaping the characters `<`, `>` and `&`."

Semantic obligation: JSON body escaping remains unchanged.

Status: encoded in `PO-4`.

## E-6

Source: implementation/API contract

Quote: `format_html()` escapes arguments with `conditional_escape()`.

Semantic obligation: provided IDs remain escaped through `format_html()`.

Status: encoded in `PO-3`.

## E-7

Source: source search

Quote: production references to `json_script` are only the utility definition and template filter wrapper.

Semantic obligation: adding a default does not require downstream production-source callsite changes.

Status: encoded in `PO-7`.
