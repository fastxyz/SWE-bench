// Constructed, not machine-checked.
// Mini semantics for the Mathematica-printer dispatch fragment relevant to
// sympy__sympy-15345. This is not full Python semantics; it models the
// observable dispatch choice that determines whether a SymPy expression is
// formatted by MCodePrinter._print_Function or by the inherited unsupported
// Expr fallback.

module MINI-PYTHON-PRINTER-SYNTAX
  imports STRING-SYNTAX
  imports LIST-SYNTAX

  syntax Class ::= "MaxClass" | "MinClass" | "FunctionClass" | "ExprClass"
  syntax Expr ::= expr(Class, String, List)
  syntax Action ::= dispatch(Expr)
                  | printFunction(Expr)
                  | unsupportedFallback(Expr)
                  | emit(String)

  syntax String ::= bracketCall(String, List) [function]
                  | parenCall(String, List)   [function]
endmodule

module MINI-PYTHON-PRINTER
  imports MINI-PYTHON-PRINTER-SYNTAX
  imports STRING
  imports LIST

  configuration
    <k> $PGM:Action </k>
    <out> "" </out>

  // V1-added dispatch cases: class-specific printer methods exist for Max/Min.
  rule <k> dispatch(expr(MaxClass, NAME:String, ARGS:List))
        => printFunction(expr(MaxClass, NAME, ARGS)) ... </k>

  rule <k> dispatch(expr(MinClass, NAME:String, ARGS:List))
        => printFunction(expr(MinClass, NAME, ARGS)) ... </k>

  // Existing behavior for ordinary Function objects: use Mathematica bracket syntax.
  rule <k> dispatch(expr(FunctionClass, NAME:String, ARGS:List))
        => printFunction(expr(FunctionClass, NAME, ARGS)) ... </k>

  // Existing unsupported Expr fallback: use the inherited string representation.
  rule <k> dispatch(expr(ExprClass, NAME:String, ARGS:List))
        => unsupportedFallback(expr(ExprClass, NAME, ARGS)) ... </k>

  // MCodePrinter._print_Function observable shape.
  rule <k> printFunction(expr(CLASS:Class, NAME:String, ARGS:List))
        => emit(bracketCall(NAME, ARGS)) ... </k>

  // StrPrinter.emptyPrinter/repr-style observable shape for this issue.
  rule <k> unsupportedFallback(expr(CLASS:Class, NAME:String, ARGS:List))
        => emit(parenCall(NAME, ARGS)) ... </k>

  rule <k> emit(S:String) => .K </k>
       <out> _ => S </out>
endmodule
