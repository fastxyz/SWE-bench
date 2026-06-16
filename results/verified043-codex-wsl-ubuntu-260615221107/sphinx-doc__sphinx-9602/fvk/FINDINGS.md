# FVK Findings

Status: findings are from public intent, source inspection, and constructed proof
obligations. No tests or verification tooling were run.

## F-001: Original Literal Value Xref Bug

Input: `typing.Literal[True]`.

Observed before the fix: `_parse_annotation()` converted every non-empty text
fragment to `type_to_xref()`, so `True` became a `py:class` pending reference.

Expected from intent `I1` and `I2`: `typing.Literal` may be a Python-domain
reference, but `True` is a literal value and must remain visible non-reference
text.

Status: fixed by the V1/V2 `literal_depth` scan. Covered by `PO-001`, `PO-002`,
and `PO-003`.

## F-002: V1 Missed Signed Numeric Literal Values

Input: `Literal[-1]`.

Observed in V1 by source reasoning: Python parses `-1` as `ast.UnaryOp`, which V1
did not handle. That raised `SyntaxError` in the parser path and fell back to a
single `type_to_xref("Literal[-1]")`, so the annotation could still produce a
missing-reference warning instead of preserving the literal value.

Expected from intent `I2` and `I4`: signed numeric literal values are still
literal values and must not become xrefs.

Status: fixed in V2 by handling `ast.UAdd` and `ast.USub` under `literal_args`.
Covered by `PO-004`.

## F-003: V1 Did Not Cover Unparseable Literal Value Representations

Input: `Literal[<Color.RED: 1>]`, representative of value text that can occur from
`repr()`-style stringification but is not a parseable Python expression.

Observed in V1 by source reasoning: the AST parser would raise `SyntaxError`; the
fallback would produce one `pending_xref` for the entire annotation string.

Expected from intent `I2` and `I4`: the recognized `Literal` head can still be an
xref, but bracketed value text is a literal value region and should not be
cross-referenced.

Status: fixed in V2 by a constrained fallback for full `Literal[...]`,
`typing.Literal[...]`, and `typing_extensions.Literal[...]` strings. Covered by
`PO-005`.

## F-004: Frame Condition for Ordinary Type Annotations

Input: `List[int]`, `Tuple[int, int]`, `Callable[[int, int], int]`, and top-level
`None`.

Observed after the V2 source change by inspection: the new no-xref behavior is
entered only after a recognized `Literal` head and while the scanner is inside its
matching bracket depth. Other text fragments still flow through `type_to_xref()`.

Expected from public tests and compatibility intent `I5`: ordinary annotation type
names remain Python-domain references.

Status: confirmed by `PO-006`; no additional source change required.

## F-005: Arbitrary Aliases for Literal Remain Underspecified

Input: `L[True]` where user code has separately aliased `typing.Literal` to `L`.

Observed after V2 by source reasoning: `_parse_annotation()` has only the annotation
string and no reliable alias table here, so it cannot prove `L` means
`typing.Literal`. The value would still be treated as a type expression.

Expected from public intent: the issue demonstrates `typing.Literal[...]` and
speaks of `Literal[...]`, but does not provide evidence that arbitrary aliases must
be resolved at this parser layer.

Status: open/underspecified, not a blocker for this issue. Future work should
clarify whether alias-aware Literal parsing belongs in `_parse_annotation()` or in
the caller that has import/type-alias context.

## F-006: Proof Honesty Boundary

The FVK proof is constructed but not machine-checked. The findings above come from
intent and source reasoning, but no claim should be treated as discharged by
`kprove` until the commands in `fvk/PROOF.md` are actually run in an environment
with K available.
