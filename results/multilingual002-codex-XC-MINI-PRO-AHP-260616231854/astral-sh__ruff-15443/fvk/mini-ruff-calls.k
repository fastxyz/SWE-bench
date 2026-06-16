requires "domains.md"

module MINI-RUFF-CALLS-SYNTAX
  imports STRING-SYNTAX
  imports BOOL-SYNTAX

  syntax RuleId ::= "S102" | "PTH123"
  syntax QName ::= qname(String, String)
  syntax OpenInfo ::= openInfo(Bool, Bool, Bool)
  syntax Decision ::= "emit" | "noEmit"
  syntax KItem ::= check(RuleId, QName, OpenInfo)
endmodule

module MINI-RUFF-CALLS
  imports MINI-RUFF-CALLS-SYNTAX
  imports STRING
  imports BOOL

  configuration
    <k> $PGM:K </k>
    <decision> noEmit </decision>

  rule <k> check(S102, qname(MOD, "exec"), INFO) => .K </k>
       <decision> _ => emit </decision>
    requires MOD ==String "" orBool MOD ==String "builtins"

  rule <k> check(S102, qname(MOD, "exec"), INFO) => .K </k>
       <decision> _ => noEmit </decision>
    requires notBool (MOD ==String "" orBool MOD ==String "builtins")

  rule <k> check(S102, qname(MOD, NAME), INFO) => .K </k>
       <decision> _ => noEmit </decision>
    requires NAME =/=String "exec"

  rule <k> check(PTH123, qname(MOD, "open"), openInfo(BAD_CLOSEFD, BAD_OPENER, FILE_DESCRIPTOR)) => .K </k>
       <decision> _ => emit </decision>
    requires (MOD ==String "" orBool MOD ==String "builtins")
     andBool BAD_CLOSEFD ==Bool false
     andBool BAD_OPENER ==Bool false
     andBool FILE_DESCRIPTOR ==Bool false

  rule <k> check(PTH123, qname(MOD, "open"), openInfo(BAD_CLOSEFD, BAD_OPENER, FILE_DESCRIPTOR)) => .K </k>
       <decision> _ => noEmit </decision>
    requires notBool (MOD ==String "" orBool MOD ==String "builtins")
      orBool BAD_CLOSEFD
      orBool BAD_OPENER
      orBool FILE_DESCRIPTOR

  rule <k> check(PTH123, qname(MOD, NAME), INFO) => .K </k>
       <decision> _ => noEmit </decision>
    requires NAME =/=String "open"
endmodule
