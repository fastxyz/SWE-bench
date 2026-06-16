# Formal Spec English

Status: constructed, not machine-checked.

## Claim READ-PIPELINE

For every non-diff `literalinclude` input line list `F`, selector state `S`, dedent option `D`, prepend text `P`, append text `A`, and boolean presence flags `HP` and `HA`, the modeled read pipeline reaches:

`append(prepend(dedent(select(F, S), D), P, HP), A, HA)`

This means selection happens before dedent, and both synthetic option lines are added after dedent.

## Claim DEDENT-WARNING-SCOPE

For every non-diff `literalinclude` pipeline, the warning predicate for fixed-width dedent is computed from `select(F, S)` only, not from the line list after `prepend` or `append` has inserted synthetic lines.

## Claim NO-DEDENT-FRAME

When the dedent option is absent, the pipeline reaches:

`append(prepend(select(F, S), P, HP), A, HA)`

This preserves existing `prepend`/`append` behavior in the no-dedent case.

## Claim DIFF-FRAME

When the `diff` option is present, the normal non-diff filter pipeline is bypassed and the result is the unified diff output. The V1 patch does not change this branch.

## Claim PUBLIC-COMPATIBILITY

The public directive options and method signatures are unchanged. The returned tuple shape from `LiteralIncludeReader.read()` remains `(text, number_of_lines)`, where the line count includes any `prepend` and `append` lines present in the returned literal block.
