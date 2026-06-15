# FVK Notes

## Decision

V1 stands unchanged. The audit identifies the original defect as F-001 and
discharges it through PO-003: supplied kwargs from a required mutually exclusive
group are now added to the synthetic parser arguments before
`parser.parse_args()` runs.

## Source changes

No production source files were changed in the FVK pass.

Reasoning:

- F-001 is the public issue, and V1's `get_mutually_exclusive_required_options()`
  plus the shared `required_options` loop satisfy PO-003.
- F-002 requires missing-group and conflicting-group cases to remain argparse
  decisions. V1 satisfies PO-004 because it neither fabricates absent group
  options nor chooses a winner when multiple group kwargs are supplied.
- F-003 confirms the V1 lookup change from `options` to `arg_options` for
  required-option synthesis. This supports PO-001 and PO-002 and does not require
  another code edit.
- PO-005, PO-006, and PO-007 are frame obligations. V1 preserves final kwarg
  overlay, unknown-option rejection, and the public `call_command()` API shape.
- F-004 is a proof-scope boundary rather than a source bug for this issue. The
  public report uses ordinary optional actions with scalar values, and V1
  correctly delegates full argparse validation instead of reimplementing it.

## Artifact changes

I added the required FVK artifacts:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

I also added the formal core required by the FVK docs:

- `fvk/mini-call-command.k`
- `fvk/call-command-spec.k`

And the separate adequacy/compatibility files required by the FVK method:

- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`

During artifact review, I corrected the mini semantics so required-group tokens
use the action's option string (`--shop-id`) rather than deriving an option name
from the dest (`shop_id`). That correction is artifact-only and supports F-001
and PO-003; it did not require a source edit because V1's source already uses
`min(opt.option_strings)`.

## Verification status

The proof is constructed, not machine-checked. Per the task constraints, I did
not run tests, Python, `kompile`, `kast`, or `kprove`. The exact future
machine-check commands are recorded in `fvk/PROOF.md`.
