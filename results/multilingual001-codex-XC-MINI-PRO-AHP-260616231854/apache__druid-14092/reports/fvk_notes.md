# FVK Notes

## Decision Summary

V1 stands unchanged after the FVK audit. No additional production source edits were made in V2.

## Decisions and Evidence

1. Kept the default handled status set as `200 OK`.

   Evidence: `fvk/FINDINGS.md` F-001 and `fvk/PROOF_OBLIGATIONS.md` PO-1, PO-4. The issue's concrete proxy/sidecar failure example is `503`, and the proof obligation requires a default `503` to miss the handled-status set and enter the refresh/retry branch.

2. Kept the status-aware overloads added in V1.

   Evidence: F-002 and PO-2. The public issue proposes allowing callers to pass statuses they want to handle. The overloads provide that path, and the proof shows any status in the supplied set returns directly.

3. Kept the `withCurrentKnownLeader` shared helper.

   Evidence: F-001 and PO-4, PO-6. The helper is the proof bridge showing status-based retries and transport-exception retries use the same cache-refresh mechanism while preserving the request path, query, headers, and content.

4. Kept the final-response behavior after status retry exhaustion or refresh failure.

   Evidence: F-001 and PO-5. The issue says that if the best-effort retry is still unsuccessful, the response should be returned to the caller. V1 does this on the final retry and when no refreshed leader can be resolved.

5. Did not migrate public callers that handle `404` to the new overloads in this iteration.

   Evidence: F-003 and PO-7. The reported defect is fixed by the default path. Broad migration would change the method shape observed by public mocks and overrides, while the issue only requires that callers have an API to opt into handled statuses. This is recorded as future targeted work in `fvk/ITERATION_GUIDANCE.md`.

6. Accepted handler reuse across status retries for the audited source.

   Evidence: F-004 and PO-8. Public DruidLeaderClient custom-handler call sites use response handlers that are effectively stateless for each holder. No V2 code change was justified. A future stateful handler would require a new audit.

7. Did not run tests or formal tooling.

   Evidence: F-005 and the user instructions. `fvk/PROOF.md` records the commands that would be used in an execution-capable environment, but no `kompile`, `kprove`, tests, Python, or project code were run.

## Artifacts Produced

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`
- `fvk/mini-druid-leader-client.k`
- `fvk/druid-leader-client-spec.k`
- `reports/fvk_notes.md`

## Code Changes in V2

None. The only production source diff remains the V1 change in `repo/server/src/main/java/org/apache/druid/discovery/DruidLeaderClient.java`.
