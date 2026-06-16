// Constructed FVK side artifact. Not compiled or machine-checked.

requires "mini-signature-default.k"

module SIGNATURE-DEFAULT-SPEC
  imports MINI-SIGNATURE-DEFAULT

  // SPEC-PROVENANCE:
  // - from_prompt: expected add_lines(..., color=(1, 1, 1), ...)
  //   => tuple defaults retain parentheses in default context.
  claim
    <k> render(Tuple(Const("1") ; Const("1") ; Const("1") ; .Nodes), true)
      => "(1, 1, 1)" </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_default_domain: Python singleton tuple syntax requires a trailing comma.
  claim
    <k> render(Tuple(Const("1") ; .Nodes), true) => "(1,)" </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_source/tests: annotation slices such as Tuple[int, int] stay unparenthesized.
  claim
    <k> render(Subscript(Name("Tuple"), Tuple(Name("int") ; Name("int") ; .Nodes)), true)
      => "Tuple[int, int]" </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - frame condition: normal tuple unparse behavior is not changed by default rendering.
  claim
    <k> render(Tuple(Const("1") ; Const("1") ; .Nodes), false) => "1, 1" </k>
    [all-path]
endmodule
