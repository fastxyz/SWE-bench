# FVK Notes

## Source Decisions

- Kept the V1 approach of recognizing `Literal`, `typing.Literal`, and
  `typing_extensions.Literal`, then suppressing xref conversion only inside that
  bracketed argument region. This is justified by `fvk/FINDINGS.md` `F-001` and
  `fvk/PROOF_OBLIGATIONS.md` `PO-001`, `PO-002`, and `PO-003`.

- Added `ast.UnaryOp` handling for `+` and `-` while `literal_args` is true. V1
  missed signed numeric literals such as `Literal[-1]`, which would have fallen
  back to a whole-annotation xref. This change is justified by `F-002` and
  `PO-004`.

- Added `parse_literal_annotation_fallback()` for recognized full `Literal[...]`,
  `typing.Literal[...]`, and `typing_extensions.Literal[...]` strings after an AST
  `SyntaxError`. This covers literal value text that is not a parseable Python
  expression while preserving the old fallback for non-Literal annotations. This is
  justified by `F-003` and `PO-005`.

- Kept normal non-Literal annotation behavior unchanged: outside literal argument
  depth, non-empty text still goes through `type_to_xref()`. This is justified by
  `F-004` and `PO-006`.

- Did not attempt arbitrary alias resolution such as `L[True]`. The parser does not
  have reliable import-alias context, and broad name guessing would risk suppressing
  real type xrefs. This is recorded as open/underspecified in `F-005`, not as a
  blocker for the public issue.

## Artifact Decisions

- Wrote the five requested FVK artifacts under `fvk/`: `SPEC.md`, `FINDINGS.md`,
  `PROOF_OBLIGATIONS.md`, `PROOF.md`, and `ITERATION_GUIDANCE.md`.

- Also emitted standalone K-style files `fvk/mini-python-annotation.k` and
  `fvk/python-annotation-spec.k` because the FVK method requires a formal core with
  exact `kompile`/`kprove` commands. They are marked constructed, not
  machine-checked, in `fvk/PROOF.md`.

## Verification Boundary

No tests, Python, or K tooling were run. The proof is a constructed reasoning
artifact only; `F-006` records that it must not be treated as machine-checked until
the emitted commands run and return `#Top`.
