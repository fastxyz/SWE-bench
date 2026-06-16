# FVK Findings

Status: constructed, not machine-checked. No tests or project code were run.

## F1: Pre-fix inline wrapper added TeX-visible boundary spaces

Classification: code bug, fixed by V1.

Evidence: problem statement E1 reports that "a space character is inserted at
start and end of the inline code" in LaTeX output. The shown pre-fix output has
bare line endings immediately after `\sphinxupquote{` and immediately before
`}}`.

Concrete input -> observed vs expected:

* Input: highlighted inline body `Body = \PYG{k}{def} ... \PYG{k}{pass}` from
  the reproducer's `:python:` role.
* Pre-fix observed: TeX sees `" " + Body + " "` because a newline inside a
  normal macro argument is a space.
* Expected: TeX-visible text is exactly `Body`.
* V1 result: `\sphinxupquote{%` hides the opening line ending, and `Body%`
  hides the line ending before `}}`, so TeX-visible text is `Body`.

Related obligations: O1, O2, O3.

## F2: Public test assertion records the legacy buggy inline shape

Classification: SUSPECT public-test obligation; test file unchanged by rule.

Evidence: `repo/tests/test_build_latex.py` contains an assertion for
`Inline \sphinxcode{\sphinxupquote{\n` followed by `common_content + '\n}}'`.
That exact shape is what the public issue identifies as producing the unwanted
spaces.

Concrete input -> observed vs expected:

* Input: the public fixture `tests/roots/test-reST-code-role/index.rst`.
* Legacy test expectation: bare formatter newlines around inline highlighted
  content.
* Intent-derived expectation: TeX comments at both wrapper boundaries, or an
  equivalent output form that does not add visible boundary spaces.

Resolution: do not use this assertion to veto the fix. Do not edit it in this
benchmark task because test files are forbidden.

Related obligations: O1, O2, O4.

## F3: V1 covers the intended inline-code domain under the formatter-shape precondition

Classification: confirmation with explicit precondition.

Evidence: the branch condition in `visit_literal()` requires both class `code`
and a language value, matching the reproducer's `.. role:: python(code)
:language: python`. `roles.code_role()` constructs such a node.

Concrete input -> observed vs expected:

* Input class: any highlighted inline code-role literal whose LaTeX highlighter
  output has the standard Pygments `Verbatim` wrapper.
* V1 observed by symbolic review: opening wrapper replacement adds `%`; trailer
  removal is followed by `rstrip(CR) + '%' + CR`, placing a comment marker before
  the closing wrapper line.
* Expected: no formatter wrapper line ending is TeX-visible as a boundary space.

Residual risk: the constructed proof assumes the existing writer precondition
that the Pygments LaTeX formatter emits the standard `Verbatim` wrapper that the
writer already replaces and strips. This was an existing dependency before V1.

Related obligations: O0, O1, O2, O3.

## F4: Non-target rendering paths remain framed

Classification: confirmation.

Evidence: V1 changes only the highlighted `code` role branch in
`visit_literal()`. The branches for title literals, keyboard literals,
non-highlighted literals, and `visit_literal_block()` are untouched.

Concrete input -> observed vs expected:

* Input: `.. code-block:: python` from the reproducer.
* V1 observed by static diff: literal block code still goes through
  `visit_literal_block()`, not the edited inline branch.
* Expected: block output remains `sphinxVerbatim` with its block line structure.

Related obligations: O4, O5.

## F5: Verification is constructed, not machine-checked

Classification: proof capability / environment gap.

Evidence: the task forbids running tests, Python, or K tooling. The K artifacts
and commands are emitted for later checking, but no command was executed.

Concrete input -> observed vs expected:

* Input: `fvk/latex-inline-code-spec.k`.
* Current status: proof constructed by symbolic reasoning only.
* Expected machine-check upgrade: running the emitted `kompile` and `kprove`
  commands should return `#Top`.

Related obligations: O6.
