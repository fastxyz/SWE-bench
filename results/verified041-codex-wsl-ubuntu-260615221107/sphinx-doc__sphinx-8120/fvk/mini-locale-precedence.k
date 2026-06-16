module MINI-LOCALE-PRECEDENCE-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX
  imports STRING-SYNTAX
  imports LIST-SYNTAX

  syntax Source ::= project(Int) | system | package
  syntax Val ::= val(Source, String) | missing

  syntax KItem ::= initI18n(List)
                 | resolve(String)
                 | scan(List, String)

  syntax Bool ::= has(Source, String) [function]
  syntax KResult ::= Val
endmodule

module MINI-LOCALE-PRECEDENCE
  imports MINI-LOCALE-PRECEDENCE-SYNTAX
  imports BOOL
  imports LIST

  configuration
    <k> $PGM:KItem </k>
    <order> .List </order>
    <out> missing </out>

  // V1 _init_i18n order: yielded project locale dirs first, then the
  // pre-existing built-in fallback order: system gettext location, package.
  rule <k> initI18n(USERDIRS:List) => .K ... </k>
       <order> _ => USERDIRS ListItem(system) ListItem(package) </order>

  rule <k> resolve(M:String) => scan(ORDER, M) ... </k>
       <order> ORDER </order>

  rule <k> scan(ListItem(S:Source) REST:List, M:String) => .K ... </k>
       <out> _ => val(S, M) </out>
    requires has(S, M)

  rule <k> scan(ListItem(S:Source) REST:List, M:String) => scan(REST, M) ... </k>
    requires notBool has(S, M)

  rule <k> scan(.List, M:String) => .K ... </k>
       <out> _ => missing </out>
endmodule
