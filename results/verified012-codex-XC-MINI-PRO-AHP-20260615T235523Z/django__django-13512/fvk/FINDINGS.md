# FVK Findings

Status: constructed, not machine-checked. No tests, Python, or K tooling were run.

## F-001: Legacy non-ASCII display escaped Unicode in JSONField form/admin display

Input: a JSONField value containing readable non-ASCII text, represented by the issue example `"China"` text (`中国`) or a JSON object/list containing such text.

Observed before V1: `forms.JSONField.prepare_value()` called `json.dumps(value, cls=self.encoder)`, which defaults to `ensure_ascii=True`; the display string therefore used escapes such as `"\u4e2d\u56fd"`.

Expected by public intent: the form/admin display string preserves readable Unicode, e.g. `"中国"`, because the problem is explicitly about admin display rather than database storage.

Classification: code bug in display serialization.

Status after V1: resolved by `PO-002`; `prepare_value()` now calls `json.dumps(value, ensure_ascii=False, cls=self.encoder)`.

## F-002: Invalid JSON redisplay must remain unchanged

Input: invalid submitted JSON that `bound_data()` wraps as `InvalidJSONInput`, such as `{"foo"}`.

Observed in candidate: `prepare_value()` returns the `InvalidJSONInput` unchanged before reaching `json.dumps()`.

Expected by public/source intent: invalid user input should be redisplayed as typed and not overquoted.

Classification: compatibility/frame condition.

Status after V1: no problem found; discharged by `PO-001`.

## F-003: Database JSON serialization must remain outside the display fix

Input: any model `JSONField` value prepared for database storage.

Observed in candidate: `django.db.models.fields.json.JSONField.get_prep_value()` still calls `json.dumps(value, cls=self.encoder)` and was not edited.

Expected by public intent: the issue discussion identifies the fix as admin/display-only and explicitly separates it from MySQL write/read behavior.

Classification: compatibility/frame condition.

Status after V1: no problem found; discharged by `PO-005`.

## F-004: Custom encoder dispatch must remain intact

Input: a `forms.JSONField(encoder=CustomEncoder)` or model `JSONField(encoder=CustomEncoder)` formfield.

Observed in candidate: the display call still passes `cls=self.encoder`; V1 only supplies `ensure_ascii=False`.

Expected by public/source intent: custom encoder remains honored.

Classification: public API compatibility.

Status after V1: no problem found; discharged by `PO-004`.

## F-005: Constructed proof was not machine-checked

Input: the FVK claims in `fvk/jsonfield-prepare-value-spec.k`.

Observed in this workspace: commands such as `kompile` and `kprove` were not run because the task forbids executing K tooling.

Expected by FVK honesty gate: label the proof as constructed, not machine-checked, and do not recommend deleting tests unless a future machine check returns `#Top`.

Classification: proof execution boundary, not a code bug.

Status after V1: documented in `PROOF.md` and `ITERATION_GUIDANCE.md`.

## Summary

The only code bug identified by the FVK audit is F-001, and V1 addresses it directly. Findings F-002 through F-004 are compatibility checks that V1 passes. F-005 prevents claiming machine-checked proof status, but it does not justify a source change.
