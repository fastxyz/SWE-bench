requires "domains.md"

module MINI-PYTHON-ROUTER-SYNTAX
  imports BOOL-SYNTAX
  imports STRING-SYNTAX
  imports LIST-SYNTAX

  syntax App
  syntax Model
  syntax Pair ::= pair(String, String)
  syntax KItem ::= emitNewPairs(List)
                 | emitOldPairs(List)
endmodule

module MINI-PYTHON-ROUTER
  imports MINI-PYTHON-ROUTER-SYNTAX
  imports BOOL
  imports STRING
  imports LIST

  configuration <k> $PGM:K </k>

  syntax String ::= appLabel(App) [function]
  syntax String ::= objectName(Model) [function]
  syntax List ::= appModels(App) [function]
  syntax List ::= allModels(List) [function]

  syntax List ::= newPairs(List) [function]
  syntax List ::= oldPairs(List) [function]
  syntax List ::= oldPairsWith(List, List) [function]
  syntax List ::= pairsFor(String, List) [function]

  syntax Bool ::= validPair(List, Pair) [function]
  syntax Bool ::= allValid(List, List) [function]
  syntax Bool ::= containsPair(List, Pair) [function]
  syntax Bool ::= modelNameIn(String, List) [function]
  syntax Bool ::= allowed(String, Pair) [function]
  syntax Bool ::= anyAllowed(String, List) [function]

  rule <k> emitNewPairs(APPS) => newPairs(APPS) ... </k>
  rule <k> emitOldPairs(APPS) => oldPairs(APPS) ... </k>

  rule newPairs(.List) => .List
  rule newPairs(ListItem(A:App) REST:List)
    => pairsFor(appLabel(A), appModels(A)) newPairs(REST)

  rule oldPairs(APPS) => oldPairsWith(APPS, allModels(APPS))
  rule oldPairsWith(.List, ALL:List) => .List
  rule oldPairsWith(ListItem(A:App) REST:List, ALL:List)
    => pairsFor(appLabel(A), ALL) oldPairsWith(REST, ALL)

  rule allModels(.List) => .List
  rule allModels(ListItem(A:App) REST:List) => appModels(A) allModels(REST)

  rule pairsFor(L, .List) => .List
  rule pairsFor(L, ListItem(M:Model) REST:List)
    => ListItem(pair(L, objectName(M))) pairsFor(L, REST)

  rule validPair(.List, P:Pair) => false
  rule validPair(ListItem(A:App) REST:List, pair(L, MN))
    => ((L ==String appLabel(A)) andBool modelNameIn(MN, appModels(A)))
       orBool validPair(REST, pair(L, MN))

  rule allValid(APPS, .List) => true
  rule allValid(APPS, ListItem(P:Pair) REST:List)
    => validPair(APPS, P) andBool allValid(APPS, REST)

  rule modelNameIn(MN, .List) => false
  rule modelNameIn(MN, ListItem(M:Model) REST:List)
    => (MN ==String objectName(M)) orBool modelNameIn(MN, REST)

  rule anyAllowed(ALIAS, .List) => false
  rule anyAllowed(ALIAS, ListItem(P:Pair) REST:List)
    => allowed(ALIAS, P) orBool anyAllowed(ALIAS, REST)
endmodule
