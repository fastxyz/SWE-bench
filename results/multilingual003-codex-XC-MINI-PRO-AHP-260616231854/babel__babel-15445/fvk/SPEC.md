# FVK Specification

Status: constructed, not machine-checked.

## Scope

This FVK pass audits the V1 fix in `repo/packages/babel-generator/src/source-map.ts`, specifically the `SourceMap` constructor path that copies source contents from `opts.inputSourceMap` into the generated map.

The formal model abstracts external library behavior:

- `TraceMap(opts.inputSourceMap).resolvedSources` is represented as a finite list of source names.
- `TraceMap(opts.inputSourceMap).sourcesContent` is represented as either `noContent` or `someContent(contents)`.
- `setSourceContent(map, source, content)` is represented as a map update.

This abstraction keeps the defect's observable axis visible: whether Babel reads from an absent `sourcesContent` array, and whether it preserves provided source contents.

## Public Intent Ledger

| ID | Source | Evidence | Obligation |
| --- | --- | --- | --- |
| E1 | prompt | "generating source maps fails due to `sourcesContent` being undefined" | Do not throw when `sourcesContent` is absent. |
| E2 | prompt | "`sourcesContent: undefined`" after creating `TraceMap` | Treat nullish source-content arrays as in-domain. |
| E3 | prompt | Reproducer input map lacks `sourcesContent` but has `sources` and `mappings` | Do not require `sourcesContent` for source map generation. |
| E4 | source | Pre-existing constructor copied source contents from input maps | Preserve copying when contents are present. |
| E5 | source | `mark()` uses `_inputMap`; V1 still creates `_inputMap` | Do not break original-position tracing. |
| E6 | source | Direct `code` source-content branches are unchanged | Do not regress no-input-map string/object source content insertion. |

The full ledger is mirrored in `fvk/PUBLIC_EVIDENCE_LEDGER.md`.

## Contract

For valid `TraceMap` outputs in the audited domain:

1. If `sourcesContent` is absent/nullish, the constructor must not index it and must not call `setSourceContent` from the input-map copy loop.
2. If `sourcesContent` is present, the constructor must copy provided source contents pairwise by index to the corresponding resolved source.
3. If the content list is shorter than the source list, the constructor must not read beyond the content list. This is a defensive extension; public intent does not require synthesizing missing entries.
4. Missing input source contents must remain missing. Babel must not attach the currently transformed code as fallback content for original sources named by an input map.
5. `_inputMap`, `mark()`, `get()`, `getDecoded()`, `getRawMappings()`, and direct `code` content behavior are frame conditions outside the changed copy loop.

## Formal Claims

The formal core is in:

- `fvk/mini-ts-sourcemap.k`
- `fvk/source-map-spec.k`

Claim `COPY-NO-CONTENT` states that `copyInput(SOURCES, noContent)` terminates with the generated-map contents unchanged.

Claim `COPY-SOME-CONTENT` states that `copyInput(SOURCES, someContent(CONTENTS))` terminates with generated-map contents equal to `copyPairs(M, SOURCES, CONTENTS)`, where `copyPairs` performs pairwise map updates until either list ends.

## Adequacy

`fvk/FORMAL_SPEC_ENGLISH.md` paraphrases the claims, and `fvk/SPEC_AUDIT.md` compares those paraphrases to intent. The audit passes: the formal claims cover the reported missing-`sourcesContent` crash, preserve content-copy behavior when contents exist, and do not prove a legacy behavior the issue labels as buggy.

## Machine Check Commands

These commands are emitted for later use only. They were not run in this environment.

```sh
kompile fvk/mini-ts-sourcemap.k --backend haskell
kast --backend haskell fvk/source-map-spec.k
kprove fvk/source-map-spec.k
```
