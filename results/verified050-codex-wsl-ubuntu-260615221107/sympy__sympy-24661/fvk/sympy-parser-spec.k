// Constructed, not machine-checked.
// SPEC-PROVENANCE:
// - from_prompt: "parse_expr('1 < 2', evaluate=False)" should return
//   "Lt(1, 2, evaluate=False)" => supported comparison syntax must be
//   converted to an unevaluated SymPy relational constructor.
// - from_prompt: "sympify function calls parse_expr if it is given a string"
//   => the parser claim also covers the sympify string path.
// - from_code: EvaluateFalseTransformer.visit_Compare dispatches on
//   ast.Compare operator classes and constructs ast.Call nodes.

requires "mini-sympy-parser.k"

module SYMPY-PARSER-SPEC
  imports MINI-SYMPY-PARSER

  claim <k> visitCompare(Compare(Leaf("1"), LtOp , .Ops, Leaf("2"), .Exps))
        => RelCall("Lt", Leaf("1"), Leaf("2"), false) ... </k>

  claim <k> visitCompare(Compare(Leaf("x"), LtEOp , .Ops, Leaf("y"), .Exps))
        => RelCall("Le", Leaf("x"), Leaf("y"), false) ... </k>

  claim <k> visitCompare(Compare(Leaf("x"), EqOp , .Ops, Leaf("y"), .Exps))
        => RelCall("Eq", Leaf("x"), Leaf("y"), false) ... </k>

  claim <k> visitCompare(Compare(Leaf("x"), LtOp , LtOp , .Ops,
                                 Leaf("y"), Leaf("z"), .Exps))
        => AndCall(pairwise(Leaf("x"), LtOp , LtOp , .Ops,
                            Leaf("y"), Leaf("z"), .Exps),
                   false) ... </k>
endmodule
