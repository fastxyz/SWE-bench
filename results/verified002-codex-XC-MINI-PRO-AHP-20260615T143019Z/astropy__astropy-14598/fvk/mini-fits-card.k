// Constructed mini semantics for the audited FITS Card long-string fragment.
// This file was not parsed or machine-checked in this task.

module MINI-FITS-CARD-SYNTAX
  imports STRING-SYNTAX
  imports BOOL-SYNTAX

  syntax Payload ::= payload(String, Bool)
  syntax Payloads ::= ".Payloads"
                    | Payload ";" Payloads

  syntax VC ::= vc(String, String)

  syntax Cmd ::= splitLong(Payloads, String)
               | parseValue
               | roundTrip(String, String)

  syntax KResult ::= VC | String
endmodule

module MINI-FITS-CARD
  imports MINI-FITS-CARD-SYNTAX
  imports STRING
  imports BOOL

  configuration <k> $PGM:K </k>

  // Spec vocabulary. These are abstract functions for the exact string facts
  // audited by this FVK pass.
  syntax String ::= escape(String) [function]
                  | unescape(String) [function]
                  | stripContinue(String, Bool) [function]
                  | collectEscaped(Payloads) [function]
                  | observedValue(String) [function]

  syntax Payloads ::= chunks(String) [function]

  // Formatter/chunker obligations.
  rule collectEscaped(.Payloads) => ""
  rule collectEscaped(payload(P:String, CONT:Bool) ; PS:Payloads)
    => stripContinue(P, CONT) +String collectEscaped(PS)

  // Continuation marker semantics. The concrete Python implementation uses
  // rstrip() and then removes one final '&'. The Bool records whether the
  // physical card carried that marker.
  rule stripContinue(P:String, false) => P

  // Abstract axiom: for formatter-produced payloads that carry a continuation
  // marker, stripping the marker leaves the original escaped chunk. The marker
  // itself is not modeled as part of P; it is represented by the Bool.
  rule stripContinue(P:String, true) => P

  // Final parse unescapes exactly once.
  rule <k> vc(E:String, C:String) ~> parseValue => unescape(E) ... </k>

  // Long split reassembles raw escaped text and keeps comments as a frame.
  rule <k> splitLong(PS:Payloads, C:String)
        => vc(collectEscaped(PS), C)
       ... </k>

  // End-to-end audited command: format by escaping, split by valid chunks, then
  // parse the synthesized value/comment field.
  rule <k> roundTrip(V:String, C:String)
        => splitLong(chunks(escape(V)), C) ~> parseValue
       ... </k>
endmodule
