# FVK Notes

## Decisions and changes

V1 did not stand unchanged. `fvk/FINDINGS.md` F2 and F3 showed that V1's
condition for dropping `.format(...)` was too broad: it handled the reported
`"Hello".format("world")` case, but it also would erase escaped-brace formatting
and missing-placeholder behavior. Those cases violate `fvk/PROOF_OBLIGATIONS.md`
PO2 and PO3.

I changed `repo/crates/ruff_linter/src/rules/pyflakes/format.rs` to add
`FormatSummary::is_literal_identity`. This discharges PO3 and PO5 by recording
whether a parsed no-field format template is actually identity-preserving. The
flag is true only for an empty template or for a single parsed literal part equal
to the original string literal value, which excludes doubled-brace cases from F2.

I changed `repo/crates/ruff_linter/src/rules/pyflakes/fixes.rs` so the full-call
replacement now requires all of the PO1 conditions: non-empty unused positional
arguments, no keyword arguments, no parsed auto/index/keyword fields,
`is_literal_identity`, and coverage of every explicit positional argument index.
This keeps the intended fix from F1 while addressing F2, F3, PO2, PO3, and PO4.
The existing CST rewrite remains the fallback, which is the PO7 frame condition.

I changed `repo/crates/ruff_linter/src/rules/pyflakes/rules/strings.rs` to pass
the existing `FormatSummary` into the fix helper. This is required by PO6:
the edit decision must use the same parsed summary that the checker used to
classify positional arguments.

## Decisions to keep behavior unchanged

I kept the existing fallback argument-removal transform unchanged. `FINDINGS.md`
F4 and `PROOF_OBLIGATIONS.md` PO4/PO7 justify this: when keyword arguments or
semantically relevant format fields remain, F523 should remove only unused
positional arguments and preserve the `.format(...)` operation.

I did not change F522 named-argument fixes. `ITERATION_GUIDANCE.md` records that
as adjacent but outside this F523 issue; no finding in `FINDINGS.md` makes an
F522 production-code change necessary for this task.

I did not modify tests or run tests/K tooling. `FINDINGS.md` F5 and
`PROOF_OBLIGATIONS.md` PO8 record the execution constraint and the constructed,
not machine-checked status.
