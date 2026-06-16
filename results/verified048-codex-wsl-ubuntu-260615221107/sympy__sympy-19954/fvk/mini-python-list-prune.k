requires "domains.md"

module MINI-PYTHON-LIST-PRUNE-SYNTAX
  imports INT
  imports BOOL
  imports LIST

  syntax Stmt ::= pruneDeletes(List)
                | deleteLoop(List)
                | done()
endmodule

module MINI-PYTHON-LIST-PRUNE
  imports MINI-PYTHON-LIST-PRUNE-SYNTAX
  imports INT
  imports BOOL
  imports LIST

  configuration
    <k> $PGM:Stmt </k>
    <blocks> .List </blocks>
    <numBlocks> .List </numBlocks>
    <repBlocks> .List </repBlocks>

  syntax Int ::= size(List) [function, total]
  rule size(.List) => 0
  rule size(ListItem(_) REST) => 1 +Int size(REST)

  syntax Bool ::= validIndex(Int, List) [function, total]
  rule validIndex(I, L) => 0 <=Int I andBool I <Int size(L)

  syntax Bool ::= sameLength3(List, List, List) [function, total]
  rule sameLength3(A, B, C) => size(A) ==Int size(B) andBool size(B) ==Int size(C)

  syntax Bool ::= indicesInRange(List, Int) [function, total]
  rule indicesInRange(.List, _) => true
  rule indicesInRange(ListItem(I) REST, N)
    => 0 <=Int I andBool I <Int N andBool indicesInRange(REST, N)

  syntax Bool ::= strictAscending(List) [function, total]
  syntax Bool ::= strictAscendingFrom(List, Int) [function, total]
  rule strictAscending(.List) => true
  rule strictAscending(ListItem(I) REST) => strictAscendingFrom(REST, I)
  rule strictAscendingFrom(.List, _) => true
  rule strictAscendingFrom(ListItem(I) REST, PREV)
    => PREV <Int I andBool strictAscendingFrom(REST, I)

  syntax Bool ::= descendingIndicesSafe(List, Int) [function, total]
  rule descendingIndicesSafe(.List, _) => true
  rule descendingIndicesSafe(ListItem(I) REST, N)
    => 0 <=Int I andBool I <Int N
       andBool descendingIndicesSafe(REST, N -Int 1)

  syntax List ::= reverse(List) [function, total]
  syntax List ::= reverseAcc(List, List) [function, total]
  rule reverse(L) => reverseAcc(L, .List)
  rule reverseAcc(.List, ACC) => ACC
  rule reverseAcc(ListItem(I) REST, ACC) => reverseAcc(REST, ListItem(I) ACC)

  syntax List ::= deleteAt(List, Int) [function, total]
  rule deleteAt(ListItem(_) REST, 0) => REST
  rule deleteAt(ListItem(X) REST, I) => ListItem(X) deleteAt(REST, I -Int 1)
    requires I >Int 0

  syntax List ::= deleteManyDescending(List, List) [function, total]
  rule deleteManyDescending(L, .List) => L
  rule deleteManyDescending(L, ListItem(I) REST)
    => deleteManyDescending(deleteAt(L, I), REST)

  rule <k> pruneDeletes(IS) => deleteLoop(reverse(IS)) </k>

  rule <k> deleteLoop(ListItem(I) REST) => deleteLoop(REST) </k>
       <blocks> BS => deleteAt(BS, I) </blocks>
       <numBlocks> NS => deleteAt(NS, I) </numBlocks>
       <repBlocks> RS => deleteAt(RS, I) </repBlocks>
    requires validIndex(I, BS)
     andBool validIndex(I, NS)
     andBool validIndex(I, RS)

  rule <k> deleteLoop(.List) => done() </k>
endmodule
