module MINI-AXIOS-HEADERS-SYNTAX
  imports STRING-SYNTAX

  syntax HVal  ::= falseHeader
                 | nullHeader
                 | str(String)
                 | arr(HVals)

  syntax HVals ::= List{HVal, ","} [klabel(hvals)]

  syntax Command ::= normalizeValue(HVal)
                   | setGet(String, HVal)
                   | normalizeGet(String, HVal)

  syntax KResult ::= HVal
endmodule

module MINI-AXIOS-HEADERS
  imports MINI-AXIOS-HEADERS-SYNTAX

  configuration <k> $PGM:Command </k>

  syntax HVal ::= normalizeValueH(HVal) [function]
  rule normalizeValueH(falseHeader) => falseHeader
  rule normalizeValueH(nullHeader) => nullHeader
  rule normalizeValueH(str(S:String)) => str(S)
  rule normalizeValueH(arr(VS:HVals)) => arr(normalizeValues(VS))

  syntax HVals ::= normalizeValues(HVals) [function]
  rule normalizeValues(.HVals) => .HVals
  rule normalizeValues(V:HVal, VS:HVals) => normalizeValueH(V), normalizeValues(VS)

  syntax HVal ::= storedAfterSet(String, HVal) [function]
  rule storedAfterSet(_H:String, V:HVal) => normalizeValueH(V)

  syntax HVal ::= storedAfterNormalize(HVal) [function]
  rule storedAfterNormalize(V:HVal) => normalizeValueH(V)

  rule <k> normalizeValue(V:HVal) => normalizeValueH(V) ... </k>
  rule <k> setGet(H:String, V:HVal) => storedAfterSet(H, V) ... </k>
  rule <k> normalizeGet(H:String, V:HVal)
        => storedAfterNormalize(storedAfterSet(H, V)) ... </k>
endmodule
