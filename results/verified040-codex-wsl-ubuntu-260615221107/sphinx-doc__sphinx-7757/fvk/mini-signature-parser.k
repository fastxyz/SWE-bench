// Mini signature-parser semantics for the FVK audit.
// Status: constructed, not machine-checked.
//
// This is an AST-level mini model. It intentionally starts after Python's
// parser has produced the relevant ast.arguments fields: posonlyargs, args, and
// defaults. That is the behavior changed by the V1 fix.

module MINI-SIGNATURE-PARSER-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX
  imports STRING-SYNTAX
  imports LIST-SYNTAX

  syntax Kind ::= posOnly | posOrKey
  syntax MaybeDefault ::= noDefault | someDefault(String)
  syntax Param ::= param(String, Kind, MaybeDefault)

  syntax Defaults ::= defaults(List)
  syntax Names ::= names(List)

  syntax List ::= padLeft(Int, List) [function]
                | buildPosOnly(Int, List, List) [function]
                | buildPosOrKey(Int, Int, List, List) [function]
                | signatureParams(List, List, List) [function]
endmodule

module MINI-SIGNATURE-PARSER
  imports MINI-SIGNATURE-PARSER-SYNTAX
  imports INT
  imports BOOL
  imports LIST

  configuration <k> $PGM:List </k>

  // SPEC-PROVENANCE:
  // - from_prompt: positional-only defaults must be shown.
  // - from_default_domain: ast.arguments.defaults aligns to the suffix of
  //   posonlyargs + args.
  // - from_code: V1 pads defaults before both positional loops.
  rule padLeft(T, DS) => DS
    requires size(DS) >=Int T

  rule padLeft(T, DS) => padLeft(T, ListItem(noDefault) DS)
    requires size(DS) <Int T

  rule buildPosOnly(I, P, AD) => .List
    requires I >=Int size(P)

  rule buildPosOnly(I, P, AD) =>
      ListItem(param(P[I], posOnly, AD[I]))
      buildPosOnly(I +Int 1, P, AD)
    requires I <Int size(P)

  rule buildPosOrKey(I, Offset, A, AD) => .List
    requires I >=Int size(A)

  rule buildPosOrKey(I, Offset, A, AD) =>
      ListItem(param(A[I], posOrKey, AD[Offset +Int I]))
      buildPosOrKey(I +Int 1, Offset, A, AD)
    requires I <Int size(A)

  rule signatureParams(P, A, D) =>
      buildPosOnly(0, P, padLeft(size(P) +Int size(A), D))
      buildPosOrKey(0, size(P), A, padLeft(size(P) +Int size(A), D))
endmodule
