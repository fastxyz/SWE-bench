module MINI-RUNSERVER-SYNTAX
  imports BOOL-SYNTAX
  imports STRING-SYNTAX

  syntax Port ::= "noPort" | "port" "(" String ")"

  syntax Addr ::= "noAddr"
                | "raw0"
                | "ipv4wild"
                | "defaultIPv4"
                | "defaultIPv6"
                | "ipv4" "(" String ")"
                | "ipv6" "(" String ")"
                | "fqdn" "(" String ")"

  syntax AddrPort ::= "missing"
                    | "portOnly" "(" Port ")"
                    | "addrPort" "(" Addr "," Port ")"

  syntax RunCmd ::= "handle" "(" AddrPort "," Bool ")"
                  | "emit"

  syntax KResult ::= Addr | Port | String | Bool
endmodule

module MINI-RUNSERVER
  imports MINI-RUNSERVER-SYNTAX
  imports BOOL
  imports STRING

  configuration
    <k> $PGM:RunCmd </k>
    <addr> noAddr </addr>
    <port> noPort </port>
    <useIPv6> false </useIPv6>
    <rawIPv6> false </rawIPv6>
    <output> "" </output>

  syntax Addr ::= "defaultAddr" "(" Bool ")" [function]
  rule defaultAddr(false) => defaultIPv4
  rule defaultAddr(true) => defaultIPv6

  syntax String ::= "portString" "(" Port ")" [function]
  rule portString(port(P:String)) => P

  syntax String ::= "displayAddr" "(" Addr "," Bool ")" [function]
  rule displayAddr(ipv4wild, false) => "0.0.0.0"
  rule displayAddr(raw0, false) => "0"
  rule displayAddr(defaultIPv4, false) => "127.0.0.1"
  rule displayAddr(defaultIPv6, true) => "[::1]"
  rule displayAddr(ipv4(A:String), false) => A
  rule displayAddr(ipv6(A:String), true) => "[" +String A +String "]"
  rule displayAddr(fqdn(A:String), false) => A
  rule displayAddr(fqdn(A:String), true) => A

  rule <k> handle(missing, USE:Bool) => emit ... </k>
       <addr> _ => defaultAddr(USE) </addr>
       <port> _ => port("8000") </port>
       <useIPv6> _ => USE </useIPv6>
       <rawIPv6> _ => USE </rawIPv6>

  rule <k> handle(portOnly(P:Port), USE:Bool) => emit ... </k>
       <addr> _ => defaultAddr(USE) </addr>
       <port> _ => P </port>
       <useIPv6> _ => USE </useIPv6>
       <rawIPv6> _ => USE </rawIPv6>

  rule <k> handle(addrPort(raw0, P:Port), false) => emit ... </k>
       <addr> _ => ipv4wild </addr>
       <port> _ => P </port>
       <useIPv6> _ => false </useIPv6>
       <rawIPv6> _ => false </rawIPv6>

  rule <k> handle(addrPort(raw0, P:Port), true) => emit ... </k>
       <addr> _ => raw0 </addr>
       <port> _ => P </port>
       <useIPv6> _ => true </useIPv6>
       <rawIPv6> _ => false </rawIPv6>

  rule <k> handle(addrPort(ipv4(A:String), P:Port), false) => emit ... </k>
       <addr> _ => ipv4(A) </addr>
       <port> _ => P </port>
       <useIPv6> _ => false </useIPv6>
       <rawIPv6> _ => false </rawIPv6>

  rule <k> handle(addrPort(ipv6(A:String), P:Port), USE:Bool) => emit ... </k>
       <addr> _ => ipv6(A) </addr>
       <port> _ => P </port>
       <useIPv6> _ => true </useIPv6>
       <rawIPv6> _ => true </rawIPv6>

  rule <k> handle(addrPort(fqdn(A:String), P:Port), USE:Bool) => emit ... </k>
       <addr> _ => fqdn(A) </addr>
       <port> _ => P </port>
       <useIPv6> _ => USE </useIPv6>
       <rawIPv6> _ => false </rawIPv6>

  rule <k> emit => .K </k>
       <addr> A:Addr </addr>
       <port> P:Port </port>
       <rawIPv6> RAW:Bool </rawIPv6>
       <output> _ => "Starting development server at http://" +String displayAddr(A, RAW) +String ":" +String portString(P) +String "/" </output>
endmodule

