// Constructed, not machine-checked.
// Minimal abstract K fragment for the SymPy printer behavior audited here.
// It models only the observable needed for sympy__sympy-14531:
// recursive use of the active printer for composite expression operands,
// sympy_integers-sensitive Rational/Integer rendering, and PythonPrinter
// symbol collection.

module MINI-PYTHON-PRINTING-SYNTAX
    imports INT
    imports STRING

    syntax Expr ::= Sym(String)
                  | IntExpr(Int)
                  | Rat(Int, Int)
                  | Pred(String)
                  | AppliedPredicate(Expr, Expr)
                  | ExprCondPair(Expr, Expr)
                  | IntervalExpr(Expr, Expr, String)
                  | Lambda1(Expr, Expr)
                  | LambdaN(ExprList, Expr)
                  | LimitExpr(Expr, Expr, Expr, String)
                  | MatrixElementExpr(Expr, Expr, Expr)
                  | NormalExpr(Expr, Expr)
                  | RelExpr(String, Expr, Expr)
                  | UniformExpr(Expr, Expr)

    syntax ExprList ::= ".ExprList" | Expr "," ExprList
    syntax SymSet ::= ".SymSet" | String ";" SymSet

    syntax String ::= printStr(Bool, Expr) [function]
                    | rawStr(Expr) [function]
                    | printExprList(Bool, ExprList) [function]
                    | pythonProgram(Expr) [function]
                    | symbolDecls(SymSet) [function]

    syntax SymSet ::= collectSymbols(Expr) [function]
                    | collectSymbolsList(ExprList) [function]
                    | union(SymSet, SymSet) [function]
                    | add(String, SymSet) [function]

    syntax String ::= relName(String) [function]
endmodule

