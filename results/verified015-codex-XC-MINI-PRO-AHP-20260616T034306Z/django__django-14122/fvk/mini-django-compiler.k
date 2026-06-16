module MINI-DJANGO-COMPILER-SYNTAX
  imports BOOL-SYNTAX

  syntax GroupState ::= noGroup | grouped
  syntax Source ::= noSource | metaSource | explicitSource | extraSource

  // query(EXTRA, DEFAULT, QUERY_ORDER, META_ORDER, GROUP, DISTINCT, DISTINCT_FIELDS)
  syntax QueryState ::= query(Bool, Bool, Bool, Bool, GroupState, Bool, Bool)

  // result(SOURCE, ORDER_BY_HAS_META, EXTRA_SELECT_HAS_META, GROUP_BY_HAS_META, ORDERED_PROPERTY)
  syntax CompilerResult ::= result(Source, Bool, Bool, Bool, Bool)
  syntax CompilerResult ::= compile(QueryState)

  syntax KResult ::= CompilerResult
endmodule

module MINI-DJANGO-COMPILER
  imports MINI-DJANGO-COMPILER-SYNTAX
  imports BOOL

  configuration <k> $PGM:K </k>

  // extra_order_by has highest precedence and is explicit user input.
  rule <k> compile(query(true, DEFAULT:Bool, QUERY:Bool, META:Bool, GROUP:GroupState, DISTINCT:Bool, DISTINCT_FIELDS:Bool))
        => result(extraSource, false, false, false, true) ... </k>

  // query.order_by is explicit user input and is preserved for grouped queries.
  rule <k> compile(query(false, DEFAULT:Bool, true, META:Bool, GROUP:GroupState, DISTINCT:Bool, DISTINCT_FIELDS:Bool))
        => result(explicitSource, false, false, false, true) ... </k>

  // default_ordering disabled and no explicit order_by means no ordering source.
  rule <k> compile(query(false, false, false, META:Bool, GROUP:GroupState, DISTINCT:Bool, DISTINCT_FIELDS:Bool))
        => result(noSource, false, false, false, false) ... </k>

  // Default Meta.ordering is selected only when query.group_by is None.
  rule <k> compile(query(false, true, false, true, noGroup, DISTINCT:Bool, DISTINCT_FIELDS:Bool))
        => result(metaSource, true, DISTINCT andBool notBool DISTINCT_FIELDS, false, true) ... </k>

  // The fixed grouped-query case: metadata ordering is not selected.
  rule <k> compile(query(false, true, false, true, grouped, DISTINCT:Bool, DISTINCT_FIELDS:Bool))
        => result(noSource, false, false, false, false) ... </k>

  // No model metadata ordering means no default ordering source.
  rule <k> compile(query(false, true, false, false, GROUP:GroupState, DISTINCT:Bool, DISTINCT_FIELDS:Bool))
        => result(noSource, false, false, false, false) ... </k>
endmodule
