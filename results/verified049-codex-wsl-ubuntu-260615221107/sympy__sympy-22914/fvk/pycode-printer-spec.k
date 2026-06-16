requires "mini-pycode.k"

module PYCODE-PRINTER-SPEC
  imports MINI-PYCODE

  // SPEC-PROVENANCE:
  // - from_prompt: "PythonCodePrinter doesn't support Min and Max" =>
  //   Min and Max must be accepted by PythonCodePrinter.
  // - from_prompt: "print(pycode(c))" for c = Min(a,b) should lead to "min(x, y)" =>
  //   Min prints as Python builtin min with recursively printed arguments.
  // - from_prompt: suggested _print_Max returns "max({})" =>
  //   Max prints as Python builtin max with recursively printed arguments.
  // - from_code: _known_functions feeds PythonCodePrinter._kf and the generated
  //   _print_<name> methods call _print_known_func.
  claim
    <k> print(Fun("Min", Sym("a") , Sym("b") , .Args)) => "min(a, b)" </k>
    <unsupported> .Set </unsupported>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "PythonCodePrinter doesn't support Min and Max" =>
  //   Max must be accepted by PythonCodePrinter.
  // - from_prompt: suggested _print_Max uses ", ".join(...) over expr.args =>
  //   more than two arguments remain variadic and ordered as expr.args.
  // - from_code: _print_known_func formats "{name}({args})".
  claim
    <k> print(Fun("Max", Sym("a") , Sym("b") , Sym("c") , .Args)) => "max(a, b, c)" </k>
    <unsupported> .Set </unsupported>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: both functions should generate Python code, not only a flat
  //   two-symbol example.
  // - from_code: _print_known_func recursively calls self._print on each arg.
  claim
    <k> print(Fun("Max", Sym("a") , Fun("Min", Sym("b") , Sym("c") , .Args) , .Args))
      => "max(a, min(b, c))" </k>
    <unsupported> .Set </unsupported>
    [all-path]
endmodule
