# Intent Spec

Status: constructed from public evidence only. This is not machine-checked.

## Required behavior

I1. For non-diff `literalinclude`, Sphinx reads include-file lines, applies content-selection filters, applies `:dedent:` to the selected include-file content, and only then adds `:prepend:` and `:append:` option text.

I2. `:prepend:` and `:append:` text are synthetic directive-option lines, not include-file content. They must not be stripped by `:dedent:` and must not be considered when deciding whether `dedent_lines()` should warn about non-whitespace stripped by dedent.

I3. The selected file content still receives all existing include-content transformations in the established order before synthetic lines are added: `pyobject`, `start`, `end`, `lines`, then `dedent`.

I4. Existing behavior without `:dedent:` must be preserved: `:prepend:` still inserts one line before the selected content, and `:append:` still inserts one line after it.

I5. Existing public compatibility must be preserved: no public directive option names, method signatures, node shapes, line-count accounting, or diff behavior should change.

## Out of scope

OOS1. Recovering leading whitespace stripped by docutils option parsing is out of scope for this fix. The public hint says docutils ignores leading whitespace in directive options and recommends fixing the `dedent` plus `prepend`/`append` interaction instead.

OOS2. This proof pass models the line-list transformation in `LiteralIncludeReader.read()`. It does not prove full Sphinx rendering, Pygments highlighting, docutils parsing, filesystem I/O, or termination.
