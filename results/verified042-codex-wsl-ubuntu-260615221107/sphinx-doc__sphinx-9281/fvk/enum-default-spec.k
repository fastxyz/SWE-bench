requires "mini-enum-format.k"

module ENUM-DEFAULT-SPEC
  imports MINI-ENUM-FORMAT
  imports STRING

  // SPEC-PROVENANCE:
  // - from_prompt: expected default "MyEnum.ValueA" => named enum members
  //   render as Class.Member.
  // - from_prompt: ugly default "<MyEnum.ValueA: 10>" => generic enum repr is
  //   suspect legacy output.
  claim [NAMED-ENUM-DESCRIPTION]:
    <k> objectDescription(enumNamed(C:String, N:String, R:String))
        => C +String "." +String N </k>
    requires N =/=String ""
    [all-path]

  // SPEC-PROVENANCE:
  // - from_default_domain: enum.Flag combination names are pipe-separated
  //   member names; every component needs the enum class qualifier.
  claim [FLAG-COMPOSITE-DESCRIPTION]:
    <k> objectDescription(flagNamed(C:String, N1:String "|" N2:String, R:String))
        => C +String "." +String N1 +String "|" +String C +String "." +String N2 </k>
    requires N1 =/=String "" andBool N2 =/=String ""
    [all-path]

  // SPEC-PROVENANCE:
  // - from_default_domain: a missing enum member name has no Class.Member
  //   spelling; do not invent Class.None.
  // - from_code: nameless values fall through to the existing repr fallback.
  claim [UNNAMED-ENUM-FALLBACK]:
    <k> objectDescription(enumUnnamed(C:String, R:String)) => R </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: repr remains appropriate for non-enum defaults.
  // - from_code: non-enum fallback behavior is preserved.
  claim [OTHER-OBJECT-FALLBACK]:
    <k> objectDescription(other(R:String)) => R </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: stringify_signature writes object_description(param.default).
  // - from_prompt: signature default substring must be the enum member spelling.
  claim [SIGNATURE-NAMED-ENUM-DEFAULT]:
    <k> stringifyDefault(Prefix:String, enumNamed(C:String, N:String, R:String))
        => Prefix +String C +String "." +String N </k>
    requires N =/=String ""
    [all-path]
endmodule
