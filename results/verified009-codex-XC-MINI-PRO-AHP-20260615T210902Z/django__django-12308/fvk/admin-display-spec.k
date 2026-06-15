requires "mini-admin-display.k"

module ADMIN-DISPLAY-SPEC
  imports MINI-ADMIN-DISPLAY

  // SPEC-PROVENANCE:
  // - E1/E2: The prompt's JSON object example must display as JSON, not Python repr.
  claim <k> displayForField(jsonObject("foo", "bar"), jsonField("default"), emptyDisplay("-empty-"))
        => preparedJson(jsonObject("foo", "bar"), "default")
       </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E1/E3/E5: Non-null JSONField values use field.formfield().prepare_value(value).
  claim <k> displayForField(V:Value, jsonField(ENC:String), EMPTY:Display)
        => preparedJson(V, ENC)
       </k>
    requires notBool isNone(V) andBool notBool isInvalidJson(V)
    [all-path]

  // SPEC-PROVENANCE:
  // - E3/E6: InvalidJSONInput must be preserved by prepare_value().
  claim <k> displayForField(invalidJson(S:String), jsonField(ENC:String), EMPTY:Display)
        => rawJson(S)
       </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E4/E8: contrib.postgres JSONField subclasses the built-in model JSONField.
  claim <k> displayForField(V:Value, postgresJsonField(ENC:String), EMPTY:Display)
        => preparedJson(V, ENC)
       </k>
    requires notBool isNone(V) andBool notBool isInvalidJson(V)
    [all-path]

  // SPEC-PROVENANCE:
  // - E3/E4/E8: subclass handling still delegates to prepare_value(), including invalid input.
  claim <k> displayForField(invalidJson(S:String), postgresJsonField(ENC:String), EMPTY:Display)
        => rawJson(S)
       </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E7: Existing admin display_for_field(None, ...) behavior returns empty_value_display.
  claim <k> displayForField(none, jsonField(ENC:String), EMPTY:Display)
        => EMPTY
       </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - Frame condition: non-JSON fields keep the generic fallback behavior.
  claim <k> displayForField(jsonObject(K:String, V:String), normalField, EMPTY:Display)
        => pyRepr(jsonObject(K, V))
       </k>
    [all-path]
endmodule
