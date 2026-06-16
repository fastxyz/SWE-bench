module MINI-LINKCHECK-SYNTAX
  imports BOOL-SYNTAX
  imports INT-SYNTAX

  // Outcome abstracts one completed Requests operation.
  // ok(SAME, CODE): request returned a response; SAME says final URL equals
  // the requested URL after Sphinx's rstrip("/") comparison. CODE is the last
  // redirect status code, or 0 when there is no redirect history.
  syntax Outcome ::= "ok" "(" Bool "," Int ")"
                   | "httpError" "(" Int ")"
                   | "tooManyRedirects"
                   | "otherError"

  syntax Status ::= "working"
                  | "workingUnauthorized"
                  | "ignored503"
                  | "broken"
                  | "redirected" "(" Int ")"

  // The Bool records whether GET was used.
  syntax Result ::= "result" "(" Status "," Bool ")"

  syntax Cmd ::= "checkNoAnchor" "(" Outcome "," Outcome ")"
               | "classifyHead" "(" Outcome "," Outcome ")"
               | "classifyGet" "(" Outcome ")"

  syntax KResult ::= Result
endmodule

module MINI-LINKCHECK
  imports MINI-LINKCHECK-SYNTAX
  imports BOOL
  imports INT

  configuration <k> $PGM:Cmd </k>

  rule <k> checkNoAnchor(H:Outcome, G:Outcome) => classifyHead(H, G) </k>

  rule <k> classifyHead(ok(true, C:Int), G:Outcome) => result(working, false) </k>
  rule <k> classifyHead(ok(false, C:Int), G:Outcome) => result(redirected(C), false) </k>
  rule <k> classifyHead(httpError(S:Int), G:Outcome) => classifyGet(G) </k>
  rule <k> classifyHead(tooManyRedirects, G:Outcome) => classifyGet(G) </k>
  rule <k> classifyHead(otherError, G:Outcome) => result(broken, false) </k>

  rule <k> classifyGet(ok(true, C:Int)) => result(working, true) </k>
  rule <k> classifyGet(ok(false, C:Int)) => result(redirected(C), true) </k>
  rule <k> classifyGet(httpError(401)) => result(workingUnauthorized, true) </k>
  rule <k> classifyGet(httpError(503)) => result(ignored503, true) </k>
  rule <k> classifyGet(httpError(S:Int)) => result(broken, true) </k>
    requires S =/=Int 401 andBool S =/=Int 503
  rule <k> classifyGet(tooManyRedirects) => result(broken, true) </k>
  rule <k> classifyGet(otherError) => result(broken, true) </k>
endmodule
