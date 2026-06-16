module MINI-RELATED-MANAGER-SYNTAX
  imports BOOL-SYNTAX

  syntax Manager ::= reverseFK | manyToMany | genericRel | plain
  syntax Op ::= create | getOrCreate | updateOrCreate
  syntax ThroughDefaults ::= noThroughDefaults | throughDefaults

  syntax Exp ::= invokeAsync(Manager, Op, ThroughDefaults)
               | localAsync(Manager, Op, ThroughDefaults)
               | syncRelated(Manager, Op, ThroughDefaults)
               | querysetProxy(Op, ThroughDefaults)
               | checkAltersData(Manager, Op)

  syntax Result ::= reverseFkEffect(Op)
                  | manyToManyEffect(Op, ThroughDefaults)
                  | genericEffect(Op)
                  | querysetProxyEffect(Op)

  syntax KResult ::= Result | Bool

  syntax Bool ::= isRelated(Manager) [function]
endmodule

module MINI-RELATED-MANAGER
  imports MINI-RELATED-MANAGER-SYNTAX
  imports BOOL

  configuration <k> $PGM:Exp </k>

  rule isRelated(reverseFK) => true
  rule isRelated(manyToMany) => true
  rule isRelated(genericRel) => true
  rule isRelated(plain) => false

  // V1 local async wrappers on related managers.
  rule <k> invokeAsync(M:Manager, O:Op, T:ThroughDefaults)
        => localAsync(M, O, T) ... </k>
    requires isRelated(M)

  // Existing queryset proxy behavior remains for plain managers.
  rule <k> invokeAsync(plain, O:Op, T:ThroughDefaults)
        => querysetProxy(O, T) ... </k>

  // The async wrapper delegates to the corresponding sync related method.
  rule <k> localAsync(M:Manager, O:Op, T:ThroughDefaults)
        => syncRelated(M, O, T) ... </k>
    requires isRelated(M)

  // Sync related methods provide the relation-specific observable effects.
  rule <k> syncRelated(reverseFK, O:Op, T:ThroughDefaults)
        => reverseFkEffect(O) ... </k>
  rule <k> syncRelated(manyToMany, O:Op, T:ThroughDefaults)
        => manyToManyEffect(O, T) ... </k>
  rule <k> syncRelated(genericRel, O:Op, T:ThroughDefaults)
        => genericEffect(O) ... </k>

  // Copied manager proxy observable.
  rule <k> querysetProxy(O:Op, T:ThroughDefaults)
        => querysetProxyEffect(O) ... </k>

  // Mutating async wrappers are marked with alters_data.
  rule <k> checkAltersData(M:Manager, O:Op) => true ... </k>
    requires isRelated(M)
  rule <k> checkAltersData(plain, O:Op) => false ... </k>
endmodule
