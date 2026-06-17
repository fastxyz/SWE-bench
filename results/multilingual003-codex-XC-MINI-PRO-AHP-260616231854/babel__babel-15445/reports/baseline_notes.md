# Baseline Notes

## Root cause

`@babel/generator` builds a `TraceMap` for `opts.inputSourceMap` and then copies source contents from that input map into the generated map. Source map `sourcesContent` is optional, but `packages/babel-generator/src/source-map.ts` assumed `this._inputMap.sourcesContent` was always an array whenever the input map had resolved sources. When an input map has `sources` and `mappings` but omits `sourcesContent`, `TraceMap` exposes `sourcesContent` as `undefined`, so indexing `this._inputMap.sourcesContent[i]` throws before code generation can complete.

## Files changed

`repo/packages/babel-generator/src/source-map.ts`

Guarded the source-content copy loop so Babel only calls `setSourceContent` when the input map actually provides a `sourcesContent` array. The existing behavior is preserved for input maps that include source contents, while maps that omit the optional field can still be traced and composed.

`reports/baseline_notes.md`

Added this required analysis report.

## Assumptions and rejected alternatives

I assumed that an omitted `sourcesContent` field should remain omitted rather than being synthesized. With `inputSourceMap`, the map's `sources` refer to earlier original files, so using the currently transformed code as fallback source content would attach the wrong text to those original sources.

I considered filling missing entries with empty strings or `null`, but rejected that because the input map did not provide content for those sources. Preserving only provided entries avoids inventing source text while fixing the crash.

I did not modify test files, as requested.
