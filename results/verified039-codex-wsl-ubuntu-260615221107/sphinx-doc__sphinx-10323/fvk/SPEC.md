# FVK Spec

Status: constructed, not machine-checked.

## Scope

This FVK pass verifies the line-list pipeline in `LiteralIncludeReader.read()` for non-diff `literalinclude` handling. The proof target is the order in which selected include-file lines, `dedent`, `prepend`, and `append` compose.

The modeled unit is the pure transformation:

`read(F, selector, D, P, HP, A, HA)`

where `F` is the include-file line list, `selector` abstracts `pyobject`/`start`/`end`/`lines`, `D` is the dedent option, `P` and `A` are directive-option strings, and `HP`/`HA` say whether `prepend`/`append` are present.

## Public intent ledger

- E1, E2, E3: The bug is the interaction between `literalinclude`, `dedent`, and synthetic `prepend`/`append` lines. Obligation: `dedent` must apply to selected include-file content only.
- E4: Docutils may already have removed leading option whitespace. Obligation: this fix must not claim to recover discarded whitespace.
- E5: The intended repair is for the combined option behavior. Obligation: preserve standalone filter behavior.
- E6: The implementation is a sequential line-list filter pipeline. Obligation: model filter order over line lists.
- E7: Existing public tests require no-dedent `prepend`/`append` behavior. Obligation: preserve that frame.
- E8: Existing public tests require `dedent` behavior on selected content. Obligation: preserve that frame.

Full ledger: `fvk/PUBLIC_EVIDENCE_LEDGER.md`.

## Contract

S1. Non-diff pipeline:

`read(F, S, D, P, HP, A, HA) = append(prepend(dedent(select(F, S), D), P, HP), A, HA)`

S2. Dedent warning scope:

`dedentWarns` is evaluated over `select(F, S)`, not over any line list containing `P` or `A`.

S3. No-dedent frame:

If `D = noDedent`, then:

`read(F, S, noDedent, P, HP, A, HA) = append(prepend(select(F, S), P, HP), A, HA)`

S4. Diff frame:

The `diff` branch remains outside the non-diff filter list and is unchanged by the fix.

S5. Public compatibility frame:

No public directive option names, method signatures, return tuple shapes, or downstream caller expectations change.

## Formal files

- `fvk/mini-literalinclude.k`: a minimal K model of the line-list filter pipeline.
- `fvk/literalinclude-spec.k`: K claims for S1 through S4.
- `fvk/FORMAL_SPEC_ENGLISH.md`: English paraphrase of each claim.
- `fvk/SPEC_AUDIT.md`: adequacy check against the intent spec.
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`: API and callsite compatibility check.

## Limits

This is a partial-correctness proof over an abstracted line-list model. It does not prove filesystem I/O, docutils parsing, Pygments highlighting, final builder rendering, or machine-level K correctness. The proof is constructed but not machine-checked because this session forbids running K tooling.
