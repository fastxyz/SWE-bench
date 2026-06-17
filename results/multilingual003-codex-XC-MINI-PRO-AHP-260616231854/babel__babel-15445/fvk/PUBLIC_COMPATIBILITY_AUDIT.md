# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed symbols

`repo/packages/babel-generator/src/source-map.ts`

- Changed local constructor logic only.
- No exported class name changed.
- No constructor parameter changed.
- No public method signature changed.
- No return shape changed.
- No new dependency or new virtual dispatch added.

## Public callers and overrides

The changed code is inside the existing `SourceMap` constructor and only affects when `setSourceContent` is called for input-map contents. Callers still pass the same `opts` and `code` values. There are no subclass or override compatibility obligations introduced by V1.

## Producer/consumer shape

Produced source maps continue to use the existing `GenMapping` output path. When input-map `sourcesContent` is absent, V1 omits copied source contents instead of throwing or inventing contents. When contents are present, V1 preserves pairwise copying.

Compatibility result: pass.
