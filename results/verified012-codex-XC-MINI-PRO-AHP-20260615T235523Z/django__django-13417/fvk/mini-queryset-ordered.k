module QUERYSET-ORDERED-SYNTAX
  imports BOOL-SYNTAX

  // qs(isEmpty, hasExtraOrderBy, hasExplicitOrderBy,
  //    defaultOrderingEnabled, hasMetaOrdering, hasGroupBy)
  syntax QueryState ::= qs(Bool, Bool, Bool, Bool, Bool, Bool)

  syntax OrderSource ::= noOrder | explicitOrder | metaOrder

  syntax Bool ::= ordered(QueryState) [function]
                | compilerOrdered(QueryState) [function]
                | sourceOrdered(OrderSource, Bool) [function]
                | grouped(QueryState) [function]
  syntax OrderSource ::= compilerSource(QueryState) [function]
endmodule

module QUERYSET-ORDERED
  imports QUERYSET-ORDERED-SYNTAX
  imports BOOL

  configuration <k> $PGM:Bool </k>

  // V1 QuerySet.ordered semantics.
  rule ordered(qs(true, EXTRA:Bool, EXPLICIT:Bool, DEFAULT:Bool, META:Bool, GROUPED:Bool))
    => true
  rule ordered(qs(false, true, EXPLICIT:Bool, DEFAULT:Bool, META:Bool, GROUPED:Bool))
    => true
  rule ordered(qs(false, false, true, DEFAULT:Bool, META:Bool, GROUPED:Bool))
    => true
  rule ordered(qs(false, false, false, DEFAULT:Bool, META:Bool, GROUPED:Bool))
    => DEFAULT andBool META andBool notBool GROUPED

  // Compiler-derived semantic ordering model:
  // extra_order_by and explicit query.order_by are preserved; Meta.ordering is
  // selected only as a default source and is suppressed when GROUP BY is active.
  rule grouped(qs(EMPTY:Bool, EXTRA:Bool, EXPLICIT:Bool, DEFAULT:Bool, META:Bool, GROUPED:Bool))
    => GROUPED

  rule compilerSource(qs(false, true, EXPLICIT:Bool, DEFAULT:Bool, META:Bool, GROUPED:Bool))
    => explicitOrder
  rule compilerSource(qs(false, false, true, DEFAULT:Bool, META:Bool, GROUPED:Bool))
    => explicitOrder
  rule compilerSource(qs(false, false, false, DEFAULT:Bool, META:Bool, GROUPED:Bool))
    => metaOrder
    requires DEFAULT andBool META
  rule compilerSource(qs(false, false, false, DEFAULT:Bool, META:Bool, GROUPED:Bool))
    => noOrder
    requires notBool (DEFAULT andBool META)

  rule sourceOrdered(explicitOrder, GROUPED:Bool) => true
  rule sourceOrdered(metaOrder, GROUPED:Bool) => notBool GROUPED
  rule sourceOrdered(noOrder, GROUPED:Bool) => false

  rule compilerOrdered(qs(true, EXTRA:Bool, EXPLICIT:Bool, DEFAULT:Bool, META:Bool, GROUPED:Bool))
    => true
  rule compilerOrdered(qs(false, EXTRA:Bool, EXPLICIT:Bool, DEFAULT:Bool, META:Bool, GROUPED:Bool))
    => sourceOrdered(
        compilerSource(qs(false, EXTRA, EXPLICIT, DEFAULT, META, GROUPED)),
        GROUPED
       )
endmodule
