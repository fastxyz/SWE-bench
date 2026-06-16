requires "mini-pastebin.k"

module PASTEBIN-SPEC
  imports MINI-PASTEBIN

  // SPEC-PROVENANCE:
  // - from_prompt: "The call goes through fine if lexer is changed from python3 to text"
  //   => the submitted bpaste lexer must be text for pytest terminal output.
  // - from_prompt: "the console output of a pytest run that is being uploaded is not
  //   Python code, but arbitrary text"
  //   => no Python-version-specific lexer is permitted for this upload.
  // - from_code: create_new_paste builds params with code, lexer, and expiry, then
  //   sends urlencode(params) to https://bpaste.net.
  // - conflicts: testing/test_pastebin.py expects python/python3; marked SUSPECT
  //   in FINDINGS.md because it preserves the reported legacy behavior.
  claim
    <k> createPasteRequest(CONTENTS:String)
        => request("https://bpaste.net", CONTENTS, "text", "1week")
    </k>
    [all-path]
endmodule
