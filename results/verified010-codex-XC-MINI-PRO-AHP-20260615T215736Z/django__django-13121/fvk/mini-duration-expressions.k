module MINI-DURATION-EXPRESSIONS-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX

  syntax Connector ::= add | sub | mul
  syntax FieldKind ::= duration | date | datetime | time | other
  syntax Expr ::= durValue(Int)
                | col(FieldKind)
                | bin(Connector, Expr, Expr)
  syntax Sql ::= raw(Expr)
               | stored(Int)
               | formatted(Sql)
               | interval(Int)
               | numeric(Connector, Sql, Sql)
               | durationFn(Connector, Sql, Sql)
  syntax KResult ::= Sql | Bool | FieldKind

  syntax Bool ::= isAddSub(Connector) [function]
                | isTemporalKind(FieldKind) [function]
                | isDurationValue(Expr) [function]
                | hasDurationOutput(Expr) [function]
  syntax FieldKind ::= outputKind(Expr) [function]
  syntax Sql ::= compileRaw(Expr) [function]
               | compileStored(Expr) [function]
               | compileMixed(Expr) [function]
               | compileDurationExpression(Connector, Expr, Expr) [function]
endmodule

module MINI-DURATION-EXPRESSIONS
  imports MINI-DURATION-EXPRESSIONS-SYNTAX
  imports INT
  imports BOOL
  imports K-EQUAL

  configuration <k> $PGM:Sql </k>

  rule isAddSub(add) => true
  rule isAddSub(sub) => true
  rule isAddSub(mul) => false

  rule isTemporalKind(date) => true
  rule isTemporalKind(datetime) => true
  rule isTemporalKind(time) => true
  rule isTemporalKind(duration) => false
  rule isTemporalKind(other) => false

  rule isDurationValue(durValue(_:Int)) => true
  rule isDurationValue(col(_:FieldKind)) => false
  rule isDurationValue(bin(_:Connector, _:Expr, _:Expr)) => false

  rule outputKind(durValue(_:Int)) => duration
  rule outputKind(col(K:FieldKind)) => K
  rule outputKind(bin(sub, L:Expr, R:Expr)) => duration
    requires isTemporalKind(outputKind(L)) andBool outputKind(L) ==K outputKind(R)
  rule outputKind(bin(C:Connector, L:Expr, R:Expr)) => duration
    requires isAddSub(C)
     andBool outputKind(L) ==K duration
     andBool outputKind(R) ==K duration
  rule outputKind(bin(_:Connector, _:Expr, _:Expr)) => other [owise]

  rule hasDurationOutput(E:Expr) => outputKind(E) ==K duration

  rule compileRaw(durValue(I:Int)) => interval(I)
  rule compileRaw(E:Expr) => raw(E) [owise]

  rule compileStored(durValue(I:Int)) => stored(I)
  rule compileStored(E:Expr) => compileRaw(E) [owise]

  rule compileMixed(E:Expr) => compileRaw(E)
    requires isDurationValue(E)
  rule compileMixed(E:Expr) => formatted(compileRaw(E))
    requires hasDurationOutput(E) andBool notBool isDurationValue(E)
  rule compileMixed(E:Expr) => compileRaw(E)
    requires notBool hasDurationOutput(E)

  rule compileDurationExpression(C:Connector, L:Expr, R:Expr)
    => numeric(C, compileStored(L), compileStored(R))
    requires isAddSub(C)
     andBool hasDurationOutput(L)
     andBool hasDurationOutput(R)
  rule compileDurationExpression(C:Connector, L:Expr, R:Expr)
    => durationFn(C, compileMixed(L), compileMixed(R))
    [owise]
endmodule
