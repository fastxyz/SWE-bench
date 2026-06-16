module MINI-PYTHON-WHERE-ATTRS-SYNTAX
  imports STRING
  imports BOOL
  imports LIST

  syntax Attrs ::= emptyAttrs() | attrs(String)
  syntax XSource ::= scalar() | xarray(List)
  syntax KItem ::= selectAttrs(XSource, List)
                 | selectFromSources(List, List)
                 | oldSelectSecond(List)
  syntax Bool ::= containsAttrs(Attrs, List) [function]
endmodule

module MINI-PYTHON-WHERE-ATTRS
  imports MINI-PYTHON-WHERE-ATTRS-SYNTAX

  configuration <k> $PGM:K </k>

  rule <k> selectAttrs(scalar(), MERGE) => emptyAttrs() ... </k>
  rule <k> selectAttrs(xarray(XS), MERGE) => selectFromSources(XS, MERGE) ... </k>

  rule <k> selectFromSources(.List, MERGE) => emptyAttrs() ... </k>
  rule <k> selectFromSources(ListItem(A) REST, MERGE) => A ... </k>
       requires containsAttrs(A, MERGE)
  rule <k> selectFromSources(ListItem(A) REST, MERGE) => selectFromSources(REST, MERGE) ... </k>
       requires notBool containsAttrs(A, MERGE)

  rule containsAttrs(A, .List) => false
  rule containsAttrs(A, ListItem(B) REST) => true
       requires A ==K B
  rule containsAttrs(A, ListItem(B) REST) => containsAttrs(A, REST)
       requires A =/=K B

  rule <k> oldSelectSecond(ListItem(A) ListItem(B) REST) => B ... </k>
endmodule
