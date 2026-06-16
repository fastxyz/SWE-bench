# Baseline Notes

## Root cause

`LiteralIncludeReader.read()` applied `prepend_filter` and `append_filter` before `dedent_filter`. As a result, lines supplied by the `:prepend:` and `:append:` directive options were treated as part of the included file content for dedentation. When a user used `:dedent:` to adjust only the indentation of the selected literalinclude content, Sphinx also stripped characters from the prepended/appended option text and could emit the `non-whitespace stripped by dedent` warning.

## Files changed

`repo/sphinx/directives/code.py`

The literalinclude filter order now applies `dedent_filter` after the content-selection filters (`pyobject`, `start`, `end`, and `lines`) but before `prepend_filter` and `append_filter`. This keeps dedent scoped to content read from the include file while preserving the existing behavior that prepended and appended lines are present in the final literal block and line count.

`reports/baseline_notes.md`

Added this report to document the root cause, implementation, and assumptions for the benchmark task.

## Assumptions and alternatives considered

I assumed the issue is specifically about the interaction of `:dedent:` with `:prepend:` and `:append:`, as described in the public hint, not about making docutils preserve leading spaces in option values. Docutils has already parsed directive options before Sphinx receives them, so changing Sphinx option parsing would not recover indentation that docutils discarded.

I considered changing `dedent_lines()` to skip only prepended/appended lines, but that would require tracking which lines were synthetic and would add state to a simple filter pipeline. Reordering the existing filters is smaller and directly matches the intended behavior: select file content, dedent file content, then add synthetic lines unchanged.

I did not change tests, per task constraints, and did not run tests or project code because this benchmark session forbids execution.
