requires "mini-django-widgets.k"

module MINI-DJANGO-WIDGETS-SPEC
  imports MINI-DJANGO-WIDGETS
  imports BOOL

  syntax Checks ::= expected(Values, Bool) [function]
  rule expected(.Values, C) => .Checks
  rule expected(cons(V, VS), C) => ccons(C orBool shouldCheck(V), expected(VS, C))
  rule append(snoc(OS:Checks, B:Bool), CS:Checks) => append(OS, ccons(B, CS)) [simplification]

  // SPEC-PROVENANCE:
  // - E3: The issue identifies mutation of attrs passed to CheckboxInput.get_context()
  //   as the root cause.
  // - E4: check_test(value) determines generated checked state.
  // Claim: CHECKBOX-CONTEXT-NO-MUTATE
  claim
    <k> checkbox(V:Bool) => .K ... </k>
    <attrs> attrs(C:Bool) => attrs(C) </attrs>
    <out> OS:Checks => snoc(OS, C orBool shouldCheck(V)) </out>
    [all-path]

  // SPEC-PROVENANCE:
  // - E1/E2: SplitArrayField(BooleanField) must not check widgets after the
  //   first true value when their own backing value is false.
  // - E6: SplitArrayWidget reuses final_attrs across child renders.
  // Claim: SPLIT-ARRAY-CHECKED-INDEPENDENT
  claim
    <k> render(VS:Values) => .K ... </k>
    <attrs> attrs(C:Bool) => attrs(C) </attrs>
    <out> OS:Checks => append(OS, expected(VS, C)) </out>
    [all-path]

  // SPEC-PROVENANCE:
  // - Concrete public issue shape: no explicit checked attr and values
  //   [False, True, False] must render [False, True, False].
  // Claim: REPRODUCTION-FALSE-TRUE-FALSE
  claim
    <k> render(cons(false, cons(true, cons(false, .Values)))) => .K ... </k>
    <attrs> attrs(false) => attrs(false) </attrs>
    <out> .Checks => ccons(false, ccons(true, ccons(false, .Checks))) </out>
    [all-path]
endmodule
