# FVK Findings

Status: audit findings after `/formalize` and `/verify` reasoning.  The proof
is constructed, not machine-checked.

## F1 - Resolved Code Bug: First Whitespace Split Corrupts Inline Container Types

- Evidence: issue E1-E3.
- Input: `:param dict(str, str) opc_meta:`.
- Pre-V1 observed mechanism: split field argument at the first whitespace,
  yielding type `dict(str,` and parameter name `str) opc_meta`.
- Expected: type expression remains `dict(str, str)` and parameter name is
  `opc_meta`.
- V1 status: resolved by `fieldarg.rsplit(None, 1)` in
  `DocFieldTransformer.transform()`.
- Proof obligations: PO1, PO2.

## F2 - Non-Blocking Documentation Tension: "Single Word" Inline Type Text

- Evidence: E7 says combined parameter type and description are possible when
  the type is a single word.
- Conflict: the issue provides positive public intent for an inline container
  type with internal whitespace.
- Resolution: do not preserve the legacy first-split behavior.  Treat the docs
  sentence as older under-specification.  A future documentation clarification
  would be useful, but it is not required to make the source fix correct.
- Proof obligations: PO1, PO5.

## F3 - Non-Blocking Ambiguity: Internal Type Whitespace

- Evidence: issue input includes `dict(str, str)` but expected prose writes
  `dict(str,str)`.
- Expected by this spec: correct type/name boundary; no new whitespace
  normalization of type expressions.
- Rationale: existing public tests and docs preserve comma-space type text such
  as `Tuple[str, ...]` and `dict(str, int)`.
- Proof obligations: PO1, PO3.

## F4 - Confirmation: Autodoc Annotation Merge Needed the Same Name Rule

- Evidence: E8 and source review of `modify_field_list()` /
  `augment_descriptions_with_types()`.
- Risk without V1's second file change: autodoc could believe the documented
  typed parameter is `str) opc_meta`, then inject duplicate `param opc_meta` or
  `type opc_meta` entries for annotations.
- V1 status: resolved by using `parts[-1]` for inline typed parameter names in
  both scanner paths.
- Proof obligations: PO4.

## F5 - Honesty Finding: Proof Not Machine-Checked

- Evidence: task no-execution rule and FVK honesty gate.
- Status: no K command, Python command, or test was run.  The proof is
  constructed only; `PROOF.md` records commands for later machine checking.
- Proof obligations: PO6.

## Summary

No source-level blocker was found after the V1 fix.  V1 satisfies the intent
and proof obligations; it stands unchanged.
