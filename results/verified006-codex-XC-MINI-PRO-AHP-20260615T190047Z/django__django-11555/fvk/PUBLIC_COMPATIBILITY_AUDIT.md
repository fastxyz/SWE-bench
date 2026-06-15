# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed Symbols

`SQLCompiler.find_ordering_name()`

- Signature: unchanged.
- Return shape: unchanged list of `(OrderBy expression, is_ref)` pairs.
- Public/override compatibility: no public callsite or subclass override
  signature changes were introduced.
- Behavior frame: non-expression string ordering continues through the existing
  `get_order_dir()` and relation-recursion path.

`SQLCompiler._resolve_ordering_expression()`

- New private helper.
- Public API impact: none.
- Compatibility risk: local to `SQLCompiler`; used only by
  `find_ordering_name()`.

Import of `F`

- Public API impact: none.
- Purpose: identify plain `F()` leaves so they can be resolved from the related
  model alias.

## Compatibility Verdict

No public signature, return-shape, storage-format, or virtual-dispatch
compatibility break was found. The source change is internal to SQL compiler
ordering construction.
