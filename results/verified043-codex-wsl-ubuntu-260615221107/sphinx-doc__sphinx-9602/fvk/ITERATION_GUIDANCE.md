# FVK Iteration Guidance

Status: V2 source changes are justified by the findings and proof obligations.

## Decisions

- Keep the V1 strategy of suppressing xref conversion inside recognized
  `Literal[...]` argument brackets. Justification: `F-001`, `PO-001`, `PO-002`,
  and `PO-003`.
- Extend V1 for signed numeric literal values. Justification: `F-002` and
  `PO-004`.
- Add a constrained fallback for recognized `Literal[...]` strings that are not
  parseable by the AST parser. Justification: `F-003` and `PO-005`.
- Keep ordinary annotation xref behavior unchanged. Justification: `F-004` and
  `PO-006`.
- Do not attempt arbitrary alias resolution in `_parse_annotation()`. Justification:
  `F-005`; the parser has no import-alias context and the public issue does not
  require guessing aliases by name.

## Recommended Tests If Tests Become Editable

- `_parse_annotation("typing.Literal[True]", env)` returns an xref for
  `typing.Literal` and plain text `True`.
- `_parse_annotation("typing.Literal[False]", env)` returns plain text `False`.
- `_parse_annotation("Literal['x']", env)` preserves quoted string text and emits no
  xref for it.
- `_parse_annotation("Literal[-1]", env)` preserves `-1` as literal text and emits
  no whole-annotation fallback xref.
- `_parse_annotation("Literal[<Color.RED: 1>]", env)` uses the Literal fallback and
  emits no xref for `<Color.RED: 1>`.
- Existing tests for `List[int]`, `Callable[[int, int], int]`, and top-level `None`
  should remain.

## Next Formal Step

In an environment with K available, run the commands in `fvk/PROOF.md` against
`fvk/mini-python-annotation.k` and `fvk/python-annotation-spec.k`. Until `kprove`
returns `#Top`, treat the proof as constructed but not machine-checked.

## Open Question for Future Work

Should Sphinx resolve aliases such as `L[True]` when `L` is an alias for
`typing.Literal`? If yes, the parser likely needs context from autodoc or type
alias resolution rather than a broader string-name heuristic inside
`_parse_annotation()`.
