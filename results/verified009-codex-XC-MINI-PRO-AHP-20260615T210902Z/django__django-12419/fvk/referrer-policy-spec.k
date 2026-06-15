// Constructed FVK artifact, not machine-checked.
// Claims for django__django-12419 SECURE_REFERRER_POLICY default behavior.

requires "mini-django-referrer.k"

module REFERRER-POLICY-SPEC
  imports MINI-DJANGO-REFERRER
  imports MAP
  imports BOOL
  imports STRING

  // SPEC-PROVENANCE:
  // - from_prompt: "change the default for this to \"same-origin\"" =>
  //   the global default must evaluate to SameOrigin.
  claim
    <k> defaultSECURE_REFERRER_POLICY => SameOrigin </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "Add secure default SECURE_REFERRER_POLICY / Referrer-policy header" =>
  //   a default SecurityMiddleware response with no existing header must emit
  //   Referrer-Policy: same-origin.
  // - from_code: SecurityMiddleware.process_response() uses response.setdefault(),
  //   so this claim only covers responses that do not already have the header.
  claim
    <k> defaultResponse(H:Map) => H ["Referrer-Policy" <- "same-origin"] </k>
    requires notBool hasHeader(H, "Referrer-Policy")
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code/docs: response.setdefault() preserves an existing response
  //   header. This is a public frame condition preserved by V1.
  claim
    <k> defaultResponse(H:Map) => H </k>
    requires hasHeader(H, "Referrer-Policy")
    [all-path]

  // SPEC-PROVENANCE:
  // - from_docs/V1 release note: SECURE_REFERRER_POLICY = None remains the
  //   explicit opt-out for applications that need the previous behavior.
  claim
    <k> processResponse(NonePolicy, H:Map) => H </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_public API: SECURE_REFERRER_POLICY remains configurable; custom
  //   non-None policy values should still set the same header when absent.
  claim
    <k> processResponse(RawPolicy(P:String), H:Map) => H ["Referrer-Policy" <- P] </k>
    requires notBool hasHeader(H, "Referrer-Policy")
    [all-path]
endmodule
