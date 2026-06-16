# FVK PROOF OBLIGATIONS

Status: constructed, not machine-checked.

## PO-1: Direct one-element tuple

For any AST tuple node `T` with exactly one element `E`,
`_UnparseVisitor.visit_Tuple(T)` must return:

```text
"(" + visit(E) + ",)"
```

Evidence: E-001, E-002, E-003.

Finding trace: F-001.

Discharge target: the `len(node.elts) == 1` branch in `visit_Tuple()`.

## PO-2: Direct tuple frame behavior

For direct tuple nodes outside the one-element case:

- `len(node.elts) == 0` returns `"()"`;
- `len(node.elts) >= 2` returns the existing parenthesized
  `", ".join(visit(e) for e in node.elts)` form.

Evidence: E-004.

Finding trace: F-001.

Discharge target: the `elif node.elts` and `else` branches in `visit_Tuple()`.

## PO-3: One-element simple tuple slice in subscript

For an `ast.Subscript` whose slice is a simple non-starred tuple with exactly one
element `E`, the rendered subscript must include the tuple comma:

```text
visit(value) + "[" + visit(E) + ",]"
```

The parentheses around tuple slices may be omitted, as existing behavior does
for multi-element slices, but the comma cannot be omitted because it carries the
tuple cardinality.

Evidence: E-001, E-005.

Finding trace: F-002.

Discharge target: `render_simple_tuple()` inside `visit_Subscript()`.

## PO-4: Subscript frame behavior

For subscript nodes outside the one-element simple tuple-slice case:

- simple non-starred tuple slices with two or more elements keep the existing
  bracketed comma-and-space joined form, preserving `Tuple[int, int]`;
- empty tuple slices do not match `is_simple_tuple()` and continue through the
  generic `self.visit(node.slice)` path;
- starred tuple slices do not match `is_simple_tuple()` and continue through the
  generic path;
- `ast.Index` wrapping on older Python ASTs must satisfy the same one-element
  and multi-element obligations as the direct `node.slice` path.

Evidence: E-004, E-005.

Finding trace: F-002.

Discharge target: both `is_simple_tuple(node.slice)` and
`isinstance(node.slice, ast.Index) and is_simple_tuple(node.slice.value)`
branches in `visit_Subscript()`.

## PO-5: Public compatibility

The fix must not change:

- the `unparse(node, code='')` public helper signature;
- visitor method signatures;
- return type for any audited path;
- test files.

Evidence: E-006 and the benchmark instruction forbidding test edits.

Finding trace: F-003.

Discharge target: source diff limited to branch-local string construction in
`repo/sphinx/pycode/ast.py`.

## PO-6: Verification honesty

The proof artifacts must identify exact K commands and expected outcomes, but
must not claim those commands were run or delete tests based on the constructed
proof.

Evidence: FVK `verify.md` honesty gate and benchmark no-execution instruction.

Finding trace: F-004.

Discharge target: `PROOF.md`, `ITERATION_GUIDANCE.md`, and `reports/fvk_notes.md`.
