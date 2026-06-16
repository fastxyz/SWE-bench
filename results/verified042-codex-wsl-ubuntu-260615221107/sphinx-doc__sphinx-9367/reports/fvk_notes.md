# FVK Notes

## Decisions

D-001: Keep the V1 direct tuple fix.

Trace: Finding F-001 identifies the original direct tuple bug, and PO-1 requires
`(<element>,)` for exactly one tuple element. PO-2 requires empty and
multi-element tuple behavior to remain unchanged. The existing V1 branch in
`visit_Tuple()` satisfies those obligations, so it stands.

D-002: Add a V2 fix for one-element simple tuple slices in `visit_Subscript()`.

Trace: Finding F-002 shows that V1 did not cover the sibling formatter in
`visit_Subscript()`, which manually joined tuple slice elements and would still
erase the comma for `obj[1,]`. PO-3 requires preserving the comma for a
one-element tuple slice, and PO-4 requires preserving the existing multi-element
subscript formatting. The new `render_simple_tuple()` helper satisfies both.

D-003: Do not change unrelated AST renderers or call sites.

Trace: Finding F-003 and PO-5 found no signature or return-type compatibility
problem in public `pycode.ast.unparse()` callers. The nested
`sphinx.domains.python._parse_annotation().unparse()` helper is a separate
docutils-node renderer, not the string API named by the issue, so it was not
changed.

D-004: Do not modify tests or run verification commands.

Trace: Finding F-004 and PO-6 record the benchmark no-execution rule and FVK
honesty gate. The K commands are written into the artifacts with an expected
`#Top`, but they were not executed. No tests were edited.

## Changed Files

`repo/sphinx/pycode/ast.py`

V1 already changed `visit_Tuple()` to handle direct one-element tuples. V2 adds
`render_simple_tuple()` inside `visit_Subscript()` and uses it for both modern
`node.slice` tuple slices and older `ast.Index(...).value` tuple slices.

`fvk/SPEC.md`, `fvk/FINDINGS.md`, `fvk/PROOF_OBLIGATIONS.md`,
`fvk/PROOF.md`, `fvk/ITERATION_GUIDANCE.md`

Added the requested FVK audit artifacts.

`fvk/mini-pycode-unparse.k`, `fvk/pycode-ast-tuple-spec.k`

Added the constructed formal core referenced by the FVK proof artifacts.

`reports/fvk_notes.md`

Added this decision trace from findings and proof obligations to source changes
and no-change decisions.
