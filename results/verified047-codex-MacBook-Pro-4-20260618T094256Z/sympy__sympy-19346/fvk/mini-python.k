module MINI-PYTHON-SYNTAX
  imports STRING-SYNTAX

  syntax Val ::= Sym(String)
               | PyStr(String)
               | PyList(Vals)
               | PyTuple(Vals)
               | PySet(Vals)
               | PyFrozenSet(Vals)
               | PyDict(Pairs)
               | SymDict(Pairs)

  syntax Vals ::= ".Vals" [klabel(.Vals)]
                | Val "::" Vals [right, klabel(valsCons)]

  syntax Pair ::= pair(Val, Val)
  syntax Pairs ::= ".Pairs" [klabel(.Pairs)]
                 | Pair "::" Pairs [right, klabel(pairsCons)]

  syntax KItem ::= srepr(Val)

  syntax String ::= reprOf(Val) [function]
                  | reprSeq(Vals) [function]
                  | reprPairs(Pairs) [function]

  syntax Vals ::= sortVals(Vals) [function]
  syntax Pairs ::= sortPairs(Pairs) [function]

  syntax KResult ::= String
endmodule

module MINI-PYTHON
  imports MINI-PYTHON-SYNTAX
  imports STRING

  configuration <k> $PGM:K </k>

  // Public wrapper: sympy.printing.repr.srepr delegates to ReprPrinter.doprint.
  rule <k> srepr(V:Val) => reprOf(V) ... </k>

  // Atomic fragment needed by the issue examples.
  rule reprOf(Sym(S:String)) => "Symbol('" +String S +String "')"
  rule reprOf(PyStr(S:String)) => "'" +String S +String "'"

  // Existing recursive list/tuple behavior used as the regression frame.
  rule reprOf(PyList(VS:Vals)) => "[" +String reprSeq(VS) +String "]"
  rule reprOf(PyTuple(.Vals)) => "()"
  rule reprOf(PyTuple(V:Val :: .Vals)) => "(" +String reprOf(V) +String ",)"
  rule reprOf(PyTuple(V1:Val :: V2:Val :: VS:Vals))
    => "(" +String reprSeq(V1 :: V2 :: VS) +String ")"

  // V1 behavior for Python set/frozenset/dict and SymPy Dict.
  rule reprOf(PySet(.Vals)) => "set()"
  rule reprOf(PySet(V:Val :: VS:Vals))
    => "{" +String reprSeq(sortVals(V :: VS)) +String "}"
  rule reprOf(PyFrozenSet(.Vals)) => "frozenset()"
  rule reprOf(PyFrozenSet(V:Val :: VS:Vals))
    => "frozenset(" +String reprOf(PySet(V :: VS)) +String ")"
  rule reprOf(PyDict(PS:Pairs))
    => "{" +String reprPairs(sortPairs(PS)) +String "}"
  rule reprOf(SymDict(PS:Pairs))
    => "Dict(" +String reprOf(PyDict(PS)) +String ")"

  // Recursive sequence helpers model reprify and _print_dict's item loop.
  rule reprSeq(.Vals) => ""
  rule reprSeq(V:Val :: .Vals) => reprOf(V)
  rule reprSeq(V1:Val :: V2:Val :: VS:Vals)
    => reprOf(V1) +String ", " +String reprSeq(V2 :: VS)

  rule reprPairs(.Pairs) => ""
  rule reprPairs(pair(K:Val, V:Val) :: .Pairs)
    => reprOf(K) +String ": " +String reprOf(V)
  rule reprPairs(pair(K:Val, V:Val) :: P2:Pair :: PS:Pairs)
    => reprOf(K) +String ": " +String reprOf(V) +String ", " +String reprPairs(P2 :: PS)

  // default_sort_key is represented abstractly. Concrete x/y rules let the
  // issue examples reduce; general claims preserve sortVals/sortPairs in the
  // postcondition.
  rule sortVals(.Vals) => .Vals
  rule sortVals(V:Val :: .Vals) => V :: .Vals
  rule sortVals(Sym("x") :: Sym("y") :: .Vals) => Sym("x") :: Sym("y") :: .Vals
  rule sortVals(Sym("y") :: Sym("x") :: .Vals) => Sym("x") :: Sym("y") :: .Vals

  rule sortPairs(.Pairs) => .Pairs
  rule sortPairs(P:Pair :: .Pairs) => P :: .Pairs
endmodule
