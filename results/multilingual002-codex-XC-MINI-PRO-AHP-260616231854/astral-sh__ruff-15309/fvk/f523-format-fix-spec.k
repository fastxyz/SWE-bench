requires "mini-f523-format-fix.k"

module F523-FORMAT-FIX-SPEC
  imports MINI-F523-FORMAT-FIX

  // SPEC-PROVENANCE:
  // - from_prompt: expected `"Hello".format("world")` => `"Hello"`.
  // - obligation: when all explicit positional arguments are unused, no keyword
  //   arguments remain, the format string has no fields, and no-argument
  //   formatting is identity-preserving, the fix drops the `.format(...)` call.
  claim <k> shouldDropFormatCall(true, true, true, true, N, N) => true ... </k>
    requires N >Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - from_python_format_semantics: format strings with fields still perform
  //   formatting or raise missing-argument errors with zero arguments.
  // - obligation: F523 must not erase `.format(...)` when parsed fields exist.
  claim <k> shouldDropFormatCall(true, false, true, true, N, N) => false ... </k>
    requires N >Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - from_python_format_semantics: doubled braces are normalized by
  //   `str.format`, so no-argument formatting is not always identical to the
  //   source literal expression.
  // - obligation: F523 must not erase `.format(...)` when literal formatting is
  //   not identity-preserving.
  claim <k> shouldDropFormatCall(true, true, false, true, N, N) => false ... </k>
    requires N >Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - from_rule_contract: F523 removes extra positional arguments only.
  // - obligation: if keyword arguments remain, keep the format call and remove
  //   only positional arguments.
  claim <k> shouldDropFormatCall(false, true, true, true, N, N) => false ... </k>
    requires N >Int 0
    [all-path]
endmodule
