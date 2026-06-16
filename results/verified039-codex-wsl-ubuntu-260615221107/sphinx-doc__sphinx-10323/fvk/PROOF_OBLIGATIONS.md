# Proof Obligations

Status: constructed, not machine-checked.

## PO1: Non-diff pipeline composition

Claim: For every non-diff input, `LiteralIncludeReader.read()` composes filters as:

`append(prepend(dedent(select(file_lines)), append/prepend options))`

More explicitly:

`read(F, S, D, P, HP, A, HA) = append(prepend(dedent(select(F, S), D), P, HP), A, HA)`

Evidence: E1, E3, E6.

Status: discharged by V1 source inspection and represented by K claim `read-pipeline`.

## PO2: Dedent warning source excludes prepend and append

Claim: The `dedent_lines()` warning predicate can inspect only selected include-file lines, not synthetic `prepend` or `append` lines.

Evidence: E2, E3.

Status: discharged by placing `dedent_filter` before `prepend_filter` and `append_filter`; represented by K claim `dedent-warning-scope`.

## PO3: No-dedent frame preservation

Claim: When `'dedent'` is absent, output with `prepend`/`append` is unchanged from legacy/public behavior.

Evidence: E5, E7.

Status: discharged because `dedent_filter` returns its input unchanged when `'dedent'` is absent; represented by K claim `no-dedent-frame`.

## PO4: Selection-before-dedent frame preservation

Claim: `pyobject`, `start`, `end`, and `lines` selection still happen before dedent.

Evidence: E6, E8.

Status: discharged by current filter order: `pyobject_filter`, `start_filter`, `end_filter`, `lines_filter`, `dedent_filter`, `prepend_filter`, `append_filter`.

## PO5: Diff branch frame preservation

Claim: The `diff` branch bypasses the normal filter list and remains unchanged.

Evidence: I5 and implementation branch in `read()`.

Status: discharged because the V1 edit is inside the `else` branch only; represented by K claim `diff-frame`.

## PO6: Public compatibility frame

Claim: The fix changes no public API, directive option names, return tuple shape, or caller contract.

Evidence: public compatibility audit.

Status: discharged by source inspection; no signatures or option specs were changed.

## PO7: Honesty gate

Claim: The proof must not be represented as machine-checked and tests must not be removed.

Evidence: task no-execution rule and FVK honesty gate.

Status: discharged by artifact labels and by not modifying tests.

## PO8: Do not invent a docutils whitespace-recovery contract

Claim: The repair must not depend on reconstructing leading spaces already discarded by docutils option parsing.

Evidence: E4 and OOS1.

Status: discharged by leaving option parsing unchanged and by scoping the source fix to filter order.
