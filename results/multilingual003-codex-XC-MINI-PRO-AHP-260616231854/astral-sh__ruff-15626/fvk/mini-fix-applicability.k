module MINI-FIX-APPLICABILITY-SYNTAX
  imports BOOL-SYNTAX

  syntax Rule ::= "sim201" | "sim202"
  syntax Evidence ::= "directKnown"
                    | "builtinKnown"
                    | "semanticKnown"
                    | "bindingValueKnown"
                    | "unknownName"
                    | "unknownCall"
                    | "ambiguousBinding"
  syntax Applicability ::= "safe" | "unsafe"
  syntax Bool ::= "known" "(" Evidence ")" [function]
                | "bothKnown" "(" Evidence "," Evidence ")" [function]
  syntax AppExp ::= "fixApplicability" "(" Rule "," Evidence "," Evidence ")" [function]
  syntax KResult ::= Bool | Applicability
endmodule

module MINI-FIX-APPLICABILITY
  imports MINI-FIX-APPLICABILITY-SYNTAX
  imports BOOL

  configuration <k> $PGM:AppExp </k>

  rule known(directKnown) => true
  rule known(builtinKnown) => true
  rule known(semanticKnown) => true
  rule known(bindingValueKnown) => true
  rule known(unknownName) => false
  rule known(unknownCall) => false
  rule known(ambiguousBinding) => false

  rule bothKnown(L:Evidence, R:Evidence) => known(L) andBool known(R)

  rule fixApplicability(_RULE:Rule, L:Evidence, R:Evidence) => safe
    requires bothKnown(L, R) ==Bool true
  rule fixApplicability(_RULE:Rule, L:Evidence, R:Evidence) => unsafe
    requires bothKnown(L, R) ==Bool false
endmodule
