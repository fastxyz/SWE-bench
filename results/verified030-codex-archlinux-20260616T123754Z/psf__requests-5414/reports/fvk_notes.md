# FVK Notes

## Decisions

1. Kept the V1 ASCII-host predicate unchanged:
   `host.startswith(u'*') or host.startswith(u'.') or u'..' in host`.

   Trace: `fvk/FINDINGS.md` F-1 and F-2 identify the reported leading empty
   label and the related interior empty-label family as resolved by this
   predicate. `fvk/PROOF_OBLIGATIONS.md` PO-1, PO-2, and PO-3 state the
   corresponding proof obligations and mark them discharged by the leading-dot
   and doubled-dot checks. PO-4 confirms the existing wildcard behavior is
   preserved.

2. Did not broaden the fix to full ASCII IDNA validation.

   Trace: `fvk/FINDINGS.md` F-4 records this as a rejected alternative.
   `fvk/PROOF_OBLIGATIONS.md` PO-5 and PO-6 require preserving the existing
   non-ASCII IDNA path and avoiding new rejection of otherwise allowed ASCII
   hosts. PO-7 specifically preserves the trailing-dot class, such as
   `example.com.`, because the issue does not provide public intent to reject
   it.

3. Changed only the source comment adjacent to the V1 predicate.

   Trace: `fvk/FINDINGS.md` F-3 found that the V1 comment said "empty labels"
   too broadly even though PO-7 intentionally permits a single trailing dot.
   The comment now says "leading/interior empty labels", matching PO-2, PO-3,
   and PO-7 without changing runtime behavior.

4. Added FVK artifacts without running tests, Python, or K tooling.

   Trace: `fvk/FINDINGS.md` F-5 and `fvk/PROOF_OBLIGATIONS.md` PO-9 require the
   honesty gate: the proof is constructed, not machine-checked. The exact
   `kompile`, `kast`, and `kprove` commands are recorded in `fvk/SPEC.md`,
   `fvk/PROOF.md`, and `fvk/ITERATION_GUIDANCE.md`, but were not executed.

## Files Changed

`repo/requests/models.py`

- Updated the validation comment to accurately describe the V1/V2 predicate as
  rejecting wildcard prefixes and leading/interior empty labels.
- Left the actual runtime predicate unchanged after the FVK audit confirmed it
  discharges the issue-derived obligations.

`fvk/SPEC.md`

- Captures the intent-only requirements, public evidence ledger, reduced formal
  spec, adequacy audit, compatibility audit, and recorded machine-check commands.

`fvk/FINDINGS.md`

- Records the resolved bug, the empty-label family, the V1 comment issue, the
  rejected full-IDNA alternative, and the constructed-not-machine-checked caveat.

`fvk/PROOF_OBLIGATIONS.md`

- Lists the concrete and symbolic obligations used to judge the fix and maps
  them to the source predicate.

`fvk/PROOF.md`

- Provides the constructed proof sketch for the reduced ASCII-host model and
  records residual risk.

`fvk/ITERATION_GUIDANCE.md`

- States that V1 stands except for the source comment clarification and lists
  future test and machine-check guidance.

`fvk/mini-python.k` and `fvk/requests-url-spec.k`

- Provide the minimal K semantics and claims required by the FVK methodology.

## Assumptions

- The FVK scope is the `PreparedRequest.prepare_url` ASCII-host validation
  branch that can produce the reported `UnicodeError` leak. The proof does not
  claim full correctness of Requests URL parsing or networking.
- A leading dot and an interior doubled dot are the issue-derived non-final
  empty-label cases. A single trailing dot remains allowed by this fix.
- Full ASCII IDNA validation is a broader compatibility decision and was not
  applied without public intent beyond this issue.
