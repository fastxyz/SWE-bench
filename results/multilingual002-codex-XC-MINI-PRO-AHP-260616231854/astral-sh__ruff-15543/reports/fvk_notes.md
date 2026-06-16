# FVK Notes

The FVK audit confirms V1 should stand unchanged.

## Decisions

- Kept the V1 source change in `repo/crates/ruff_linter/src/rules/pyupgrade/rules/yield_in_for_loop.rs` unchanged. This is justified by `fvk/FINDINGS.md` F1 and F2: the reported singleton case and the broader unparenthesized tuple family are both discharged by `fvk/PROOF_OBLIGATIONS.md` PO1 and PO2.
- Did not broaden the fix beyond `Expr::Tuple { parenthesized: false, .. }`. This is justified by `fvk/FINDINGS.md` F3 and `fvk/PROOF_OBLIGATIONS.md` PO3, which preserve the existing source-slice behavior for non-bare iterable forms.
- Did not refactor the replacement construction. `fvk/PROOF_OBLIGATIONS.md` PO5 keeps the blast radius internal and minimal; no finding identified a readability, compatibility, or correctness issue requiring a source edit.
- Did not modify tests or run commands. This follows the task constraints and is recorded in `fvk/FINDINGS.md` F4; the K commands in `fvk/PROOF.md` and `fvk/PROOF_OBLIGATIONS.md` are for later machine checking only.

## Outcome

The proof model focuses on the observable that produced the bug: the replacement string. It distinguishes the pre-fix failing output `yield from x,` from the V1 output `yield from (x,)`, proves the generalized bare tuple wrapping obligation in the mini semantics, and records the remaining risk as unexecuted tooling rather than as a source-code defect.
