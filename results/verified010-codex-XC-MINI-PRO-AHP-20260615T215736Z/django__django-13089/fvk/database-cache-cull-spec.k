requires "mini-cache-cull.k"

module DATABASE-CACHE-CULL-SPEC
  imports MINI-CACHE-CULL
  imports INT
  imports BOOL

  // SPEC-PROVENANCE:
  // - from_prompt: "cursor.fetchone()[0] afterwards fails" => missing cutoff row is in-domain for culling.
  // - from_code: V1 checks "if cull_key is not None" before reading index 0.
  claim <k> cull(FREQ, MAX, NUM, none) => rows(NUM) ... </k>
    requires FREQ >Int 0
     andBool NUM >=Int 0
     andBool NUM >Int MAX
     andBool (NUM /Int FREQ) =/=Int NUM
    [all-path]

  // SPEC-PROVENANCE:
  // - from_docs: "The actual ratio is 1 / CULL_FREQUENCY" => FREQ 1 culls all current rows.
  // - from_code: V1 deletes all rows when cull_num == num instead of selecting past the end.
  claim <k> cull(1, MAX, NUM, CUTOFF) => rows(0) ... </k>
    requires NUM >=Int 0 andBool NUM >Int MAX
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: the fix should address the missing-row crash without changing normal culling.
  // - from_code: a present cutoff row still drives the same "delete before cutoff" behavior.
  claim <k> cull(FREQ, MAX, NUM, some(CUTOFF)) => rows(NUM -Int (NUM /Int FREQ)) ... </k>
    requires FREQ >Int 0
     andBool NUM >=Int 0
     andBool NUM >Int MAX
     andBool (NUM /Int FREQ) =/=Int NUM
    [all-path]

  // SPEC-PROVENANCE:
  // - from_docs: "A value of 0 for CULL_FREQUENCY means that the entire cache will be dumped."
  // - from_code: existing zero-frequency branch is preserved.
  claim <k> cull(0, MAX, NUM, CUTOFF) => rows(0) ... </k>
    requires NUM >=Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - from_docs: culling happens when MAX_ENTRIES is reached/exceeded.
  // - from_code: _cull's post-expiry count controls whether cutoff culling runs.
  claim <k> cull(FREQ, MAX, NUM, CUTOFF) => rows(NUM) ... </k>
    requires FREQ >Int 0
     andBool NUM >=Int 0
     andBool NUM <=Int MAX
    [all-path]
endmodule
