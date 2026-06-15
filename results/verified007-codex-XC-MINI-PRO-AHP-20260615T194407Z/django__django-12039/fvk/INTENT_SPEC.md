# Intent Spec

This file records intended behavior before accepting V1 implementation behavior as correct.

## Required Behaviors

1. A descending index column must be rendered with whitespace between the quoted column token and `DESC`.
2. An ascending/default index column must not gain trailing whitespace from the empty suffix token.
3. A PostgreSQL opclass index column without explicit ordering must be rendered as quoted column token, one space, opclass token, and no trailing whitespace.
4. A PostgreSQL opclass index column with descending ordering must be rendered as quoted column token, one space, opclass token, one space, `DESC`.
5. Multi-column index SQL must continue separating rendered column entries with comma-space.
6. The fix must not require public API signature, constructor, or dispatch changes.

## Domain Assumptions

- `Index.fields_orders` supplies `''` for ascending/default order and `DESC` for descending order.
- `Index.__init__()` requires `opclasses` to be the same length as fields when opclasses are provided.
- Opclass names are in-scope as bare SQL tokens supplied through the existing API.

## Suspect Legacy Evidence

The issue's examples of `"name"DESC` and `"name" text_pattern_ops ` are current bad behavior, not expected behavior. They must not be preserved as the spec.
