module MINI-DJANGO-QUERYSET-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX

  syntax Row ::= row(Int)
  syntax Rows ::= ".Rows"
                | Row "," Rows [right]
  syntax QuerySet ::= qs(Rows)
  syntax Limit ::= limit(Int)
  syntax KItem ::= applyLimit(QuerySet, Limit)
  syntax KResult ::= QuerySet
endmodule

module MINI-DJANGO-QUERYSET
  imports MINI-DJANGO-QUERYSET-SYNTAX
  imports INT
  imports BOOL

  configuration <k> $PGM:KItem </k>

  // Abstract predicates supplied by the spec model.
  syntax Bool ::= qualifies(Limit, Row) [function]
  syntax Bool ::= uniquePks(Rows) [function]
  syntax Rows ::= existsFilter(Rows, Limit) [function]

  rule existsFilter(.Rows, L:Limit) => .Rows
  rule existsFilter(R:Row, RS:Rows, L:Limit) => R , existsFilter(RS, L)
    requires qualifies(L, R)
  rule existsFilter(R:Row, RS:Rows, L:Limit) => existsFilter(RS, L)
    requires notBool qualifies(L, R)

  // V1 behavior: apply the limit as a boolean existence predicate on each
  // outer row, not as a join that expands one row per witness.
  rule <k> applyLimit(qs(RS:Rows), L:Limit) => qs(existsFilter(RS, L)) </k>
endmodule
