requires "mini-python.k"

module DIGEST-AUTH-SPEC
  imports MINI-PYTHON
  imports LIST
  imports STRING

  // SPEC-PROVENANCE:
  // - E-1/E-3/E-4: the qop value emitted by Digest Auth must be quoted.
  // - E-2: qop-options is a list of one or more tokens; if "auth" is present,
  //   Requests selects "auth".
  // - from_code: V2 computes the digest qop-value from the selected token.
  claim
    <k> buildDigestQop(qopOptions(QOPS:List))
        => qopResult("qop=\"auth\"", "auth") </k>
    requires containsAuth(QOPS)
    [all-path]

  // SPEC-PROVENANCE:
  // - I-3: a challenge without qop must not gain a qop header fragment.
  // - from_code: qop is None uses the legacy nonce:HA2 digest input.
  claim
    <k> buildDigestQop(noQop)
        => qopResult("", "") </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E-6: auth-int is explicitly not implemented in this version.
  // - I-4: no-auth qop options are recorded as unsupported, not certified.
  claim
    <k> buildDigestQop(qopOptions(QOPS:List))
        => unsupportedQop </k>
    requires notBool containsAuth(QOPS)
    [all-path]
endmodule