module MINI-PYTHON-PRINTING
    imports MINI-PYTHON-PRINTING-SYNTAX
    imports BOOL
    imports INT
    imports STRING

    rule printStr(SI, Sym(N)) => N

    rule printStr(false, IntExpr(I)) => Int2String(I)
    rule printStr(true,  IntExpr(I)) => "S(" +String Int2String(I) +String ")"

    rule printStr(false, Rat(P, Q)) => Int2String(P) +String "/" +String Int2String(Q)
      requires Q =/=Int 1
    rule printStr(true, Rat(P, Q)) => "S(" +String Int2String(P) +String ")/" +String Int2String(Q)
      requires Q =/=Int 1
    rule printStr(SI, Rat(P, 1)) => printStr(SI, IntExpr(P))

    // rawStr stands for the legacy direct "%s" interpolation of a SymPy object.
    rule rawStr(Sym(N)) => N
    rule rawStr(IntExpr(I)) => Int2String(I)
    rule rawStr(Rat(P, Q)) => Int2String(P) +String "/" +String Int2String(Q)
      requires Q =/=Int 1
    rule rawStr(Rat(P, 1)) => Int2String(P)

    rule printStr(SI, Pred(N)) => "Q." +String N

    rule printStr(SI, AppliedPredicate(F, A))
      => printStr(SI, F) +String "(" +String printStr(SI, A) +String ")"

    rule printStr(SI, ExprCondPair(E, C))
      => "(" +String printStr(SI, E) +String ", " +String printStr(SI, C) +String ")"

    rule printStr(SI, IntervalExpr(A, B, M))
      => "Interval" +String M +String "(" +String printStr(SI, A)
         +String ", " +String printStr(SI, B) +String ")"

    rule printStr(SI, Lambda1(A, E))
      => "Lambda(" +String printStr(SI, A) +String ", "
         +String printStr(SI, E) +String ")"

    rule printStr(SI, LambdaN(AS, E))
      => "Lambda((" +String printExprList(SI, AS) +String "), "
         +String printStr(SI, E) +String ")"

    rule printStr(SI, LimitExpr(E, Z, Z0, "+"))
      => "Limit(" +String printStr(SI, E) +String ", "
         +String printStr(SI, Z) +String ", " +String printStr(SI, Z0)
         +String ")"

    rule printStr(SI, LimitExpr(E, Z, Z0, D))
      => "Limit(" +String printStr(SI, E) +String ", "
         +String printStr(SI, Z) +String ", " +String printStr(SI, Z0)
         +String ", dir='" +String D +String "')"
      requires D =/=String "+"

    rule printStr(SI, MatrixElementExpr(P, I, J))
      => printStr(SI, P) +String "[" +String printStr(SI, I)
         +String ", " +String printStr(SI, J) +String "]"

    rule printStr(SI, NormalExpr(Mu, Sigma))
      => "Normal(" +String printStr(SI, Mu) +String ", "
         +String printStr(SI, Sigma) +String ")"

    rule printStr(SI, RelExpr(OP, L, R))
      => relName(OP) +String "(" +String printStr(SI, L)
         +String ", " +String printStr(SI, R) +String ")"
      requires OP ==String "==" orBool OP ==String "!="

    rule printStr(SI, UniformExpr(A, B))
      => "Uniform(" +String printStr(SI, A) +String ", "
         +String printStr(SI, B) +String ")"

    rule relName("==") => "Eq"
    rule relName("!=") => "Ne"

    rule printExprList(SI, .ExprList) => ""
    rule printExprList(SI, E , .ExprList) => printStr(SI, E)
    rule printExprList(SI, E , ES) => printStr(SI, E) +String ", " +String printExprList(SI, ES)
      requires ES =/=K .ExprList

    rule collectSymbols(Sym(N)) => add(N, .SymSet)
    rule collectSymbols(IntExpr(I)) => .SymSet
    rule collectSymbols(Rat(P, Q)) => .SymSet
    rule collectSymbols(Pred(N)) => .SymSet
    rule collectSymbols(AppliedPredicate(F, A)) => union(collectSymbols(F), collectSymbols(A))
    rule collectSymbols(ExprCondPair(E, C)) => union(collectSymbols(E), collectSymbols(C))
    rule collectSymbols(IntervalExpr(A, B, M)) => union(collectSymbols(A), collectSymbols(B))
    rule collectSymbols(Lambda1(A, E)) => union(collectSymbols(A), collectSymbols(E))
    rule collectSymbols(LambdaN(AS, E)) => union(collectSymbolsList(AS), collectSymbols(E))
    rule collectSymbols(LimitExpr(E, Z, Z0, D))
      => union(collectSymbols(E), union(collectSymbols(Z), collectSymbols(Z0)))
    rule collectSymbols(MatrixElementExpr(P, I, J))
      => union(collectSymbols(P), union(collectSymbols(I), collectSymbols(J)))
    rule collectSymbols(NormalExpr(Mu, Sigma)) => union(collectSymbols(Mu), collectSymbols(Sigma))
    rule collectSymbols(RelExpr(OP, L, R)) => union(collectSymbols(L), collectSymbols(R))
    rule collectSymbols(UniformExpr(A, B)) => union(collectSymbols(A), collectSymbols(B))

    rule collectSymbolsList(.ExprList) => .SymSet
    rule collectSymbolsList(E , ES) => union(collectSymbols(E), collectSymbolsList(ES))

    rule union(.SymSet, S2) => S2
    rule union(N ; S1, S2) => add(N, union(S1, S2))
    rule add(N, .SymSet) => N ; .SymSet
    rule add(N, N ; S) => N ; S
    rule add(N, M ; S) => M ; add(N, S) requires N =/=String M

    rule symbolDecls(.SymSet) => ""
    rule symbolDecls(N ; S) => N +String " = Symbol('" +String N +String "')\n" +String symbolDecls(S)

    rule pythonProgram(E) => symbolDecls(collectSymbols(E)) +String "e = " +String printStr(false, E)
endmodule
