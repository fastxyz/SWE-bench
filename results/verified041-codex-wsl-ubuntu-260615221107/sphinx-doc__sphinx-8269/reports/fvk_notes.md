# FVK Notes

## Decisions

### D-1: Keep V1 source unchanged

Decision: no additional source edit was made after the V1 insertion of `response.raise_for_status()` before `check_anchor()`.

Trace: `fvk/FINDINGS.md` entry `F-1` identifies the pre-V1 root cause, and `fvk/PROOF_OBLIGATIONS.md` entries `PO-1` and `PO-2` state the required status-before-anchor behavior. The V1 code discharges those obligations because ordinary HTTP error responses now enter the existing `except HTTPError` path before anchor parsing.

### D-2: Preserve successful anchor behavior

Decision: no refactor was made to the successful-response anchor path.

Trace: `F-2` and `PO-4` require successful responses with missing anchors to keep reporting `Anchor '<anchor>' not found`. Since `raise_for_status()` is a no-op for successful responses, the V1 path still calls `check_anchor()` and raises the existing anchor-not-found exception when appropriate.

### D-3: Preserve existing special HTTP policies

Decision: no new status-code policy was added for anchor-bearing links.

Trace: `F-3` and `PO-3` require the existing `HTTPError` handler behavior to remain authoritative: 401 is working with unauthorized info and 503 is ignored. Routing the anchor branch through the same `HTTPError` handler satisfies that without duplicating policy.

### D-4: No public compatibility edit

Decision: no API, output format, configuration, or callsite changes were made.

Trace: `PO-6` and `fvk/PUBLIC_COMPATIBILITY_AUDIT.md` show the V1 edit only calls a method already used on `requests.Response` in the same function. There are no public signature, subclass, or output-schema changes to repair.

### D-5: Produce supporting FVK artifacts beyond the five requested summaries

Decision: added `mini-python.k`, `linkcheck-spec.k`, and adequacy/compatibility audit files under `fvk/` in addition to `SPEC.md`, `FINDINGS.md`, `PROOF_OBLIGATIONS.md`, `PROOF.md`, and `ITERATION_GUIDANCE.md`.

Trace: the FVK documentation requires a non-Markdown-only run with K claims and adequacy artifacts. The extra files provide the formal core referenced by `PO-1` through `PO-6`.

## Residual Risk

The proof is constructed, not machine-checked. No tests, Python code, or K tooling were run. The FVK model is intentionally scoped to the changed linkcheck branch and does not prove network termination, parser completeness, or all Sphinx behavior.
