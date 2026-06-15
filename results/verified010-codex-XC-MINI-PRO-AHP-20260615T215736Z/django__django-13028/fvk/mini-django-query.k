module MINI-DJANGO-QUERY-SYNTAX
  imports BOOL-SYNTAX
  imports LIST-SYNTAX

  syntax Obj ::= obj(Bool, Bool, Bool, List)
  syntax Result ::= ok | notSupported
  syntax KItem ::= checkFilterable(Obj)
                 | checkSources(List)
  syntax KResult ::= Result
endmodule

module MINI-DJANGO-QUERY
  imports MINI-DJANGO-QUERY-SYNTAX
  imports BOOL
  imports LIST

  configuration <k> $PGM:K </k>

  // Non-expressions are ordinary RHS values and are outside the filterable
  // expression contract.
  rule <k> checkFilterable(obj(false, FILTERABLE:Bool, HAS_SOURCES:Bool, SOURCES:List)) => ok ... </k>

  // Real expressions marked non-filterable are rejected.
  rule <k> checkFilterable(obj(true, false, HAS_SOURCES:Bool, SOURCES:List)) => notSupported ... </k>

  // Filterable expressions without a source-expression walk are accepted.
  rule <k> checkFilterable(obj(true, true, false, SOURCES:List)) => ok ... </k>

  // Filterable expressions with sources validate those sources recursively.
  rule <k> checkFilterable(obj(true, true, true, SOURCES:List)) => checkSources(SOURCES) ... </k>
  rule <k> checkSources(.List) => ok ... </k>
  rule <k> checkSources(ListItem(SRC:Obj) REST:List) => checkFilterable(SRC) ~> checkSources(REST) ... </k>
  rule <k> ok ~> checkSources(REST:List) => checkSources(REST) ... </k>
  rule <k> notSupported ~> checkSources(REST:List) => notSupported ... </k>
endmodule
