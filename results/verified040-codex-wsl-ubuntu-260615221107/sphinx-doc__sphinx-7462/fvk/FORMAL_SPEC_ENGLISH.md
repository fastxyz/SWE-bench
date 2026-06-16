# Formal Spec In English

Status: paraphrase of `fvk/python-annotation-spec.k`; constructed, not
machine-checked.

## C-TUPLE-EMPTY

If the annotation AST contains an empty tuple node, the unparser returns exactly
two punctuation tokens: an opening parenthesis and a closing parenthesis.

## C-LIST-EMPTY

If the annotation AST contains an empty list node, the unparser returns exactly
two punctuation tokens: an opening square bracket and a closing square bracket.

## C-TUPLE-NONEMPTY

If the annotation AST contains a tuple node with at least one element, the
unparser returns the unparsed elements in order, inserts `, ` punctuation between
adjacent elements, and emits no trailing comma punctuation after the last
element. It does not wrap those non-empty tuple elements in parentheses.

## C-LIST-NONEMPTY

If the annotation AST contains a list node with at least one element, the
unparser returns an opening square bracket, then the unparsed elements in order
with `, ` punctuation between adjacent elements, and then a closing square
bracket. It emits no trailing comma before the closing bracket.

## C-SUBSCRIPT-INTEGRATION

If the annotation AST is a subscript, the unparser preserves the value tokens,
adds an opening square bracket, emits the slice tokens, and adds a closing square
bracket.

## C-XREF-FRAME

Name tokens produced by unparsing become Python pending xrefs in
`_parse_annotation()` post-processing. Punctuation tokens produced for brackets,
parentheses, and commas remain punctuation nodes.

## C-FALLBACK-FRAME

Unsupported annotation AST syntax continues to use the existing `SyntaxError`
fallback and returns a single pending xref for the original annotation string.
