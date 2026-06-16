# Intent Specification

Status: intent-only obligations from public evidence.

INTENT-001: A quoted phrase parsed by `MultiFieldQueryParser` with explicit slop must retain that
slop in the resulting query.

Evidence: `benchmark/PROBLEM.md` shows expected output `field1:"hello world"~1^1.5` and no-boost
output `field1:"hello world"~1`.

INTENT-002: A configured per-field boost must remain present in the resulting query.

Evidence: `benchmark/PROBLEM.md` shows expected output `field1:"hello world"~1^1.5`.

INTENT-003: Field boost wrapping must not prevent slop application.

Evidence: public hint says `setBoost()` was replaced with `new BoostQuery()`, but `BoostQuery` is
not handled in the slop function.

INTENT-004: Existing direct `PhraseQuery` and `MultiPhraseQuery` slop behavior must be preserved.

Evidence: the issue says slop works as expected when boosts are not passed; source already handles
direct `PhraseQuery` and `MultiPhraseQuery`.

INTENT-005: The repair must be source-only and must not modify test files.

Evidence: benchmark instructions forbid modifying test files and forbid running tests or code.
