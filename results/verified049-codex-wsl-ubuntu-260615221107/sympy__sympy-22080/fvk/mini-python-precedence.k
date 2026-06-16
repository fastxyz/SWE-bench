requires "domains.md"

module MINI-PYTHON-PRECEDENCE-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX
  imports STRING-SYNTAX

  syntax Exp ::= Sym(String)
               | Mod(Exp, Exp)
               | ModSubclass(Exp, Exp)
               | CustomPyMod(Exp, Exp)
               | Neg(Exp)
               | Mul(Exp, Exp)
               | Pow(Exp, Exp)

  syntax Code ::= code(String)
                | paren(Code)
                | neg(Code)
                | mul(Code, Code)
                | pow(Code, Code)
                | mod(Code, Code)
                | custom(Code, Code)
                | print(Exp) [function]
                | printMod(Exp, Exp) [function]
                | parenthesize(Exp, Int, Bool) [function]

  syntax Int ::= pyPrec(Exp) [function]
               | genericPrec(Exp) [function]
endmodule

module MINI-PYTHON-PRECEDENCE
  imports MINI-PYTHON-PRECEDENCE-SYNTAX
  imports INT
  imports BOOL
  imports STRING

  configuration <k> $PGM:K </k>

  syntax Int ::= AddPrec() [function]
               | MulPrec() [function]
               | PowPrec() [function]
               | FuncPrec() [function]
               | AtomPrec() [function]
  rule AddPrec() => 40
  rule MulPrec() => 50
  rule PowPrec() => 60
  rule FuncPrec() => 70
  rule AtomPrec() => 1000

  rule genericPrec(Sym(_)) => AtomPrec()
  rule genericPrec(Mod(_, _)) => FuncPrec()
  rule genericPrec(ModSubclass(_, _)) => FuncPrec()
  rule genericPrec(CustomPyMod(_, _)) => FuncPrec()
  rule genericPrec(Neg(_)) => AddPrec()
  rule genericPrec(Mul(_, _)) => MulPrec()
  rule genericPrec(Pow(_, _)) => PowPrec()

  // Mirrors AbstractPythonCodePrinter._precedence.
  rule pyPrec(Mod(_, _)) => AddPrec()
  rule pyPrec(ModSubclass(_, _)) => AddPrec()
  rule pyPrec(CustomPyMod(_, _)) => FuncPrec()
  rule pyPrec(Sym(S)) => genericPrec(Sym(S))
  rule pyPrec(Neg(E)) => genericPrec(Neg(E))
  rule pyPrec(Mul(A, B)) => genericPrec(Mul(A, B))
  rule pyPrec(Pow(A, B)) => genericPrec(Pow(A, B))

  rule parenthesize(E, L, false) => paren(print(E))
    requires pyPrec(E) <=Int L
  rule parenthesize(E, L, false) => print(E)
    requires pyPrec(E) >Int L
  rule parenthesize(E, L, true) => paren(print(E))
    requires pyPrec(E) <Int L
  rule parenthesize(E, L, true) => print(E)
    requires pyPrec(E) >=Int L

  rule print(Sym(S)) => code(S)
  rule print(Mod(A, B)) => printMod(A, B)
  rule print(ModSubclass(A, B)) => printMod(A, B)
  rule print(CustomPyMod(A, B)) => custom(print(A), print(B))
  rule print(Neg(E)) => neg(parenthesize(E, AddPrec(), false))
  rule print(Mul(A, B)) => mul(parenthesize(A, MulPrec(), false), parenthesize(B, MulPrec(), false))
  rule print(Pow(A, B)) => pow(parenthesize(A, PowPrec(), false), parenthesize(B, PowPrec(), false))
  rule printMod(A, B) => mod(parenthesize(A, FuncPrec(), false), parenthesize(B, FuncPrec(), false))
endmodule
