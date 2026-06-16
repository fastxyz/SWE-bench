# FVK Spec: LaTeX Highlighted Inline Code

Status: constructed, not machine-checked.

## Target

The audited production path is `LaTeXTranslator.visit_literal()` in
`repo/sphinx/writers/latex.py`, restricted to the branch for inline literal
nodes whose classes include `code` and whose `language` option is present. That
branch calls the LaTeX highlighter, replaces Pygments' `Verbatim` opening with
`\sphinxcode{\sphinxupquote{...}}`, removes the `\end{Verbatim}` trailer, and
emits the result inline.

The FVK mini-semantics are in:

* `fvk/mini-latex-inline.k`
* `fvk/latex-inline-code-spec.k`

## Intent Spec

* I1. Highlighted inline code in LaTeX must not render an extra visible space at
  the start of the code text.
* I2. Highlighted inline code in LaTeX must not render an extra visible space at
  the end of the code text.
* I3. Syntax highlighting for the Docutils `code` role should remain active for
  roles with a language, matching the purpose of the #10251 enhancement.
* I4. Literal blocks are not the defect. Their surrounding `sphinxVerbatim`
  output and line structure should remain unchanged.
* I5. The repair must be source-only and must not rely on modifying tests.

## Public Evidence Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | problem | "For LaTeX output, a space character is inserted at start and end of the inline code." | Remove wrapper-introduced leading and trailing visible spaces. | Encoded by O1, O2. |
| E2 | problem | Expected markup shows `\sphinxupquote{%` and highlighted content ending with `%` before `}}`. | TeX `%` comments are an acceptable output form for hiding formatter newlines. | Encoded by O1, O2. |
| E3 | problem | Reproducer defines `.. role:: python(code) :language: python :class: highlight` and uses `Inline :python:\`...\``. | Domain is highlighted inline `code` role output with a language. | Encoded by O0. |
| E4 | problem | Reproducer also includes `.. code-block:: python` for comparison. | Do not change literal block rendering while fixing inline rendering. | Encoded by O4. |
| E5 | public-test | `test_latex_code_role` asserts the old inline output shape with bare newlines around `common_content`. | This assertion records the reported buggy behavior and is SUSPECT under FVK. | Finding F2; tests not edited. |
| E6 | code | `roles.code_role()` creates `nodes.literal(..., classes=['code', ...], language=language)`. | The LaTeX branch condition identifies the intended highlighted inline role nodes. | Encoded by O0. |
| E7 | code | `PygmentsBridge.highlight_block()` returns LaTeX highlighter output for non-HTML builders. | The writer is adapting block formatter output for inline use. | Encoded by O1-O3. |

## Formal Domain

Let `Body` be the highlighted token stream produced by Pygments after removing
the formatter wrapper. `Body` includes all source-intended inline code
characters and spaces. It excludes only formatter-introduced wrapper line
endings around the `Verbatim` environment.

The formal input is `beginVerbatim(Body)`, an abstraction of:

```text
\begin{Verbatim}[commandchars=\\\{\}]
Body
\end{Verbatim}
```

The verified output form is `sphinxPct(Body)`, an abstraction of:

```text
\sphinxcode{\sphinxupquote{%
Body%
}}
```

## Proof Obligations Summary

* O0. The branch applies only to highlighted inline code-role literals with a
  language.
* O1. The opening formatter newline is hidden from TeX by placing `%` at the end
  of `\sphinxupquote{`.
* O2. The closing formatter newline is hidden from TeX by placing `%` at the end
  of the highlighted content line before the wrapper closes.
* O3. The highlighted `Body` is preserved exactly, including source-intended
  spaces inside `Body`.
* O4. Non-highlighted literals, keyboard literals, title literals, and literal
  blocks are frame-preserved.
* O5. The patch does not alter public APIs, method signatures, or producer /
  consumer data shapes.

The detailed proof obligations are recorded in `fvk/PROOF_OBLIGATIONS.md`.

## Formal Spec English

* K claim C1: For every highlighted body `Body`, rendering fixed inline LaTeX
  and then interpreting TeX-visible text yields exactly `Body`, with no added
  leading or trailing spaces from wrapper newlines.
* K claim C2: The legacy raw wrapper renders as one added leading space, then
  `Body`, then one added trailing space. This is a regression witness matching
  the public issue symptom.

## Spec Audit

| Claim | English meaning | Intent match |
| --- | --- | --- |
| C1 | Fixed output has TeX-visible text exactly equal to `Body`. | Pass: directly satisfies I1 and I2 and preserves I3. |
| C2 | Legacy raw wrapper adds visible boundary spaces. | Pass as a negative/regression witness: matches E1 and is not used to preserve legacy behavior. |
| O4 | Literal blocks and other literal branches remain unchanged. | Pass: required by E4 and confirmed by branch-local source diff. |
| O5 | No API or signature changes. | Pass: diff is local string output logic only. |

No formal-English claim is derived solely from current implementation behavior.
The one public test assertion that matches legacy buggy output is marked SUSPECT
instead of treated as intent.

## Public Compatibility Audit

No public symbol, method signature, class hierarchy, call protocol, node shape,
or highlighter API was changed. The only production edit is inside
`LaTeXTranslator.visit_literal()` after the highlighter output is already
available. Public callers and extensions that create `nodes.literal` values see
the same branch selection and node attributes as before.
