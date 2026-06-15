module MINI-ADMIN-ORDERING-SYNTAX
  imports BOOL-SYNTAX

  syntax FilterKind ::= related | relatedOnly
  syntax Limit      ::= noLimit | pkInLimit
  syntax Ordering   ::= none | emptyTuple | emptyList | adminOrdering | metaOrdering
  syntax AdminState ::= unregistered | registered(Ordering)
  syntax Call       ::= getChoices(FilterKind, Limit, Ordering)
                      | relatedFieldChoices(AdminState, Ordering)
                      | relatedOnlyFieldChoices(AdminState, Ordering)
  syntax Ordering   ::= resolveOrdering(AdminState, Ordering) [function]
  syntax Bool       ::= specifiedOrdering(Ordering) [function]
endmodule

module MINI-ADMIN-ORDERING
  imports MINI-ADMIN-ORDERING-SYNTAX
  imports BOOL

  configuration <k> $PGM:Call </k>

  rule specifiedOrdering(none) => false
  rule specifiedOrdering(emptyTuple) => false
  rule specifiedOrdering(emptyList) => true
  rule specifiedOrdering(adminOrdering) => true
  rule specifiedOrdering(metaOrdering) => true

  rule resolveOrdering(unregistered, M:Ordering) => M
  rule resolveOrdering(registered(O:Ordering), M:Ordering) => O
    requires specifiedOrdering(O)
  rule resolveOrdering(registered(O:Ordering), M:Ordering) => M
    requires notBool specifiedOrdering(O)

  rule <k> relatedFieldChoices(A:AdminState, M:Ordering)
        => getChoices(related, noLimit, resolveOrdering(A, M)) </k>
  rule <k> relatedOnlyFieldChoices(A:AdminState, M:Ordering)
        => getChoices(relatedOnly, pkInLimit, resolveOrdering(A, M)) </k>
endmodule
