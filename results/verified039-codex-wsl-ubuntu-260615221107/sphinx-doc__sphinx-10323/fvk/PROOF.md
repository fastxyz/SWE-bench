# Constructed Proof

Status: constructed, not machine-checked.

## Summary

The V1 source patch changes the normal `LiteralIncludeReader.read()` filter order from:

`select, prepend, append, dedent`

to:

`select, dedent, prepend, append`

where `select` abbreviates `pyobject`, `start`, `end`, and `lines` filters.

This proves the intended contract for the modeled line-list pipeline: `dedent` is applied only to include-file content selected from the file, and synthetic `prepend`/`append` lines are added afterward.

## Claim READ-PIPELINE

Initial symbolic state:

`read(F, selector, D, P, HP, A, HA)`

Symbolic execution under `mini-literalinclude.k`:

1. `read` rewrites to `F ~> selectStage(selector) ~> dedentStage(D) ~> prependStage(P, HP) ~> appendStage(A, HA)`.
2. `selectStage` rewrites `F` to `select(F, selector)`.
3. `dedentStage` rewrites that selected line list to `dedent(select(F, selector), D)`.
4. `prependStage` rewrites it to `prepend(dedent(select(F, selector), D), P, HP)`.
5. `appendStage` rewrites it to `append(prepend(dedent(select(F, selector), D), P, HP), A, HA)`.

Postcondition reached:

`append(prepend(dedent(select(F, selector), D), P, HP), A, HA)`

This discharges PO1.

## Claim DEDENT-WARNING-SCOPE

`dedentWarns` is applied to `select(F, selector)` in the formal claim. Since `prepend` and `append` are downstream of `dedentStage`, neither `P` nor `A` can be part of the input to `dedentWarns`.

This discharges PO2.

## Claim NO-DEDENT-FRAME

Instantiate READ-PIPELINE with `D = noDedent`.

The semantics rule `dedent(LS, noDedent) => LS` reduces:

`append(prepend(dedent(select(F, selector), noDedent), P, HP), A, HA)`

to:

`append(prepend(select(F, selector), P, HP), A, HA)`

This discharges PO3.

## Claim DIFF-FRAME

The Python source still selects `show_diff()` before the normal filter list when `'diff' in self.options`. The V1 edit only reorders the filter list in the non-diff `else` branch. In the K model, `diffRead(F) => F` is independent of the normal `read` pipeline.

This discharges PO5.

## Compatibility proof

No public signature, option spec, return tuple shape, or caller was changed. `LiteralInclude.run()` still receives `text, lines = reader.read(location=location)`. Because `read()` still returns `''.join(lines), len(lines)` after all filters, the line count continues to include any inserted prepend/append lines.

This discharges PO6.

## Residual risk

This is a partial-correctness proof over a small abstract line-list semantics. It does not prove docutils option parsing, filesystem reads, Unicode decoding, Pygments highlighting, builder output, or termination. The K files were not compiled or proved in this environment.

## Commands to machine-check later

These commands were not run in this session.

```sh
kompile fvk/mini-literalinclude.k --backend haskell
kast --backend haskell fvk/literalinclude-spec.k
kprove fvk/literalinclude-spec.k
```

Expected machine-check result after a successful proof: `#Top`.

## Test guidance

No tests were removed or modified. Existing tests for standalone `prepend`/`append`, standalone `dedent`, and diff behavior should be kept until the K claims are actually machine-checked. A focused regression test for `literalinclude` with combined `dedent` plus `prepend`/`append` would cover the public issue, but this task forbids modifying test files.
