# Constructed Proof

Status: constructed, not machine-checked. No K tooling was executed.

## Formal Core

The proof targets `display_for_field()`'s JSONField display behavior with a minimal branch semantics:

* `fvk/mini-admin-display.k`
* `fvk/admin-display-spec.k`

Exact commands to machine-check later:

```sh
kompile fvk/mini-admin-display.k --backend haskell
kast --backend haskell fvk/admin-display-spec.k
kprove fvk/admin-display-spec.k
```

Expected machine-check result if the constructed proof is accepted: `#Top`.

## Claims Proved in the Constructed Model

* C-JSON-EXAMPLE: the issue example JSON object reaches `preparedJson(...)`.
* C-JSON-NONINVALID: every non-null, non-invalid JSONField value reaches `preparedJson(V, ENC)`.
* C-JSON-INVALID: invalid JSON input reaches `rawJson(S)`.
* C-POSTGRES-SUBCLASS: the postgres JSONField subclass reaches the same prepared JSON path for non-null, non-invalid values.
* C-POSTGRES-INVALID: the postgres JSONField subclass preserves invalid JSON input through the same prepare path.
* C-JSON-NONE: `none` reaches the supplied empty display value.
* C-NONJSON-FALLBACK: a non-JSON field still reaches the generic Python repr path.

## Proof Sketch

There are no loops or recursion in the modeled slice, so no circularity invariant is required.

For C-JSON-EXAMPLE, symbolic execution starts with the field constructor `jsonField("default")` and a non-`none` value. The JSONField rule rewrites the computation to `prepareJsonValue(jsonObject("foo", "bar"), "default")`. The non-invalid prepare rule then rewrites to `preparedJson(jsonObject("foo", "bar"), "default")`.

For C-JSON-NONINVALID, the same two-step path applies symbolically under the side condition `notBool isNone(V)` and `notBool isInvalidJson(V)`.

For C-JSON-INVALID, the JSONField rule first rewrites to `prepareJsonValue(invalidJson(S), ENC)`. The invalid-input prepare rule then rewrites to `rawJson(S)`, matching `forms.JSONField.prepare_value()` preserving `InvalidJSONInput`.

For C-POSTGRES-SUBCLASS, the subclass field first rewrites to the built-in `jsonField(ENC)` case. The proof then follows C-JSON-NONINVALID's prepared JSON path. For C-POSTGRES-INVALID, the same subclass rewrite is followed by C-JSON-INVALID's raw invalid-input path. This models the source inheritance and the V1 `isinstance(field, models.JSONField)` check.

For C-JSON-NONE, the `none` rule fires before the JSONField preparation rule and rewrites directly to `EMPTY`, matching the V1 ordering and the existing admin null-display contract.

For C-NONJSON-FALLBACK, the `normalField` rule rewrites to `pyRepr(V)`, showing the model still distinguishes the legacy fallback from the JSONField prepared path and that the fix is localized.

## Adequacy Gate

`fvk/INTENT_SPEC.md` states the intent-only requirements. `fvk/FORMAL_SPEC_ENGLISH.md` paraphrases the K claims. `fvk/SPEC_AUDIT.md` marks each claim as pass against the intent. `fvk/PUBLIC_COMPATIBILITY_AUDIT.md` found no unhandled public callsite, override, or signature issue.

## Residual Risk

This is a constructed proof over a mini semantics, not a machine-checked proof against full Python or Django runtime semantics. The trusted base is the adequacy of the mini model, the source evidence for `models.JSONField.formfield()` and `forms.JSONField.prepare_value()`, and the future K toolchain result if the emitted commands are run.

No tests were run and no tests were modified. Any test-removal recommendation is conditioned on later machine-checking; until then, keep tests.
