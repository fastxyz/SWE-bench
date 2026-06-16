# Formal Spec English

Constructed, not machine-checked.

## Claim PROPERTY-TYPE-XREF

For every non-empty property type string `T`, running the property type handling
step on an initial signature node list `S` terminates with the signature node
list equal to `S` followed by one `desc_annotation` node. That annotation node
contains literal text `": "` followed by a cross-reference node targeting `T`.

## Claim PROPERTY-NO-TYPE-FRAME

When no property `:type:` option is present, running the property type handling
step terminates with the signature node list unchanged.

## Claim PROPERTY-SUPER-FRAME

The modeled type-handling step is a suffix update after base signature handling.
It does not alter the base property name/prefix nodes produced by
`PyObject.handle_signature()` and does not alter the `(fullname, prefix)` return
value from that base handling.

## Claim PROPERTY-COMPATIBILITY

The public callable shape remains `PyProperty.handle_signature(self, sig,
signode) -> Tuple[str, str]`; only the internal construction of the optional
type annotation node changes from plain text to parsed annotation nodes.
