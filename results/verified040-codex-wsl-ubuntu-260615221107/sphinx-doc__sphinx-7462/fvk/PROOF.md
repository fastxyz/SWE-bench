# Constructed Proof

Status: constructed, not machine-checked. No tests, Python, `kompile`, `kast`,
or `kprove` were run.

## Formal Core

- Semantics fragment: `fvk/mini-python-annotation.k`
- Claim file: `fvk/python-annotation-spec.k`
- English spec: `fvk/SPEC.md`
- Adequacy audit: `fvk/SPEC_AUDIT.md`
- Compatibility audit: `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`

The model abstracts docutils nodes into ordered `XRef(name)` and `Punct(text)`
tokens. This keeps the property under audit visible: missing delimiters,
incorrect separator cleanup, and name-vs-punctuation classification.

## PO1: Empty Tuple

Pre-V1 symbolic path:

1. Enter the `ast.Tuple` branch with `node.elts == []`.
2. Initialize `result = []`.
3. Execute zero loop iterations.
4. Execute `result.pop()`.
5. The pop is undefined on an empty list, matching the reported
   `IndexError: pop from empty list`.

V1/V2 symbolic path:

1. Enter the `ast.Tuple` branch with `node.elts == []`.
2. The condition `if node.elts:` is false.
3. Return `[Punct("("), Punct(")")]`.
4. In a surrounding `Subscript(Name("Tuple"), Tuple(Tuple([])))`, the subscript
   branch frames the value and bracket tokens around those slice tokens,
   producing `XRef("Tuple"), Punct("["), Punct("("), Punct(")"), Punct("]")`.

This discharges PO1 and PO4 for `Tuple[()]`.

## PO2: Empty List

V1 symbolic path:

1. Enter the `ast.List` branch with `node.elts == []`.
2. Initialize `result = [Punct("[")]`.
3. Execute zero loop iterations.
4. Execute `result.pop()`, which removes `Punct("[")`.
5. Append `Punct("]")`.
6. Return `[Punct("]")]`, which is malformed for the empty-list delimiter
   obligation.

V2 symbolic path:

1. Enter the `ast.List` branch with `node.elts == []`.
2. Initialize `result = [Punct("[")]`.
3. Execute zero loop iterations.
4. The condition `if node.elts:` is false, so no cleanup pop occurs.
5. Append `Punct("]")`.
6. Return `[Punct("["), Punct("]")]`.

This discharges PO2 and fixes F2.

## PO3: Non-empty Collections

For `ast.List` with `n > 0` elements, V2 follows the same path as V1:

1. Initialize the opening bracket.
2. For each element, append the element tokens and one separator.
3. Since `node.elts` is true, execute the cleanup pop.
4. The cleanup pop removes the final separator, not a delimiter.
5. Append the closing bracket.

For `ast.Tuple` with `n > 0` elements, V2 keeps the V1 non-empty path unchanged:

1. Initialize an empty result list.
2. For each element, append the element tokens and one separator.
3. Pop the final separator.
4. Return the comma-separated element tokens without wrapping parentheses.

This discharges the frame conditions for `List[int]`, `Tuple[int, int]`, and
`Callable[[int, int], int]`.

## PO4: Xref And Punctuation Frame

The changed code returns only `addnodes.desc_sig_punctuation` instances in the
new empty delimiter cases. `_parse_annotation()` post-processing converts only
`nodes.Text` instances into pending xrefs. Therefore the new punctuation nodes
remain punctuation, while existing name tokens continue to become xrefs.

## PO5 And PO6: Fallback And Compatibility

No branch that raises `SyntaxError`, no `except SyntaxError` fallback, and no
function signature or callsite contract was changed. These obligations are
framed from the unchanged source.

## Adequacy Gate

`fvk/SPEC_AUDIT.md` marks all formal claims as passing against
`fvk/INTENT_SPEC.md`. The only behavior added beyond V1 is the empty-list member
of a list-delimiter syntax family already evidenced by public tests.

## Commands For Future Machine Check

These commands are recorded for a future environment with K installed. They were
not run in this task.

```sh
cd fvk
kompile mini-python-annotation.k --backend haskell
kast --backend haskell python-annotation-spec.k
kprove python-annotation-spec.k
```

Expected machine-check result: `kprove` discharges the claims to `#Top`.

## Test Recommendation

No tests were modified. Future tests that are covered by these obligations:

- `_parse_annotation("Tuple[()]")` should produce `Tuple[()]` punctuation and
  xref structure.
- `_parse_annotation("Callable[[], int]")` should preserve the inner `[]`.
- Existing non-empty cases should remain unchanged.

No test removal is recommended until the K claims are actually machine-checked.
