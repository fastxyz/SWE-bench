# FVK Findings

Status: constructed, not machine-checked.

## F1: Pre-fix pipeline applied dedent to synthetic option lines

Evidence: E2 and E3.

Concrete input: selected include lines begin with indentation, `:prepend:` supplies non-file text, and `:dedent: 5` is used as the workaround described in the issue.

Observed pre-fix behavior: `prepend_filter` and `append_filter` ran before `dedent_filter`, so `dedent_lines()` stripped the prepended/appended option text and could emit `WARNING: non-whitespace stripped by dedent`.

Expected behavior: `dedent_lines()` sees selected include-file content only; synthetic option lines are added afterward and are not warning sources.

Classification: code bug in V0, addressed by V1.

Trace: PO1, PO2.

## F2: V1 satisfies the intended pipeline order

Evidence: current `LiteralIncludeReader.read()` filter list is `pyobject`, `start`, `end`, `lines`, `dedent`, `prepend`, `append`.

Concrete input: any non-diff line list `F` with selector state `S`, dedent option `D`, and present `prepend`/`append` text.

Observed V1 behavior by source inspection: selected file lines flow to `dedent_filter` before `prepend_filter` and `append_filter` can insert synthetic lines.

Expected behavior: same as S1.

Classification: confirmation finding. No source change beyond V1 is required for this obligation.

Trace: PO1, PO2, PO4.

## F3: No-dedent behavior is preserved

Evidence: public test `test_LiteralIncludeReader_prepend` and unchanged local behavior of `prepend_filter` and `append_filter`.

Concrete input: `lines: 1`, `prepend: Hello`, `append: Sphinx`, no `dedent`.

Observed V1 behavior by source inspection: `dedent_filter` returns the input unchanged when `'dedent'` is absent, then `prepend_filter` and `append_filter` add the same lines as before.

Expected behavior: `Hello`, selected line 1, `Sphinx`.

Classification: compatibility confirmation.

Trace: PO3.

## F4: Diff path is unchanged

Evidence: `read()` still checks `if 'diff' in self.options` before constructing the normal filter list.

Concrete input: any `literalinclude` with `:diff:`.

Observed V1 behavior by source inspection: `show_diff()` is used directly; the changed filter list is not evaluated.

Expected behavior: no change to diff output.

Classification: compatibility confirmation.

Trace: PO5.

## F5: Formal proof remains constructed, not machine-checked

Evidence: task forbids running tests, Python, or K tooling.

Concrete input: the emitted K claims in `fvk/literalinclude-spec.k`.

Observed status: claims and proof are written but `kompile` and `kprove` were not executed.

Expected status: artifact honesty gate must say constructed, not machine-checked.

Classification: proof process caveat, not a code bug.

Trace: PO7.

## F6: Broader docutils whitespace recovery is not justified here

Evidence: public hint E4 says docutils ignores leading whitespace in directive options and that handling it in directive implementation is difficult.

Concrete input: `:prepend:` option text whose leading spaces were already stripped before `LiteralIncludeReader` receives `self.options`.

Observed V1 behavior by source inspection: V1 does not attempt to reconstruct discarded leading whitespace.

Expected behavior for this task: fix the dedent interaction so users have a warning-free path where `dedent` applies only to include-file content. Do not add a speculative option-parsing change that cannot recover information already lost by docutils.

Classification: scope and compatibility finding, not a remaining code bug.

Trace: PO8.
