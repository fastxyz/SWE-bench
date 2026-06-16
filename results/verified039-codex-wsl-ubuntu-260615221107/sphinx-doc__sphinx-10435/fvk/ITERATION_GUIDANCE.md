# FVK Iteration Guidance

Status: V1 stands unchanged after FVK audit.

## Decision

Keep the V1 source patch in `repo/sphinx/writers/latex.py` unchanged. The FVK
spec and proof obligations identify the same root cause as V1: Pygments block
formatter newlines became TeX-visible spaces only after the LaTeX writer reused
block output inside an inline macro argument. V1 hides both boundary line
endings with TeX comments while preserving the highlighted body and framing
non-target rendering paths.

## Why No Additional Source Edit Was Needed

* F1 is the operative bug, and O1/O2 show V1 removes both visible boundary
  spaces.
* F3 confirms the branch domain matches the public reproducer: highlighted
  inline `code` role nodes with a language.
* F4 and O4 show literal blocks and other literal branches are untouched.
* O5 shows no compatibility repair is needed because no public API or protocol
  changed.

## Next Actions For A Future Environment

* Machine-check the constructed K artifacts with the commands in
  `fvk/PROOF.md`.
* Update or add a public LaTeX builder assertion for the inline code role so it
  expects `%` at both wrapper boundaries, or otherwise verifies no TeX-visible
  boundary spaces.
* Keep the literal-block assertion separate; it exercises a framed path outside
  the inline proof.
* If Pygments later gains a LaTeX `nowrap` formatter option, reconsider whether
  the writer can stop adapting `Verbatim` block output for inline code.
