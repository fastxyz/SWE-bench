requires "mini-druid-leader-client.k"

module DRUID-LEADER-CLIENT-SPEC
  imports MINI-DRUID-LEADER-CLIENT
  imports INT
  imports BOOL

  // SPEC-PROVENANCE:
  // - E4: callers can pass statuses they want to handle.
  // - PO-2: handled statuses return directly.
  claim
    <k> goStep(C:Int, response(handled)) => returned(handled) ... </k>
    requires C >=Int 0 andBool C <Int 5
    [all-path]

  // SPEC-PROVENANCE:
  // - E1/E2/E3/E5: unhandled non-200 proxy responses refresh cache and retry.
  // - PO-4: retry while budget remains.
  claim
    <k> goStep(C:Int, response(unhandled)) => retry ... </k>
    requires C >=Int 0 andBool C <Int 4
    [all-path]

  // SPEC-PROVENANCE:
  // - E6: persistent unsuccessful status response is returned to caller.
  // - PO-5: final retry returns final unhandled response.
  claim
    <k> goStep(4, response(unhandled)) => returned(unhandled) ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E7: redirects remain special and retry the redirect URL.
  // - PO-3: redirect branch is before handled-status classification.
  claim
    <k> goStep(C:Int, response(redirect)) => retry ... </k>
    requires C >=Int 0 andBool C <Int 5
    [all-path]

  // SPEC-PROVENANCE:
  // - E1/E5: transport failures preserve old cache-refresh retry behavior.
  // - PO-6: transport failure retries while budget remains.
  claim
    <k> goStep(C:Int, transportFailure) => retry ... </k>
    requires C >=Int 0 andBool C <Int 4
    [all-path]

  // SPEC-PROVENANCE:
  // - E1 and existing behavior: transport failures exhaust with IOE.
  // - PO-6: all transport failures throw retry exhaustion after budget.
  claim
    <k> goStep(4, transportFailure) => throwRetriesExhausted ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E6: status-branch refresh failure is best effort and returns current response.
  // - PO-5: refresh failure returns response.
  claim
    <k> goStep(C:Int, refreshFailure) => returned(unhandled) ... </k>
    requires C >=Int 0 andBool C <Int 5
    [all-path]
endmodule
