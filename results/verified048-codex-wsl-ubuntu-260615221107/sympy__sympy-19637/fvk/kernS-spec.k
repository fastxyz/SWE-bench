// Constructed FVK claims for kernS control-flow safety.
// These claims are intended for later machine checking; they were not run here.

requires "mini-kernS.k"

module KERNS-SPEC
  imports MINI-KERNS
  imports BOOL
  imports STRING

  // SPEC-PROVENANCE:
  // - E-001: the public issue input must not read undefined `kern`.
  // - E-005/E-006: `hit` guards cleanup, so keeping it false avoids Symbol(kern).
  claim
    <k> kernS(S:String) => sympify(hackRewrite(stripSpaces(S))) ... </k>
    <hit> false </hit>
    <kernDefined> false </kernDefined>
    requires hasLParen(S)
     andBool notBool quoted(S)
     andBool balancedParens(S)
     andBool notBool hasHackSpace(hackRewrite(stripSpaces(S)))
    [all-path]

  // SPEC-PROVENANCE:
  // - E-002/E-004: placeholder hack remains available when hack spaces exist.
  // - PO-3: `hit` can become true only after `kern` is assigned.
  claim
    <k> kernS(S:String)
      => clearSympify(replaceSpaces(hackRewrite(stripSpaces(S)),
                                    freshKern(hackRewrite(stripSpaces(S)))),
                      freshKern(hackRewrite(stripSpaces(S)))) ... </k>
    <hit> false => true </hit>
    <kern> "" => freshKern(hackRewrite(stripSpaces(S))) </kern>
    <kernDefined> false => true </kernDefined>
    requires hasLParen(S)
     andBool notBool quoted(S)
     andBool balancedParens(S)
     andBool hasHackSpace(hackRewrite(stripSpaces(S)))
     andBool notBool sympifyTypeError(
       replaceSpaces(hackRewrite(stripSpaces(S)),
                     freshKern(hackRewrite(stripSpaces(S)))))
    [all-path]

  // SPEC-PROVENANCE:
  // - E-003: if the hack fails with TypeError, retry the un-hacked string.
  claim
    <k> kernS(S:String) => sympify(stripSpaces(S)) ... </k>
    <hit> false </hit>
    <kernDefined> false => true </kernDefined>
    requires hasLParen(S)
     andBool notBool quoted(S)
     andBool balancedParens(S)
     andBool hasHackSpace(hackRewrite(stripSpaces(S)))
     andBool sympifyTypeError(
       replaceSpaces(hackRewrite(stripSpaces(S)),
                     freshKern(hackRewrite(stripSpaces(S)))))
    [all-path]

  // SPEC-PROVENANCE:
  // - PO-5: unmatched left parenthesis behavior is framed by V1.
  claim
    <k> kernS(S:String) => sympifyError("unmatched left parenthesis") ... </k>
    requires hasLParen(S)
     andBool notBool quoted(S)
     andBool notBool balancedParens(S)
    [all-path]
endmodule
