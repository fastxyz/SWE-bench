module MINI-QUANTITY-INPUT-SYNTAX
  imports STRING-SYNTAX
  imports BOOL-SYNTAX

  syntax Ann ::= emptyAnn
               | noneAnn
               | unitAnn(String)

  syntax Ret ::= noneRet
               | quantity(String)
               | objectRet(String)

  syntax Outcome ::= returned(Ret)
                   | converted(Ret, Ann)
                   | attrError(String)

  syntax KItem ::= wrapper(Ann, Ret)
                 | buggyWrapper(Ann, Ret)
                 | to(Ret, Ann)

  syntax Bool ::= shouldConvert(Ann) [function]
  syntax KResult ::= Outcome
endmodule

module MINI-QUANTITY-INPUT
  imports MINI-QUANTITY-INPUT-SYNTAX
  imports BOOL
  imports STRING

  configuration <k> $PGM:K </k>

  rule shouldConvert(emptyAnn) => false
  rule shouldConvert(noneAnn) => false
  rule shouldConvert(unitAnn(_:String)) => true

  // V1 behavior: convert only when the annotation is present and not None.
  rule <k> wrapper(A:Ann, R:Ret) => to(R, A) ... </k>
    requires shouldConvert(A) ==Bool true
  rule <k> wrapper(A:Ann, R:Ret) => returned(R) ... </k>
    requires shouldConvert(A) ==Bool false

  // Pre-fix behavior: every non-empty return annotation requested conversion.
  rule <k> buggyWrapper(emptyAnn, R:Ret) => returned(R) ... </k>
  rule <k> buggyWrapper(noneAnn, R:Ret) => to(R, noneAnn) ... </k>
  rule <k> buggyWrapper(unitAnn(U:String), R:Ret) => to(R, unitAnn(U)) ... </k>

  // Abstract .to behavior relevant to this issue.
  rule <k> to(noneRet, _:Ann) => attrError("NoneType.to") ... </k>
  rule <k> to(quantity(_:String), unitAnn(TO:String))
        => converted(quantity(TO), unitAnn(TO)) ... </k>
  rule <k> to(objectRet(NAME:String), unitAnn(_:String))
        => attrError(NAME) ... </k>
  rule <k> to(quantity(_:String), noneAnn) => attrError("bad-annotation") ... </k>
  rule <k> to(objectRet(NAME:String), noneAnn) => attrError(NAME) ... </k>
endmodule
