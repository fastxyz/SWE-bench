module MINI-DJANGO-AGGREGATE-SYNTAX
  imports BOOL-SYNTAX
  imports STRING-SYNTAX

  syntax String ::= distinctMarker(Bool)                         [function]
                  | aggregateSql(Bool, String, String)           [function]
                  | aggregateFilterSql(Bool, String, String, String) [function]
                  | filterFallbackSql(Bool, String, String, String)  [function]
                  | caseExpr(String, String)                     [function]
endmodule

module MINI-DJANGO-AGGREGATE
  imports MINI-DJANGO-AGGREGATE-SYNTAX
  imports BOOL
  imports STRING

  configuration <k> $PGM:String </k>

  rule distinctMarker(true) => "DISTINCT "
  rule distinctMarker(false) => ""

  rule aggregateSql(D:Bool, F:String, E:String)
    => F +String "(" +String distinctMarker(D) +String E +String ")"

  rule aggregateFilterSql(D:Bool, F:String, E:String, FILTER:String)
    => aggregateSql(D, F, E) +String " FILTER (WHERE " +String FILTER +String ")"

  rule caseExpr(FILTER:String, E:String)
    => "CASE WHEN " +String FILTER +String " THEN " +String E +String " ELSE NULL END"

  rule filterFallbackSql(D:Bool, F:String, E:String, FILTER:String)
    => aggregateSql(D, F, caseExpr(FILTER, E))
endmodule
