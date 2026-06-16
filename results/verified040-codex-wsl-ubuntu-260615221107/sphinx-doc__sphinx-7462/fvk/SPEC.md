# FVK Specification

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Scope

This FVK pass audits `sphinx.domains.python._parse_annotation()` as used for
Python-domain signature annotation rendering. The proof model focuses on the
observable property affected by the issue: the ordered sequence of name and
punctuation nodes emitted by the nested `unparse()` helper.

## Public Intent Ledger

- E1/E2 require `Tuple[()]` to render without `IndexError`.
- E3 requires the empty tuple output form to be literal `()`.
- E4 requires non-empty tuple rendering to remain unchanged.
- E5 requires the supported `ast.List` delimiter family to handle the empty
  member `[]`.
- E6 requires name-to-xref behavior to remain unchanged.
- E7 permits preserving the existing fallback for unsupported syntax.

The full ledger is in `fvk/PUBLIC_EVIDENCE_LEDGER.md`.

## Domain

The verified in-domain inputs are annotation AST fragments produced from strings
accepted by `sphinx.pycode.ast.parse()` and handled by `_parse_annotation()`:

- `ast.Name`
- `ast.Expr`
- `ast.Index`
- `ast.Module`
- `ast.Subscript`
- `ast.List`
- `ast.Tuple`
- `ast.Attribute`, with the existing implementation caveat that it expects the
  value side to unparse to a leading text node

Unsupported AST node classes are outside this verified domain and continue to
take the existing `SyntaxError` fallback path.

## Observable Model

The mini model represents output as an ordered token list:

- `XRef(name)` for a Python pending-xref name after `_parse_annotation()`'s
  post-processing
- `Punct(text)` for `addnodes.desc_sig_punctuation`

This abstraction preserves the exact property under audit: delimiter presence,
delimiter order, comma separators, and name-vs-punctuation classification.

## Claims

C-TUPLE-EMPTY:
For `ast.Tuple` with `elts == []`, `unparse()` returns
`[Punct("("), Punct(")")]`.

C-LIST-EMPTY:
For `ast.List` with `elts == []`, `unparse()` returns
`[Punct("["), Punct("]")]`.

C-TUPLE-NONEMPTY:
For `ast.Tuple` with one or more elements, `unparse()` returns each element's
unparsed tokens separated by `Punct(", ")` and with no trailing comma. It does
not add tuple parentheses around non-empty tuple slices.

C-LIST-NONEMPTY:
For `ast.List` with one or more elements, `unparse()` returns `Punct("[")`,
then each element's unparsed tokens separated by `Punct(", ")`, then
`Punct("]")`, with no trailing comma before the closing bracket.

C-SUBSCRIPT-INTEGRATION:
For `ast.Subscript(value, slice)`, `unparse()` emits the value tokens,
`Punct("[")`, the slice tokens, and `Punct("]")`.

C-XREF-FRAME:
After unparsing, only text/name tokens are converted to pending xrefs; punctuation
tokens remain punctuation nodes.

C-FALLBACK-FRAME:
Unsupported syntax still returns a single xref for the original annotation
string through the existing `SyntaxError` fallback.

## V1 Audit Result

V1 satisfies C-TUPLE-EMPTY and preserves C-TUPLE-NONEMPTY. The audit found that
V1 did not satisfy C-LIST-EMPTY: the `ast.List` branch used the same
separator-removal pattern and, on an empty list, removed the opening bracket
before appending the closing bracket.

## V2 Source Decision

V2 keeps the V1 empty tuple branch and adds one guard in the `ast.List` branch:
the trailing separator is removed only when `node.elts` is non-empty. This
discharges C-LIST-EMPTY while preserving C-LIST-NONEMPTY.
