# Public Evidence Ledger

Status: mirrored from `fvk/SPEC.md`.

E-001, prompt evidence: "Output is field1:\"hello world\"~1^1.5".
Obligation: boosted phrase output contains both slop and boost.
Spec mapping: SPEC-C-003, PO-003, PO-005.

E-002, prompt evidence: "the slop is missing from output".
Obligation: output that preserves boost but loses slop is the defect.
Spec mapping: Finding F-001.

E-003, public hint evidence: "`setBoost()` function was replaced with `new BoostQuery()`, but
BoostQuery is not handled in setSlop function."
Obligation: `BoostQuery` must be transparent to slop handling and boost-preserving.
Spec mapping: SPEC-C-003, SPEC-C-004, PO-003.

E-004, prompt evidence: "when I don't pass boosts to MultiFieldQueryParser, slop is working as
expected".
Obligation: do not regress direct non-boost phrase slop behavior.
Spec mapping: SPEC-C-001, PO-001.

E-005, source evidence: existing helper handles `MultiPhraseQuery`.
Obligation: wrapper transparency should cover the phrase-like query family already handled by the
helper.
Spec mapping: SPEC-C-002, SPEC-C-004, PO-002, PO-003.

E-006, compatibility evidence: V1 changes only a private helper body.
Obligation: no public API migration is needed.
Spec mapping: PO-008 and `PUBLIC_COMPATIBILITY_AUDIT.md`.
