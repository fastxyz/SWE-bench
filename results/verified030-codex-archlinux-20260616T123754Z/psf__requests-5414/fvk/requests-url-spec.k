requires "mini-python.k"

module REQUESTS-URL-SPEC
  imports MINI-PYTHON-REQUESTS-URL

  // SPEC-PROVENANCE:
  // - from_prompt: "Getting http://.example.com raises UnicodeError" =>
  //   the host validation branch must reject a leading empty label before the
  //   networking/IDNA layer can emit UnicodeError.
  // - from_prompt: "Expected Result ... InvalidUrl: URL has an invalid label." =>
  //   the observable error is Requests InvalidURL with the established invalid
  //   label message.
  claim <k> prepareAsciiHost(".example.com")
        => invalidURL("URL has an invalid label.") ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: the reported host has an empty DNS label; leading empty labels
  //   are the general form represented by the concrete issue input.
  claim <k> prepareAsciiHost(H:String)
        => invalidURL("URL has an invalid label.") ... </k>
    requires StartsWith(H, ".")
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "invalid label" and the IDNA symptom "label empty" justify
  //   the same Requests exception for interior empty labels in ASCII hosts.
  claim <k> prepareAsciiHost(H:String)
        => invalidURL("URL has an invalid label.") ... </k>
    requires Contains(H, "..")
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: wildcard-prefixed ASCII hosts were already rejected on this
  //   branch; the fix must preserve that established Requests behavior.
  claim <k> prepareAsciiHost(H:String)
        => invalidURL("URL has an invalid label.") ... </k>
    requires StartsWith(H, "*")
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code/comment: ASCII hosts are otherwise allowed through unencoded for
  //   compatibility; the fix must not force full IDNA validation on that branch.
  claim <k> prepareAsciiHost(H:String) => validHost(H) ... </k>
    requires notBool BadAsciiHost(H)
    [all-path]
endmodule
