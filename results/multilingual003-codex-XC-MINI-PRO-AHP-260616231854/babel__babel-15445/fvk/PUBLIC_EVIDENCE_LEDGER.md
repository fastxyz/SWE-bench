# Public Evidence Ledger

Status: constructed, not machine-checked.

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt | "generating source maps fails due to `sourcesContent` being undefined" | Missing `sourcesContent` is the reported in-domain boundary case; generation must not throw. | Encoded by PO-001 and claim `COPY-NO-CONTENT`. |
| E2 | prompt | "the returned object has ` sourcesContent: undefined,`" | The constructor must tolerate a `TraceMap` whose `sourcesContent` property is nullish. | Encoded by PO-001 and finding F-001. |
| E3 | prompt | Reproducer `inputSourceMap` includes `version`, `sources`, `mappings`, and `names`, with no `sourcesContent`. | A map with sources/mappings but absent source contents is valid for this bug fix. | Encoded in domain and PO-001. |
| E4 | source | Pre-existing code called `setSourceContent(map, resolvedSources[i], ...)` for input maps. | When source contents are present, preserve pairwise copying behavior. | Encoded by PO-002 and claim `COPY-SOME-CONTENT`. |
| E5 | source | `mark()` uses `_inputMap` for `originalPositionFor`; V1 still assigns `_inputMap` before the guard. | Mapping composition and original-position lookup must remain available. | Encoded by PO-003. |
| E6 | source | Direct `code` paths are after the input map block and unchanged by V1. | Do not regress source content insertion for no-input-map strings or object maps. | Encoded by PO-003. |
| E7 | baseline notes | "using the currently transformed code as fallback source content would attach the wrong text" | Do not invent source contents when the input map omits them. | Encoded by PO-004 and finding F-003. |
| E8 | source | V1 changes only local constructor statements; no exported type or method signature changes. | Public compatibility should be unchanged. | Encoded by PO-005. |
