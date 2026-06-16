requires "mini-python-precedence.k"

module PYCODE-MOD-PRECEDENCE-SPEC
  imports MINI-PYTHON-PRECEDENCE

  // SPEC-PROVENANCE:
  // - from_prompt: "pycode(-Mod(x, y))" produced "-x % y" => negate the whole modulo expression.
  // - from_prompt: "precedence order wrong for - and %" => parenthesize Mod under unary negative printing.
  claim <k> print(Neg(Mod(Sym("x"), Sym("y")))) => neg(paren(mod(code("x"), code("y")))) </k>
    [label(K-CLAIM-MOD-NEG), all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "expr * Mod(a, b)" must not move the multiplier into Mod's first argument.
  claim <k> print(Mul(Sym("c"), Mod(Sym("x"), Sym("y")))) => mul(code("c"), paren(mod(code("x"), code("y")))) </k>
    [label(K-CLAIM-MOD-MUL), all-path]

  // SPEC-PROVENANCE:
  // - from_default_domain: Python * and % share precedence and associate left-to-right.
  // - from_code: _print_Mod keeps using generic function precedence for operands.
  claim <k> print(Mod(Sym("x"), Mul(Sym("y"), Sym("z")))) => mod(code("x"), paren(mul(code("y"), code("z")))) </k>
    [label(K-CLAIM-MOD-OPERANDS), all-path]

  // SPEC-PROVENANCE:
  // - from_code: Printer dispatches through class MRO.
  // - from_intent: inherited _print_Mod output has the same % precedence obligation as exact Mod.
  claim <k> print(Neg(ModSubclass(Sym("x"), Sym("y")))) => neg(paren(mod(code("x"), code("y")))) </k>
    [label(K-CLAIM-MOD-SUBCLASS), all-path]

endmodule
