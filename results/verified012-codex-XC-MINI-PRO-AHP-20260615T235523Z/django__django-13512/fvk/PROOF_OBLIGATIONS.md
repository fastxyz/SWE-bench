# FVK Proof Obligations

Status: constructed, not machine-checked. No tests, Python, or K tooling were run.

## PO-001: Invalid Input Preservation

Requirement: If `value` is an `InvalidJSONInput`, `JSONField.prepare_value(value)` returns `value` unchanged.

Evidence: `JSONField.bound_data()` returns `InvalidJSONInput(data)` when submitted JSON cannot be decoded, and `prepare_value()` has an explicit first branch for that type.

Formal claim: `CLAIM-PREPARE-INVALID` in `fvk/jsonfield-prepare-value-spec.k`.

Discharge argument: V1 does not change the `InvalidJSONInput` branch. Symbolic execution takes the first branch and reaches `raw(S)` without calling `jsonDumps`.

Related findings: F-002.

Status: discharged by construction.

## PO-002: Non-ASCII Unicode Display Preservation

Requirement: For non-invalid JSON-serializable values containing non-ASCII text, form/admin display serialization preserves readable Unicode rather than emitting JSON `\uXXXX` escapes.

Evidence: public issue states that admin "doesn't display properly unicode chars in JSONFields" and identifies default `json.dumps()` ASCII escaping as the defect.

Formal claims: `CLAIM-PREPARE-UNICODE-CHINA` and `CLAIM-PREPARE-GENERAL` in `fvk/jsonfield-prepare-value-spec.k`.

Discharge argument: The normal branch of V1 calls `json.dumps(value, ensure_ascii=False, cls=self.encoder)`. In the mini semantics, that is modeled as `jsonDumps(V, false, E)`. The concrete discriminator `jstring(chinaText)` rewrites to `displayUnicodeChina`, while the legacy/default `true` path rewrites to `displayEscapedChina`.

Related findings: F-001.

Status: discharged by construction.

## PO-003: ASCII Display Compatibility

Requirement: For ASCII-only JSON-serializable values, displayed JSON text remains compatible with the previous output.

Evidence: the issue concerns non-ASCII escaping. In Python JSON serialization, `ensure_ascii` controls escaping of non-ASCII characters; ASCII-only strings are unaffected by setting it to `False`.

Formal claim: covered by `CLAIM-PREPARE-GENERAL` plus the semantic side note that `jsonDumps(V, false, E) == jsonDumps(V, true, E)` for ASCII-only values.

Discharge argument: V1 changes only the `ensure_ascii` parameter. It does not change separators, sorting, encoder, or the invalid-input branch.

Related findings: F-001.

Status: discharged by construction as a frame/semantic property of `json.dumps`.

## PO-004: Custom Encoder Preservation

Requirement: The configured JSON encoder remains the encoder passed to serialization.

Evidence: `JSONField.__init__()` stores `self.encoder`, model `JSONField.formfield()` passes the encoder into `forms.JSONField`, and existing tests use a custom encoder path.

Formal claim: `CLAIM-PREPARE-GENERAL` includes the symbolic encoder `E` and reaches `jsonDumps(V, false, E)`, not `jsonDumps(V, false, noneEncoder)`.

Discharge argument: V1 preserved `cls=self.encoder` in the `json.dumps()` call.

Related findings: F-004.

Status: discharged by construction.

## PO-005: Database Serialization Frame

Requirement: Database preparation, validation, and JSON path compilation remain unchanged by the admin/form display fix.

Evidence: public issue discussion says the relevant function is only used for admin display and does not influence MySQL writing/reading. Source diff shows only `repo/django/forms/fields.py` changed; `repo/django/db/models/fields/json.py` is unchanged.

Formal claim: frame obligation outside `prepareValue`; no K execution claim is needed because the touched source file does not define the database serialization functions.

Discharge argument: `django.db.models.fields.json.JSONField.get_prep_value()` still calls `json.dumps(value, cls=self.encoder)`, and `validate()` still uses the existing serialization call for validation.

Related findings: F-003.

Status: discharged by source-frame inspection.

## PO-006: Existing Widget Escaping Path Preservation

Requirement: The fix must not bypass Django's form widget escaping/rendering path.

Evidence: `BoundField.value()` calls `field.prepare_value(data)`, `Widget.format_value()` stringifies display values, and `textarea.html` renders `{{ widget.value }}` through the template.

Formal claim: compatibility/frame obligation, not a separate `prepareValue` K claim.

Discharge argument: V1 changes only the JSON string contents returned by `prepare_value()`. It does not alter `BoundField`, `Widget`, `Textarea`, templates, or mark the value safe.

Related findings: F-001, F-002.

Status: discharged by source-frame inspection.

## PO-007: Bound Valid JSON Redisplay Uses the Same Display Contract

Requirement: When a bound form contains valid JSON and another field causes the form to redisplay, the JSONField value should be decoded and then displayed with the same non-ASCII preservation contract.

Evidence: `BoundField.value()` routes bound data through `field.bound_data()` before `prepare_value()`. `JSONField.bound_data()` returns `json.loads(data, cls=self.decoder)` on valid JSON.

Formal claim: composition of `bound_data()` source inspection with `CLAIM-PREPARE-GENERAL`.

Discharge argument: Valid bound JSON reaches the non-invalid branch of `prepare_value()` and therefore uses `jsonDumps(V, false, E)`.

Related findings: F-001.

Status: discharged by construction and source-frame inspection.

## Machine-Check Commands Not Executed

The commands to run in a future environment are:

```sh
cd fvk
kompile mini-json-form.k --backend haskell
kast --backend haskell jsonfield-prepare-value-spec.k
kprove jsonfield-prepare-value-spec.k
```

Expected result if the constructed proof is accepted by K: `#Top` for the claims. This workspace forbids running these commands.
