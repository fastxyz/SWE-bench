# FVK Spec: JSONField Admin/Form Unicode Display

Status: constructed, not machine-checked. No tests, Python, or K tooling were run.

## Scope

The audited production change is `django.forms.JSONField.prepare_value()` in `repo/django/forms/fields.py`. The observable under audit is the string prepared for a form widget, including Django admin's model form path. The audit also checks the adjacent contributors to that observable:

- `BoundField.value()` calls `field.bound_data()` for bound forms and then `field.prepare_value()`.
- `JSONField.bound_data()` converts valid submitted JSON back to Python values and preserves invalid submitted JSON as `InvalidJSONInput`.
- `Textarea` renders `widget.value` through Django's template system.
- `django.db.models.JSONField.formfield()` passes the model field's encoder/decoder into `forms.JSONField`.
- `django.db.models.JSONField.get_prep_value()` remains the database serialization path and is intentionally outside the display-only change.

There are no loops in the audited function.

## Public Intent Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| I-001 | `benchmark/PROBLEM.md` | "Admin doesn't display properly unicode chars in JSONFields." | Admin/form display of JSONField values containing non-ASCII text must preserve readable Unicode rather than showing JSON `\uXXXX` escape sequences. | Encoded by `PO-002` and `jsonfield-prepare-value-spec.k` claims. |
| I-002 | `benchmark/PROBLEM.md` | `json.dumps` uses ASCII encoding by default, so Chinese appears as `"\u4e2d\u56fd"`. | The defective behavior is specifically the default `ensure_ascii=True` display path. A legacy expectation of escaped non-ASCII is SUSPECT. | Recorded as `F-001`; V1 changes the display dump to `ensure_ascii=False`. |
| I-003 | `benchmark/PROBLEM.md` | "this function is only used in Django admin's display, so it will not influence any operation about MySQL writing and reading." | The repair should be display-only and must not broaden to database write/read serialization. | Encoded by `PO-005`; DB JSON serialization remains unchanged. |
| I-004 | `benchmark/PROBLEM.md` | "If we save non-ASCII characters in a JsonField, such as emoji, Chinese, Japanese..." | The intended domain is the family of JSON-serializable values containing non-ASCII Unicode text, not only the exact Chinese example. | Encoded by `PO-002` as a general non-ASCII preservation obligation; the K file includes a concrete discriminator for the Chinese example. |
| I-005 | Source: `JSONField.prepare_value()` existing branch | Invalid submitted JSON is wrapped as `InvalidJSONInput` and returned unchanged by `prepare_value()`. | Redisplay of invalid user input must not be JSON-dumped or overquoted. | Encoded by `PO-001`; unchanged in V1. |
| I-006 | Source: `JSONField.__init__()` and model `formfield()` | `encoder` is accepted and passed to form JSON serialization as `cls=self.encoder`. | Custom encoder behavior must remain wired through the display serialization call. | Encoded by `PO-004`; V1 keeps `cls=self.encoder`. |
| I-007 | Source: `Widget.format_value()` and `textarea.html` | Widget values are stringified and then rendered as `{{ widget.value }}`. | Displaying raw Unicode JSON text must still rely on normal template escaping; the source change must not bypass widget rendering. | Encoded by `PO-006`; V1 only changes the string passed into the existing render path. |

## Intent-Only Requirements

1. For any `InvalidJSONInput`, `JSONField.prepare_value(value)` returns `value` unchanged.
2. For any JSON-serializable non-invalid value containing non-ASCII Unicode text, `JSONField.prepare_value(value)` returns JSON text that preserves those Unicode characters directly instead of replacing them with JSON `\uXXXX` escape sequences.
3. For ASCII-only JSON-serializable values, the displayed JSON text remains the same as the previous default `json.dumps()` output because `ensure_ascii` only changes non-ASCII escaping.
4. Any configured custom encoder remains the encoder used by JSON serialization.
5. Database JSON serialization and validation are frame conditions: they must not be changed by the admin/form display repair.
6. Form/widget rendering behavior and template escaping remain on the existing path.

## Formal Claims

The companion K artifacts are:

- `fvk/mini-json-form.k`: a minimal semantics for the audited display fragment.
- `fvk/jsonfield-prepare-value-spec.k`: reachability claims for `prepareValue`.

The formal claims paraphrase as:

- `CLAIM-PREPARE-INVALID`: starting from `prepareValue(invalidInput(S), E)`, the computation reaches `raw(S)`.
- `CLAIM-PREPARE-UNICODE-CHINA`: starting from `prepareValue(jstring(chinaText), E)`, the computation reaches `displayUnicodeChina`, not `displayEscapedChina`.
- `CLAIM-PREPARE-GENERAL`: for any non-invalid JSON value `V`, `prepareValue(V, E)` reaches `jsonDumps(V, false, E)`.

The `chinaText` discriminator models the issue's public example "China" text. In the semantics, `jsonDumps(jstring(chinaText), false, E)` rewrites to `displayUnicodeChina`; `jsonDumps(jstring(chinaText), true, E)` rewrites to `displayEscapedChina`. This keeps the property axis visible: a pre-fix implementation using default ASCII escaping would land in a different observable state.

## Adequacy Audit

| Formal claim | Intent match | Result |
| --- | --- | --- |
| `CLAIM-PREPARE-INVALID` | Matches I-005 and requirement 1. | Pass. |
| `CLAIM-PREPARE-UNICODE-CHINA` | Matches I-001, I-002, and the issue's concrete example. | Pass. |
| `CLAIM-PREPARE-GENERAL` | Matches I-004 and requirement 2 for the non-invalid value family. | Pass, with JSON library behavior abstracted as `jsonDumps`. |
| Frame: database JSON serialization unchanged | Matches I-003 and requirement 5. | Pass by source diff and compatibility audit; not a K execution claim because it is a non-touched module frame condition. |
| Frame: custom encoder remains passed | Matches I-006 and requirement 4. | Pass. |
| Frame: widget rendering remains on template path | Matches I-007 and requirement 6. | Pass. |

No formal claim is derived only from the V1 implementation. The expected non-ASCII display behavior comes from the public issue intent; the implementation is used to model the branch and call shape.

## Public Compatibility Audit

Changed public symbol: `django.forms.JSONField.prepare_value(self, value)`.

- Signature: unchanged.
- Return type shape: unchanged; returns a string-like display value for JSON values and `InvalidJSONInput` unchanged for invalid input. The non-ASCII contents of the returned string change intentionally.
- Custom encoder: unchanged dispatch shape, still `cls=self.encoder`.
- Subclasses/aliases: `django.contrib.postgres.forms.jsonb.JSONField` subclasses `django.forms.JSONField` without overriding `prepare_value()`, so it inherits the fixed display behavior without API adjustment.
- Model integration: `django.db.models.JSONField.formfield()` still supplies `forms.JSONField` with the same encoder/decoder kwargs.
- Database/storage path: unchanged.

Compatibility conclusion: no source edit beyond V1 is justified.
