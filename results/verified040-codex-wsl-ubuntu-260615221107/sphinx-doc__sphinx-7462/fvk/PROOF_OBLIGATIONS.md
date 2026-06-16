# Proof Obligations

Status: constructed, not machine-checked.

## PO1: Empty Tuple Totality And Output Form

- Claim: an empty `ast.Tuple` must return `(` and `)` punctuation tokens.
- Evidence: E1, E2, E3
- V1 status: discharged
- V2 status: discharged
- Code path: `elif isinstance(node, ast.Tuple)` with `if node.elts:` false.
- Expected result: `[desc_sig_punctuation("("), desc_sig_punctuation(")")]`
- Failure mode if absent: `result.pop()` on an empty list.

## PO2: Empty List Delimiter Preservation

- Claim: an empty `ast.List` must return `[` and `]` punctuation tokens.
- Evidence: E2, E5
- V1 status: failed
- V2 status: discharged
- Code path: `elif isinstance(node, ast.List)` with `node.elts` empty.
- Expected result: the opening bracket initialized in `result` is retained, no
  trailing separator cleanup occurs, and the closing bracket is appended.
- Failure mode if absent: the cleanup pop removes the opening bracket.

## PO3: Non-empty Separator Preservation

- Claim: non-empty `ast.List` and `ast.Tuple` nodes remove exactly the final
  separator and preserve all element tokens in order.
- Evidence: E4, E5
- V1 status: discharged for tuples; discharged for lists
- V2 status: discharged
- Code path: loop appends each element's tokens followed by `, `; cleanup pop
  executes only when at least one separator was appended.
- Frame condition: no added tuple parentheses for non-empty tuple slices.

## PO4: Subscript And Xref Integration

- Claim: subscript rendering composes value tokens, `[`, slice tokens, and `]`;
  after unparsing, text/name tokens become xrefs and punctuation remains
  punctuation.
- Evidence: E2, E3, E4, E5, E6
- V1 status: discharged for the empty tuple path; failed for empty list slices
  because PO2 failed.
- V2 status: discharged for both `Tuple[()]` and `Callable[[], int]` paths.

## PO5: Unsupported Syntax Fallback Frame

- Claim: unsupported annotation syntax continues to return a fallback xref
  through the existing `except SyntaxError` path.
- Evidence: E7
- V1 status: discharged
- V2 status: discharged
- Code path: no changes to the `else: raise SyntaxError` branch or the
  `except SyntaxError` handler.

## PO6: Public Compatibility

- Claim: no public signature, return type, virtual dispatch contract, or node
  consumer protocol changes.
- Evidence: E6 and compatibility search over source call sites
- V1 status: discharged
- V2 status: discharged
- Code path: only local branch logic changed; `_parse_annotation()` still returns
  `List[Node]`.
