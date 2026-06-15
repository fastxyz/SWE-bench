module MINI-PYTHON-ENUM-SERIALIZER-SYNTAX
  imports STRING-SYNTAX

  syntax Value ::= valueToken(String)
  syntax EnumMember ::= enumMember(String, String, String, Value)
  syntax ImportSet ::= importSet(String)
  syntax Result ::= serializeResult(String, ImportSet)
  syntax KItem ::= serializeEnum(EnumMember)
endmodule

module MINI-PYTHON-ENUM-SERIALIZER
  imports MINI-PYTHON-ENUM-SERIALIZER-SYNTAX
  imports STRING

  configuration <k> $PGM:KItem </k>

  syntax String ::= enumLookupExpr(String, String, String) [function]
  rule enumLookupExpr(M:String, C:String, N:String)
    => M +String "." +String C +String "[" +String reprString(N) +String "]"

  syntax String ::= reprString(String) [function]
  rule reprString(S:String) => "'" +String S +String "'"

  rule
    <k> serializeEnum(enumMember(M, C, N, _V))
      => serializeResult(enumLookupExpr(M, C, N), importSet("import " +String M))
    </k>
endmodule
