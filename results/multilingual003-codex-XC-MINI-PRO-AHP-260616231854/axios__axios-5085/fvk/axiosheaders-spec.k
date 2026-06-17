requires "mini-axios-headers.k"

module AXIOSHEADERS-SPEC
  imports MINI-AXIOS-HEADERS

  // SPEC-PROVENANCE:
  // - from_prompt: "AxiosHeaders.get('set-cookie') should return an array of cookies."
  //   => after set + normalize, an array-valued set-cookie header remains an array.
  // - from_prompt: "With version 0.27.2 or older ... it returned an array of cookies."
  //   => preserve order, cardinality, and string elements.
  // - from_code: AxiosHeaders.set() stores arrays and transformData() calls normalize().
  // - conflicts: V1 source fixed this, but minified runtime bundles initially still used
  //   the old scalar-only normalizer; FINDINGS F-001 records and closes that mirror gap.
  claim
    <k> normalizeGet("set-cookie", arr(str(C1:String), str(C2:String)))
      => arr(str(C1), str(C2)) ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: multiple Set-Cookie values must not be comma-joined.
  // - from_default_domain: JavaScript Array.map preserves order and cardinality.
  claim
    <k> normalizeValue(arr(VS:HVals))
      => arr(normalizeValues(VS)) ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code/frame: the fix must not change the existing false/null sentinel behavior.
  claim <k> normalizeValue(falseHeader) => falseHeader ... </k> [all-path]
  claim <k> normalizeValue(nullHeader) => nullHeader ... </k> [all-path]

  // SPEC-PROVENANCE:
  // - from_code/frame: scalar string header values remain scalar strings.
  claim <k> normalizeValue(str(S:String)) => str(S) ... </k> [all-path]
endmodule
