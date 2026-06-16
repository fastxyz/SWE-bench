# Public Evidence Ledger

Status: constructed, not machine-checked.

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | problem title | "source-read event does not modify include'd files source" | Include insertion must observe source-read mutations. | Encoded in PO-1 and CLAIM-MANAGED-INCLUDE. |
| E2 | problem description | "some are left out of this mechanism. Such is the case for include'd files" | The transformation mechanism must cover include files, not just top-level documents. | Encoded in I1/I3. |
| E3 | reproduction extension | `source[0] = result` after replacing `&REPLACE_ME;` | Event handlers mutate source by replacing list element 0; the returned include text must be that element. | Encoded in PO-1/PO-2. |
| E4 | reproduction command | `if grep -Rq REPLACE_ME build/*.html; then echo BAD; fi` | No untransformed placeholder may remain in built HTML. | Encoded in expected observable for PO-1. |
| E5 | expected HTML | Both paragraphs contain `REPLACED`. | Included and including source both receive equivalent source-read transformation. | Encoded in I3. |
| E6 | problem note | Handler is called for `something-to-include.rst` and `source[0]` is replaced, but final HTML ignores it. | Reading the included file as a standalone document is insufficient; the include read itself must use transformed text. | Encoded in root cause and PO-1. |
| E7 | Sphinx source | `SphinxStandaloneReader.read_source()` emits `source-read` and returns `arg[0]`. | Include-side processing should mirror top-level source-read post-processing. | Encoded in CLAIM-MANAGED-INCLUDE. |
| E8 | Sphinx source | `Include.run()` bypasses path processing for `<...>` standard includes. | Standard docutils includes are a frame condition; do not alter them. | Encoded in PO-2. |
| E9 | Sphinx source | `Include.run()` calls `env.relfn2path` and `env.note_included` before `super().run()`. | Preserve path resolution and included-doc bookkeeping. | Encoded in PO-3. |
| E10 | Sphinx source | `sphinx.ext.duration` connects to `source-read` and records `started_at`. | Extra include events must not make duration measure only from the last include. | Encoded in PO-6 and fixed in V2. |
