# FVK Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`,
tests, Python, or project code were run.

## Claims

The formal core is:

* `fvk/mini-latex-inline.k`
* `fvk/latex-inline-code-spec.k`

Claim C1:

```k
claim
  <k> RenderThenVisible(beginVerbatim(Body:String)) => Body </k>
  [all-path]
```

English: for every highlighted token stream `Body`, the fixed inline rendering
has TeX-visible text exactly equal to `Body`.

Claim C2:

```k
claim
  <k> TeXVisible(sphinxRaw(Body:String))
    => " " +String Body +String " " </k>
  [all-path]
```

English: the legacy wrapper with raw formatter newlines adds one visible leading
and one visible trailing space around `Body`.

## Constructed Proof Sketch

1. Start with the highlighted inline-code formatter shape
   `beginVerbatim(Body)`.
2. By the mini-semantics rule for `RenderThenVisible`, fixed rendering rewrites
   to `TeXVisible(sphinxPct(Body))`.
3. By the TeX interpretation abstraction for `sphinxPct`, TeX comments at the
   opening and closing wrapper boundaries remove the formatter line endings from
   the visible text.
4. Therefore `TeXVisible(sphinxPct(Body)) => Body`.
5. By transitivity, `RenderThenVisible(beginVerbatim(Body)) => Body`, which is
   C1.
6. Separately, `TeXVisible(sphinxRaw(Body))` rewrites to
   `" " +String Body +String " "`, proving C2 as the regression witness.

There are no loops or recursive calls in the modeled transformation, so there
are no circularity obligations. The proof is a straight-line symbolic execution
plus a TeX-comment abstraction.

## Source-Level Discharge

O1 is discharged by the replacement string in `repo/sphinx/writers/latex.py`:

```python
hlcode = hlcode.replace(r'\begin{Verbatim}[commandchars=\\\{\}]',
                        r'\sphinxcode{\sphinxupquote{%')
```

O2 is discharged by the trailer handling:

```python
hlcode = hlcode.rstrip()[:-14]  # strip \end{Verbatim}
hlcode = hlcode.rstrip(CR) + '%' + CR
```

The final `self.body.append('}}')` places the active closing braces on the line
after the `%` comment, matching the public issue's acceptable output form.

## Adequacy

The proof does not preserve the current public test assertion that contains
bare newlines in the inline wrapper. Per the FVK intent-evidence rule, that
assertion is SUSPECT because it encodes the behavior the issue reports as
buggy. The formal postcondition is instead derived from the issue text and
expected markup.

The proof covers the full intended behavior space for this issue: highlighted
inline `code` role LaTeX output with the standard Pygments `Verbatim` wrapper.
Frame obligations cover non-highlighted literals and literal blocks.

## Residual Risk

* The K proof is constructed but not machine-checked.
* The mini-semantics abstracts TeX behavior to the relevant comment/newline
  property rather than modeling full TeX.
* The proof assumes the existing writer dependency that Pygments LaTeX output
  has the standard `Verbatim` wrapper being replaced and stripped.
* Termination is not a meaningful separate obligation for the straight-line
  modeled transformation.

## Machine-check Commands

These commands are recorded for a later environment with K installed. They were
not executed in this task.

```sh
cd fvk
kompile mini-latex-inline.k --backend haskell
kast --backend haskell latex-inline-code-spec.k
kprove latex-inline-code-spec.k
```

Expected result after a successful machine check: `kprove` returns `#Top`.

## Test Guidance

No test files were modified. The existing inline assertion in
`test_latex_code_role` should be considered stale relative to the public bug
intent because it asserts the raw-newline shape. A future test update should
expect either the `%`-commented wrapper boundaries or another LaTeX output form
that is TeX-visible as exactly `Body`. The literal-block assertion should be
kept because the proof frames block rendering rather than subsuming it.
