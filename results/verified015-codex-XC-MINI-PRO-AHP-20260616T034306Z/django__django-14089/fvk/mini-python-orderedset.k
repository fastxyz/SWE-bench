module MINI-PYTHON-ORDEREDSET-SYNTAX
  imports INT-SYNTAX
  imports LIST-SYNTAX

  syntax OSet ::= os(List)

  syntax Exp ::= "OrderedSet(" List ")" [strict]
               | "iter(" Exp ")" [strict]
               | "reversed(" Exp ")" [strict]
               | "list(" Exp ")" [strict]

  syntax KResult ::= Int | List | OSet
endmodule

module MINI-PYTHON-ORDEREDSET
  imports MINI-PYTHON-ORDEREDSET-SYNTAX
  imports INT
  imports BOOL
  imports LIST

  configuration <k> $PGM:Exp </k>

  syntax List ::= uniqueFirst(List) [function]
                | removeAll(Int, List) [function]
                | reverseList(List) [function]
                | reverseAcc(List, List) [function]
                | dictFromKeys(List) [function]
                | dictReversedKeys(List) [function]

  rule uniqueFirst(.List) => .List
  rule uniqueFirst(ListItem(X:Int) XS:List) => ListItem(X) uniqueFirst(removeAll(X, XS))

  rule removeAll(_:Int, .List) => .List
  rule removeAll(X:Int, ListItem(X) XS:List) => removeAll(X, XS)
  rule removeAll(X:Int, ListItem(Y:Int) XS:List) => ListItem(Y) removeAll(X, XS)
    requires X =/=Int Y

  rule reverseList(XS:List) => reverseAcc(XS, .List)
  rule reverseAcc(.List, ACC:List) => ACC
  rule reverseAcc(ListItem(X:Int) XS:List, ACC:List) => reverseAcc(XS, ListItem(X) ACC)

  rule dictFromKeys(XS:List) => uniqueFirst(XS)
  rule dictReversedKeys(KS:List) => reverseList(KS)

  rule <k> OrderedSet(XS:List) => os(dictFromKeys(XS)) </k>
  rule <k> iter(os(KS:List)) => KS </k>
  rule <k> reversed(os(KS:List)) => dictReversedKeys(KS) </k>
  rule <k> list(XS:List) => XS </k>
endmodule
