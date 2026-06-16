requires "domains.md"

module MINI-DJANGO-PREFETCH-SYNTAX
  imports INT
  imports BOOL

  syntax MaybeInt ::= "none" | "some" "(" Int ")"
  syntax Order ::= "emptyOrder" | "resolvedOrder" | "pkOrder"
  syntax Key ::= "fkKey" | "m2mKey" | "genericKey"
  syntax Predicate ::= "relPred"
                     | "corePred"
                     | "rankGt" "(" Int ")"
                     | "rankLte" "(" Int ")"
                     | Predicate "andP" Predicate [left]
  syntax Query ::= query(Bool, Int, MaybeInt, Order, Bool)
  syntax Result ::= ok(Query, Predicate, Order) | errorNotSupported
  syntax Result ::= filterPrefetch(Query, Predicate, Key) [function]
  syntax Order ::= normalizeOrder(Order) [function]
endmodule

module MINI-DJANGO-PREFETCH
  imports MINI-DJANGO-PREFETCH-SYNTAX
  imports INT
  imports BOOL

  rule normalizeOrder(emptyOrder) => pkOrder
  rule normalizeOrder(O) => O [owise]

  rule filterPrefetch(query(false, L, H, O, SUPPORTS), P, K)
    => ok(query(false, L, H, O, SUPPORTS), P, O)

  rule filterPrefetch(query(true, L, H, O, false), P, K)
    => errorNotSupported

  rule filterPrefetch(query(true, L, none, O, true), P, K)
    => ok(
         query(false, 0, none, normalizeOrder(O), true),
         P andP rankGt(L),
         normalizeOrder(O)
       )

  rule filterPrefetch(query(true, L, some(H), O, true), P, K)
    => ok(
         query(false, 0, none, normalizeOrder(O), true),
         P andP rankGt(L) andP rankLte(H),
         normalizeOrder(O)
       )
endmodule
