requires "mini-signature-parser.k"

module SIGNATURE-FROM-STR-SPEC
  imports MINI-SIGNATURE-PARSER
  imports INT
  imports BOOL
  imports LIST
  imports STRING

  // SPEC-PROVENANCE:
  // - E1/E2 from the issue require `b=0` to survive in `(a, b=0, /, c=1)`.
  // - E4 gives the default-domain alignment: defaults attach to the suffix of
  //   posonlyargs + args.
  // - E5 requires no regression when P == 0.
  //
  // Claim family over the mini functions:

  // CLAIM-ALIGN-GENERAL
  claim <k> signatureParams(P:List, A:List, D:List) =>
              buildPosOnly(0, P, padLeft(size(P) +Int size(A), D))
              buildPosOrKey(0, size(P), A, padLeft(size(P) +Int size(A), D))
        </k>
    requires 0 <=Int size(D)
     andBool size(D) <=Int size(P) +Int size(A)
    [all-path]

  // CLAIM-ISSUE-EXAMPLE
  // Concrete issue instance:
  // P = [a, b], A = [c], D = [0, 1].
  claim <k> signatureParams(
              ListItem("a") ListItem("b"),
              ListItem("c"),
              ListItem(someDefault("0")) ListItem(someDefault("1")))
            =>
              ListItem(param("a", posOnly, noDefault))
              ListItem(param("b", posOnly, someDefault("0")))
              ListItem(param("c", posOrKey, someDefault("1")))
        </k>
    [all-path]

  // CLAIM-NO-POSONLY-REGRESSION
  // No-positional-only regression:
  // P = [], A = [a, b], D = [0] keeps default only on b.
  claim <k> signatureParams(
              .List,
              ListItem("a") ListItem("b"),
              ListItem(someDefault("0")))
            =>
              ListItem(param("a", posOrKey, noDefault))
              ListItem(param("b", posOrKey, someDefault("0")))
        </k>
    [all-path]
endmodule
