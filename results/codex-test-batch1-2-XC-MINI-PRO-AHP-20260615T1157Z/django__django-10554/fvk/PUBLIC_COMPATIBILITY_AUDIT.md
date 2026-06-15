# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed public symbols

None. V1 changes only the implementation of `Query.clone()`.

## Signature compatibility

`Query.clone(self)` keeps the same signature and return type: it still returns a
copy of the current `Query`.

## Callsite compatibility

Read-only callsite audit:

- `Query.chain()` calls `self.clone()` and continues to receive a `Query`.
- `QuerySet._clone()` calls `self.query.chain()` and continues to receive an
  independent query for the derived queryset.
- compiler code calling `compiler.query.clone()` continues to receive a `Query`.

The V1 edit changes only whether `combined_queries` child query objects are
shared or cloned. This strengthens the existing clone contract and does not
require public caller changes.

## Subclasses and overrides

No public override signature was changed. The cloned object retains
`self.__class__`, as before V1. The new line calls `query.clone()` on component
queries, using the same internal clone protocol already used throughout
`Query`.

## Producer/consumer shapes

The shape of `combined_queries` remains a tuple of `Query` objects. Consumers do
not receive a new type or tuple layout.

Verdict: no compatibility finding blocks keeping V1.
