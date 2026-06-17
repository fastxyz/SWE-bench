requires "mini-axios-http-options.k"

module AXIOS-HTTP-OPTIONS-SPEC
  imports MINI-AXIOS-HTTP-OPTIONS

  // SPEC-PROVENANCE:
  // - from_prompt: "default maxBodyLength of 10MB began to be enforced"
  //   and "default maxBodyLength should be consistent" => unlimited axios
  //   defaults must not inherit follow-redirects' finite default.
  // - from_hint: "if axios limit is set to -1 then Infinity should be passed
  //   to follow-redirects" => follow transport receives inf for finite(-1).
  claim <k> compute(finite(-1), false, false) => res(follow, inf) ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "{ maxBodyLength: -1 }" should not fail the same large
  //   request => any axios unlimited sentinel on the follow path maps to inf.
  claim <k> compute(finite(N:Int), false, false) => res(follow, inf) ... </k>
    requires notBool gtMinusOne(finite(N))
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "{ maxBodyLength: Infinity } -> OK" and existing adapter
  //   behavior for finite positive values => explicit limits pass through.
  claim <k> compute(MBL:Limit, true, RD:Bool) => res(custom, MBL) ... </k>
    requires gtMinusOne(MBL)
    [all-path]

  claim <k> compute(MBL:Limit, false, true) => res(native, MBL) ... </k>
    requires gtMinusOne(MBL)
    [all-path]

  claim <k> compute(MBL:Limit, false, false) => res(follow, MBL) ... </k>
    requires gtMinusOne(MBL)
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "{ maxRedirects: 0 } -> OK" => native no-redirect path
  //   remains unlimited without needing follow-redirects' inf override.
  claim <k> compute(finite(N:Int), false, true) => res(native, omitted) ... </k>
    requires notBool gtMinusOne(finite(N))
    [all-path]

  // SPEC-PROVENANCE:
  // - from_public_compatibility: custom transport is outside the reported
  //   follow-redirects defect; preserve V0 option shape for unlimited values.
  claim <k> compute(finite(N:Int), true, RD:Bool) => res(custom, omitted) ... </k>
    requires notBool gtMinusOne(finite(N))
    [all-path]
endmodule
