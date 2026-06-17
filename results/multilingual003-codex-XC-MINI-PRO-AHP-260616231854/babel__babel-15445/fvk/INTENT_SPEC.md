# Intent Specification

Status: constructed, not machine-checked.

## Intent-only obligations

1. Babel generator must not throw while generating a source map when `opts.inputSourceMap` is present and the normalized `TraceMap` has `sourcesContent` equal to `undefined`.
2. An input source map may validly provide `sources`, `mappings`, and `names` without `sourcesContent`; this absence is in scope because the issue reproducer does exactly that.
3. If an input source map does provide `sourcesContent`, Babel should keep the existing behavior of copying provided source contents into the output source map.
4. Babel should not synthesize original source contents from the currently transformed code when an input source map omits `sourcesContent`, because the input map's sources can refer to earlier original files.
5. The change must not alter public API shape, source map position tracing, or the existing direct `code` source-content paths outside the optional input-map content copy.

## Domain

The audited unit is the `SourceMap` constructor's input-map source-content copy step in `repo/packages/babel-generator/src/source-map.ts`.

Inputs in scope:

- `opts.inputSourceMap` absent or present.
- `TraceMap(opts.inputSourceMap).resolvedSources` is a finite list.
- `TraceMap(opts.inputSourceMap).sourcesContent` is either absent/nullish or a finite array of source-content entries.

Inputs outside this FVK slice:

- Malformed arrays with explicit `undefined` entries or sparse holes inside a present `sourcesContent` array.
- Correctness of the external `TraceMap`, `setSourceContent`, and `originalPositionFor` implementations.
- Full Babel parsing, transformation, and code generation behavior.
