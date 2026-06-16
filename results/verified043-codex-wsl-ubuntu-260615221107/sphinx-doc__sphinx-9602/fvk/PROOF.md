# FVK Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`, tests,
or Python code were run.

## Machine-Check Commands

Standalone K-style artifacts were emitted as `fvk/mini-python-annotation.k` and
`fvk/python-annotation-spec.k`.

Expected commands, not executed here:

```sh
kompile fvk/mini-python-annotation.k --backend haskell
kast --backend haskell fvk/python-annotation-spec.k
kprove fvk/python-annotation-spec.k
```

Expected machine result after syntax repair, if any is needed: `#Top` for all
claims.

## Constructed Proof Summary

The proof is a partial-correctness argument over a finite tree walk and a finite
token scan. Termination is not separately machine-proved, but the implementation
recurses over finite AST children and iterates once over the finite result list.

### Literal Head Recognition

`PO-002` follows directly from `is_literal_annotation()` and the scanner check:
both use the same recognized set of head names. Therefore the AST subscript slice
of `Literal[...]`, `typing.Literal[...]`, and `typing_extensions.Literal[...]` is
unparsed with `literal_args=True`, and the later scan enters literal depth after
the corresponding head token.

### AST Parse Path

For parseable annotation strings, `_parse_annotation()` first builds a flat result
list by `unparse(tree)`.

For a recognized Literal subscript:

1. `unparse(node.value, literal_args)` emits the head as text.
2. `Punct("[")` is appended.
3. `unparse(node.slice, True)` emits the argument region as literal-value tokens.
4. `Punct("]")` is appended.

During the scan:

1. The head text is outside literal depth, so it becomes `type_to_xref(head, env)`.
2. The head text sets `next_is_literal_args = True`.
3. The following `[` enters `literal_depth = 1`.
4. Every token until the matching `]` is skipped before xref conversion.
5. The matching `]` decrements depth and is preserved.

This discharges `PO-001`, `PO-003`, and the parseable cases of `PO-004`.

### Constant and Signed Constant Cases

Under `literal_args=True`, constants use `repr(value)`, so strings keep quotes and
booleans/numbers/`None` render as their literal spelling. `ast.UnaryOp` with `+` or
`-` is accepted only in literal-argument mode; when its operand is a single text
node, V2 combines the sign and operand into one visible text token such as `-1`.

Those tokens are produced inside `literal_depth`, so no `type_to_xref()` call can
target them. This discharges `PO-004` and closes finding `F-002`.

### SyntaxError Literal Fallback

If AST parsing fails, V2 checks whether the original annotation string is exactly a
recognized `Literal[...]` form. If so, it returns:

1. `type_to_xref(literal_name, env)`,
2. `[`,
3. plain text for the entire bracket contents,
4. `]`.

That path is deliberately limited to recognized Literal heads; non-Literal
unsupported annotations still use the legacy single-xref fallback. This discharges
`PO-005` and closes finding `F-003`.

### Non-Literal Frame

For non-Literal annotations, `literal_depth` is never entered. The existing loop
still converts each non-empty text node to `type_to_xref()`, while punctuation nodes
are untouched. The public examples `List[int]`, `Callable[[int, int], int]`, and
top-level `None` therefore retain their expected xrefs. This discharges `PO-006`.

### Compatibility

The proof relies only on internal helper behavior. `_parse_annotation()` keeps the
same signature and every return path still returns a list of docutils/Sphinx nodes.
This discharges `PO-007`.

## Test Guidance

No tests were modified and none should be removed from this un-machine-checked
proof. Public tests that assert ordinary type xrefs should be kept. New tests, if
the suite were editable, should cover `typing.Literal[True]`,
`typing.Literal[False]`, `Literal['x']`, `Literal[-1]`, and a fallback value such
as `Literal[<Color.RED: 1>]`.

## Residual Risk

- The proof is not machine-checked.
- Arbitrary aliases such as `L[True]` are not resolved in this parser layer; see
  `F-005`.
- The mini model abstracts node internals to xref/text/punctuation observables. It
  is property-complete for the reported nitpick bug because nitpick warnings depend
  on whether a `pending_xref` is emitted.
