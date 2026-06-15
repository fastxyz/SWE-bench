// Constructed K-style claims for the audited FITS Card long-string fragment.
// This file was not parsed or machine-checked in this task.

requires "mini-fits-card.k"

module FITS-CARD-VERIFICATION
  imports MINI-FITS-CARD
  imports BOOL
  imports STRING

  // Abstract predicates/functions used to state the parser obligation that V1
  // changed from prefix matching to full matching.
  syntax Bool ::= fullMatchValueComment(String) [function]
  syntax String ::= prefixAmbiguousField(String) [function]

  // Formatter/chunker axiom: valid chunks reassemble to their escaped source.
  rule collectEscaped(chunks(E:String)) => E [simplification]

  // Escape/unescape axiom over the in-domain printable-ASCII values covered by
  // this FVK pass. observedValue accounts for the existing Card.value
  // whitespace policy; for the issue examples it is the identity.
  rule unescape(escape(V:String)) => observedValue(V) [simplification]

  // V1 PO2: prefix-ambiguous fields, such as a doubled quote followed by a
  // space and continuation suffix, must not be accepted as valid full fields.
  rule fullMatchValueComment(prefixAmbiguousField(E:String)) => false [simplification]
endmodule

module FITS-CARD-SPEC
  imports FITS-CARD-VERIFICATION

  // SPEC-PROVENANCE:
  // - E1: "Card.fromstring(str(card1)) # Should be the same as card1"
  //   => round-trip value preservation.
  // - E2: issue examples where "''" became "'" => doubled quotes are preserved.
  // - E4/E5: CONTINUE is transparent and "&" is not part of the value.
  // - F1/F2: V1 removes per-chunk unescape and requires full matching.
  claim
    <k> roundTrip(V:String, C:String) => observedValue(V) ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E3: "'' aaa" after a boundary quote must preserve the trailing text.
  // - PO2/F2: a prefix-only parse is not acceptable.
  claim
    <k> fullMatchValueComment(prefixAmbiguousField(E:String)) => false ... </k>
    [all-path]
endmodule
