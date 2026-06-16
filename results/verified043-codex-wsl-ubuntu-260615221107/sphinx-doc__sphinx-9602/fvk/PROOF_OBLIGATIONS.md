# FVK Proof Obligations

Status: constructed, not machine-checked.

## PO-001: Literal Values Are Not Class Targets

For any recognized `Literal` annotation head, every token in its bracketed argument
region is outside the class-reference conversion path.

Formal shape:

```k
requires isLiteralHead(Head)
claim scan(Text(Head) Punct("[") Args Punct("]"), 0, false)
  => XRef(Head) Punct("[") noXRefs(Args) Punct("]")
```

Evidence: `I1`, `I2`.

Discharge argument: V2 sets `next_is_literal_args` immediately after converting the
recognized Literal head to `type_to_xref()`. The following `[` enters
`literal_depth = 1`; while `literal_depth` is positive, the loop updates only
bracket depth and continues before the `type_to_xref()` branch. Therefore no
`nodes.Text` inside the argument region is converted to a `pending_xref`.

## PO-002: Recognized Literal Heads Enter the Literal Argument Mode

The parser recognizes `Literal`, `typing.Literal`, and `typing_extensions.Literal`
as heads that begin a literal-value subscript.

Formal shape:

```k
claim isLiteralHead("Literal") => true
claim isLiteralHead("typing.Literal") => true
claim isLiteralHead("typing_extensions.Literal") => true
```

Evidence: `I2`, `I3`; `typing_extensions` is included as the standard backport
spelling for the same public construct.

Discharge argument: `is_literal_annotation()` compares `unparse_name(node)` against
exactly those three names, and the scanner compares generated text against the same
set.

## PO-003: Literal Values Remain Present

Skipping xref conversion must not remove or hide literal value text.

Formal shape:

```k
claim parseAnn("typing.Literal[True]")
  => XRef("typing.Literal") Punct("[") Text("True") Punct("]")
claim parseAnn("typing.Literal[False]")
  => XRef("typing.Literal") Punct("[") Text("False") Punct("]")
```

Evidence: `I2`, `I3`.

Discharge argument: the AST unparser still emits nodes for constants and
punctuation. The scanner skips xref conversion while inside `literal_depth`, but it
does not drop or replace those nodes.

## PO-004: Literal Constant Formatting

Constants inside `Literal[...]` are rendered as literal values, not type names.

Formal shape:

```k
claim parseAnn("Literal['x']") => XRef("Literal") Punct("[") Text("'x'") Punct("]")
claim parseAnn("Literal[1]") => XRef("Literal") Punct("[") Text("1") Punct("]")
claim parseAnn("Literal[-1]") => XRef("Literal") Punct("[") Text("-1") Punct("]")
claim parseAnn("Literal[None]") => XRef("Literal") Punct("[") Text("None") Punct("]")
claim parseAnn("Literal[...]") => XRef("Literal") Punct("[") Punct("...") Punct("]")
```

Evidence: `I2`, `I4`.

Discharge argument: V2 passes `literal_args=True` to the subscript slice when the
subscript head is a recognized Literal. Constants under that flag use `repr()`;
unary plus/minus under that flag combines the sign with a single text operand where
possible; ellipsis remains punctuation. All of these nodes are then inside
`literal_depth` and are not cross-referenced.

## PO-005: SyntaxError Fallback for Recognized Literal Strings

When the full annotation string has a recognized `Literal[...]` head but the
argument text is not parseable as a Python AST expression, the fallback must still
avoid xrefs for the bracketed value text.

Formal shape:

```k
claim parseAnn("Literal[<Color.RED: 1>]")
  => XRef("Literal") Punct("[") Text("<Color.RED: 1>") Punct("]")
```

Evidence: `I2`, `I4`.

Discharge argument: `except SyntaxError` calls
`parse_literal_annotation_fallback()`. The fallback is constrained to strings that
start with one of the recognized Literal heads plus `[` and end with `]`; it returns
an xref for the head and plain text for the bracket contents.

## PO-006: Non-Literal Annotation Frame Condition

For annotations without a recognized Literal argument region, existing text-to-xref
behavior is preserved.

Formal shape:

```k
claim parseAnn("List[int]") => XRef("List") Punct("[") XRef("int") Punct("]")
claim parseAnn("None") => XRef("None")
claim parseAnn("Callable[[int, int], int]")
  => XRef("Callable") Punct("[") Punct("[") XRef("int") Punct(", ")
     XRef("int") Punct("]") Punct(", ") XRef("int") Punct("]")
```

Evidence: `I5`.

Discharge argument: outside `literal_depth`, the scan still converts every
non-empty `nodes.Text` via `type_to_xref()`. Existing punctuation construction is
unchanged.

## PO-007: Public Compatibility

The fix must not change `_parse_annotation()`'s public call protocol or the node
list shape expected by its callers.

Formal shape:

```k
claim callShape("_parse_annotation", annotation, env) => returnsListOfNodes
```

Evidence: `I6`.

Discharge argument: all new helpers are nested inside `_parse_annotation()`. The
function signature is unchanged and every path still returns `List[Node]`.
