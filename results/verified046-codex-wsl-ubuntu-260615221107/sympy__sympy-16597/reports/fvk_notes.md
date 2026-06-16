# FVK Notes

## Source decision

No additional production-code edits were made after V1.

This decision traces to:

- `fvk/FINDINGS.md` F-1 and F-2: the reported `even=True` and `integer=True`
  failures are resolved by V1.
- `fvk/FINDINGS.md` F-3: the public hint supports placing the rule at
  `rational`, which covers rational, integer, odd, and even through the existing
  old-assumption graph.
- `fvk/PROOF_OBLIGATIONS.md` PO-1 through PO-4: the constructed proof obligations
  discharge `rational -> finite`, then derive `integer -> finite` and
  parity finiteness from existing edges.

## Rejected alternatives

I did not add `integer -> finite`, `even -> finite`, or `odd -> finite`.

Reason: `fvk/PROOF_OBLIGATIONS.md` PO-4 shows those leaf rules are redundant once
`rational -> finite` exists. Adding them would duplicate graph edges without
covering any case not already covered by V1.

I did not add old-rule `real -> finite`.

Reason: `fvk/FINDINGS.md` F-4 and `fvk/PROOF_OBLIGATIONS.md` PO-5 trace to the
public hint warning that old-assumption `real` is broader and that adding
`finite` there would probably break code. The issue examples require
rational-derived number classes, not a global real narrowing.

I did not update the newer `ask(Q.*)` generated fact tables.

Reason: `fvk/FINDINGS.md` F-5 and `fvk/PROOF_OBLIGATIONS.md` PO-7 classify that
as a separate API cleanup. The issue examples use `.is_finite`, the public hint
names `_assume_rules`, and changing the generated `ask_generated.py` table would
require a regeneration workflow that this no-execution benchmark explicitly
forbids.

## Artifact decisions

The required FVK files were written under `fvk/`, along with the formal core and
adequacy files required by the FVK documentation:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`
- `fvk/mini-assumptions.k`
- `fvk/assumptions-spec.k`
- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`

The K artifacts are labeled constructed, not machine-checked. No tests, Python,
or K tooling were run.
