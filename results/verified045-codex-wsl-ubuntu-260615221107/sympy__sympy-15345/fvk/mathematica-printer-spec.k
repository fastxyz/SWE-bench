// Constructed, not machine-checked.
requires "mini-python-printer.k"

module MATHEMATICA-PRINTER-SPEC
  imports MINI-PYTHON-PRINTER
  imports LIST
  imports STRING

  // SPEC-PROVENANCE:
  // - from_prompt: "mathematica_code(Max(x,2)) ... expect ... 'Max[x,2]'"
  //   => SymPy Max must be emitted as a Mathematica function call with square brackets.
  // - from_prompt: "instead I get 'Max(2, x)' which is not valid Mathematica code"
  //   => parenthesized fallback output is forbidden for in-domain Max expressions.
  // - from_code: V1 adds MCodePrinter._print_Max(self, expr) delegating to
  //   MCodePrinter._print_Function.
  claim <k> dispatch(expr(MaxClass, "Max", ARGS:List)) => .K </k>
        <out> "" => bracketCall("Max", ARGS) </out>
        [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt_hint: "neither Mathematica Max or Min functions are in"
  //   => the issue names Max directly and identifies Min as the homogeneous sibling.
  // - from_code: V1 adds MCodePrinter._print_Min(self, expr) delegating to
  //   MCodePrinter._print_Function.
  claim <k> dispatch(expr(MinClass, "Min", ARGS:List)) => .K </k>
        <out> "" => bracketCall("Min", ARGS) </out>
        [all-path]

  // SPEC-PROVENANCE:
  // - from_public_test: test_mathematica.py checks f(x,y,z) -> f[x, y, z]
  //   and sin(x) -> Sin[x].
  // - frame_condition: V1 must not change ordinary Function bracket printing.
  claim <k> dispatch(expr(FunctionClass, NAME:String, ARGS:List)) => .K </k>
        <out> "" => bracketCall(NAME, ARGS) </out>
        [all-path]

  // SPEC-PROVENANCE:
  // - from_code: unsupported non-Function Expr values still route to the
  //   inherited unsupported fallback; V1 only adds class-specific Max/Min methods.
  // - frame_condition: do not globally replace CodePrinter._print_Expr behavior.
  claim <k> dispatch(expr(ExprClass, NAME:String, ARGS:List)) => .K </k>
        <out> "" => parenCall(NAME, ARGS) </out>
        [all-path]
endmodule
