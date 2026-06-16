requires "mini-runserver.k"

module RUNSERVER-SPEC
  imports MINI-RUNSERVER

  // SPEC-PROVENANCE:
  // - E-001/E-004: non-IPv6 "0:P" is the documented shortcut for "0.0.0.0:P".
  // - E-002/E-003: startup output must render "0.0.0.0", not "0".
  // - E-007/E-008: self.addr feeds both the output and server bind, so the state is canonical.
  // CLAIM: BUGFIX-ZERO-SHORTCUT
  claim
    <k> handle(addrPort(raw0, port(P:String)), false) => .K </k>
    <addr> noAddr => ipv4wild </addr>
    <port> noPort => port(P) </port>
    <useIPv6> false => false </useIPv6>
    <rawIPv6> false => false </rawIPv6>
    <output> "" => "Starting development server at http://0.0.0.0:" +String P +String "/" </output>
    [all-path]

  // SPEC-PROVENANCE:
  // - E-006: omitted non-IPv6 addrport defaults to 127.0.0.1:8000.
  // - public tests in ManageRunserver assert this state.
  // CLAIM: FRAME-DEFAULT-IPV4
  claim
    <k> handle(missing, false) => .K </k>
    <addr> noAddr => defaultIPv4 </addr>
    <port> noPort => port("8000") </port>
    <useIPv6> false => false </useIPv6>
    <rawIPv6> false => false </rawIPv6>
    <output> "" => "Starting development server at http://127.0.0.1:8000/" </output>
    [all-path]

  // SPEC-PROVENANCE:
  // - E-006: --ipv6 changes the default address to ::1.
  // - existing formatter brackets raw IPv6 addresses.
  // CLAIM: FRAME-DEFAULT-IPV6
  claim
    <k> handle(missing, true) => .K </k>
    <addr> noAddr => defaultIPv6 </addr>
    <port> noPort => port("8000") </port>
    <useIPv6> false => true </useIPv6>
    <rawIPv6> false => true </rawIPv6>
    <output> "" => "Starting development server at http://[::1]:8000/" </output>
    [all-path]

  // SPEC-PROVENANCE:
  // - public tests assert port-only input keeps the default address.
  // CLAIM: FRAME-PORT-ONLY-IPV4
  claim
    <k> handle(portOnly(port(P:String)), false) => .K </k>
    <addr> noAddr => defaultIPv4 </addr>
    <port> noPort => port(P) </port>
    <useIPv6> false => false </useIPv6>
    <rawIPv6> false => false </rawIPv6>
    <output> "" => "Starting development server at http://127.0.0.1:" +String P +String "/" </output>
    [all-path]

  // SPEC-PROVENANCE:
  // - public tests assert port-only input with --ipv6 keeps the IPv6 default address.
  // CLAIM: FRAME-PORT-ONLY-IPV6
  claim
    <k> handle(portOnly(port(P:String)), true) => .K </k>
    <addr> noAddr => defaultIPv6 </addr>
    <port> noPort => port(P) </port>
    <useIPv6> false => true </useIPv6>
    <rawIPv6> false => true </rawIPv6>
    <output> "" => "Starting development server at http://[::1]:" +String P +String "/" </output>
    [all-path]

  // SPEC-PROVENANCE:
  // - command reference and public tests assert explicit IPv4 address preservation.
  // CLAIM: FRAME-EXPLICIT-IPV4
  claim
    <k> handle(addrPort(ipv4(A:String), port(P:String)), false) => .K </k>
    <addr> noAddr => ipv4(A) </addr>
    <port> noPort => port(P) </port>
    <useIPv6> false => false </useIPv6>
    <rawIPv6> false => false </rawIPv6>
    <output> "" => "Starting development server at http://" +String A +String ":" +String P +String "/" </output>
    [all-path]

  // SPEC-PROVENANCE:
  // - command reference and public tests allow ASCII hostnames, including with --ipv6.
  // CLAIM: FRAME-FQDN
  claim
    <k> handle(addrPort(fqdn(H:String), port(P:String)), USE:Bool) => .K </k>
    <addr> noAddr => fqdn(H) </addr>
    <port> noPort => port(P) </port>
    <useIPv6> false => USE </useIPv6>
    <rawIPv6> false => false </rawIPv6>
    <output> "" => "Starting development server at http://" +String H +String ":" +String P +String "/" </output>
    [all-path]

  // SPEC-PROVENANCE:
  // - command reference and public tests assert bracketed IPv6 literals enable IPv6.
  // CLAIM: FRAME-BRACKETED-IPV6
  claim
    <k> handle(addrPort(ipv6(A:String), port(P:String)), USE:Bool) => .K </k>
    <addr> noAddr => ipv6(A) </addr>
    <port> noPort => port(P) </port>
    <useIPv6> false => true </useIPv6>
    <rawIPv6> false => true </rawIPv6>
    <output> "" => "Starting development server at http://[" +String A +String "]:" +String P +String "/" </output>
    [all-path]
endmodule
