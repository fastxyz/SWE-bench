module MINI-ENUM-FORMAT-SYNTAX
  imports STRING-SYNTAX

  syntax Names ::= String
                 | String "|" Names [right]

  syntax Obj ::= enumNamed(String, String, String)
               | flagNamed(String, Names, String)
               | enumUnnamed(String, String)
               | other(String)

  syntax Exp ::= String
               | objectDescription(Obj)
               | stringifyDefault(String, Obj)
               | dot(String, String)
               | qualifyFlags(String, Names)
               | cleanRepr(String)
               | Exp "+S" Exp [seqstrict, left]

  syntax KResult ::= String
endmodule

module MINI-ENUM-FORMAT
  imports MINI-ENUM-FORMAT-SYNTAX
  imports STRING
  imports BOOL

  configuration <k> $PGM:Exp </k>

  rule <k> objectDescription(enumNamed(C:String, N:String, _R:String))
        => dot(C, N) ... </k>
    requires N =/=String ""

  rule <k> objectDescription(flagNamed(C:String, NS:Names, _R:String))
        => qualifyFlags(C, NS) ... </k>

  rule <k> objectDescription(enumUnnamed(_C:String, R:String))
        => cleanRepr(R) ... </k>

  rule <k> objectDescription(other(R:String))
        => cleanRepr(R) ... </k>

  rule <k> stringifyDefault(Prefix:String, O:Obj)
        => Prefix +S objectDescription(O) ... </k>

  rule <k> dot(C:String, N:String)
        => C +S "." +S N ... </k>

  rule <k> qualifyFlags(C:String, N:String)
        => dot(C, N) ... </k>

  rule <k> qualifyFlags(C:String, N:String "|" REST:Names)
        => dot(C, N) +S "|" +S qualifyFlags(C, REST) ... </k>

  rule <k> cleanRepr(R:String) => R ... </k>

  rule <k> S1:String +S S2:String => S1 +String S2 ... </k>
endmodule
