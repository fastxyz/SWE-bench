# Baseline Notes

## Root cause

The Docutils `code` role is converted by Sphinx into a highlighted inline
literal when it has a `language` option. In the LaTeX writer,
`LaTeXTranslator.visit_literal()` reuses the Pygments LaTeX block formatter for
that inline content, then replaces the opening `Verbatim` environment with
`\sphinxcode{\sphinxupquote{...}}`.

The Pygments block formatter emits newlines after the opening environment and
before `\end{Verbatim}`. After the environment is replaced with an inline
command wrapper, those newlines sit inside a normal TeX macro argument. TeX
therefore treats them as interword spaces, producing an unwanted space before
and after the rendered inline code in PDF output.

## Changed files

* `repo/sphinx/writers/latex.py`
  * Added a TeX comment marker to the replacement opening
    `\sphinxcode{\sphinxupquote{...}}` so the formatter newline immediately
    after the wrapper start is ignored by TeX.
  * Added a TeX comment marker before the closing wrapper line after stripping
    Pygments' `\end{Verbatim}` trailer, so the formatter newline after the
    highlighted inline content is also ignored.
  * Left ordinary inline literals, keyboard literals, title literals, and
    literal blocks unchanged.

## Assumptions and alternatives

* Assumed the unwanted spaces come from TeX's treatment of the Pygments
  formatter newlines, not from the highlighted tokens themselves. The issue's
  generated LaTeX example and the writer's inline replacement logic both point
  to that path.
* Assumed the safest scope is only the highlighted `code` role branch in
  `visit_literal()`, because non-highlighted inline literals do not go through
  the Pygments block formatter and literal blocks require their surrounding
  newlines.
* Considered stripping the generated newlines entirely, but rejected that
  because TeX comments preserve the existing line-oriented output shape while
  removing only the TeX-visible spaces caused by line endings.
* Considered changing `PygmentsBridge.highlight_block()` or formatter options,
  but rejected that as broader than necessary. The surrounding code already
  notes that the desired `nowrap` support is not available for the LaTeX
  formatter in this version.
