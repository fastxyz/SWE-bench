requires "mini-cpp-literals.k"

module CPP-UDL-SPEC
  imports MINI-CPP-LITERALS
  imports STRING
  imports BOOL

  // SPEC-PROVENANCE:
  // - from_prompt: "6.62607015e-34q_J * 1q_s" fails at q_J
  //   => numeric UDL suffixes must be consumed as part of the literal.
  claim <k> parse(num, CORE:String, SUFFIX:String, REST:String)
        => parsed(num, CORE +String SUFFIX, SUFFIX, REST) </k>
    requires isCore(num, CORE) andBool isUdlSuffix(SUFFIX)
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "C++ User Defined Literals not supported"
  // - from_default_domain: UDLs apply to string-literal spellings too.
  claim <k> parse(str, CORE:String, SUFFIX:String, REST:String)
        => parsed(str, CORE +String SUFFIX, SUFFIX, REST) </k>
    requires isCore(str, CORE) andBool isUdlSuffix(SUFFIX)
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "C++ User Defined Literals not supported"
  // - from_default_domain: UDLs apply to character-literal spellings too.
  claim <k> parse(chr, CORE:String, SUFFIX:String, REST:String)
        => parsed(chr, CORE +String SUFFIX, SUFFIX, REST) </k>
    requires isCore(chr, CORE) andBool isUdlSuffix(SUFFIX)
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: existing ordinary literal parsing must be preserved when no
  //   immediate suffix is present.
  claim <k> parse(K:Kind, CORE:String, "", REST:String)
        => parsed(K, CORE, "", REST) </k>
    requires isCore(K, CORE)
    [all-path]
endmodule
