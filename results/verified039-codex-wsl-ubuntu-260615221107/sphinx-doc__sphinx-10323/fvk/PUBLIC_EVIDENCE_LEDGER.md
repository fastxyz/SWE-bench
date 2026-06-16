# Public Evidence Ledger

## E1

Source: prompt.

Quoted evidence: "Cannot determine a mechanism to use literalinclude directive with `prepend` or `append` to match code example indentation, as leading whitespace is removed."

Semantic obligation: The fix must address the interaction between `literalinclude`, `prepend`/`append`, and indentation. Status: encoded in I1 and I2.

## E2

Source: prompt.

Quoted evidence: "I cannot think of good warning free way to indent `:prepend:` to match the included code example."

Semantic obligation: The supported workaround must avoid the `non-whitespace stripped by dedent` warning when the non-whitespace belongs to directive-option text rather than include-file content. Status: encoded in I2 and PO2.

## E3

Source: prompt.

Quoted evidence: "Use of `dedent` could be a good solution, if `dedent` was applied only to the literalinclude and not to the `prepend` and `append` content."

Semantic obligation: `dedent` is scoped to literalinclude file content only; `prepend` and `append` content are added outside the dedent domain. Status: encoded in I1, I2, PO1, and PO2.

## E4

Source: public hint.

Quoted evidence: "Docutils; the reST parser library ignores the leading whitespaces of directive options. So it's difficult to handle it from directive implementation."

Semantic obligation: Do not require Sphinx to recover spaces that docutils has already discarded. Status: encoded in OOS1.

## E5

Source: public hint.

Quoted evidence: "The combination of `dedent` and `prepend` options are not intended. So it should be fixed."

Semantic obligation: The defect is the combined behavior, not the standalone `prepend`, standalone `append`, or standalone `dedent` behavior. Status: encoded in I3 and I4.

## E6

Source: implementation.

Quoted evidence: `LiteralIncludeReader.read()` runs filters in a list over `lines` and returns `''.join(lines), len(lines)`.

Semantic obligation: The line-transform proof may model the filter pipeline as a sequence over a list of lines and should preserve final line count semantics. Status: encoded in PO1, PO4, and PO5.

## E7

Source: public tests.

Quoted evidence: `test_LiteralIncludeReader_prepend` expects `Hello`, selected line 1, then `Sphinx`.

Semantic obligation: `prepend`/`append` behavior without `dedent` remains unchanged. Status: encoded in I4 and PO3.

## E8

Source: public tests.

Quoted evidence: `test_LiteralIncludeReader_dedent` expects `dedent` to strip selected include-file content according to the option value.

Semantic obligation: Dedent still applies to selected include-file lines. Status: encoded in I3 and PO1.
