# Public Evidence Ledger

| ID | Source | Evidence | Semantic obligation | Status |
|---|---|---|---|---|
| E1 | prompt | "toctree contains reference to nonexisting document 'genindex', 'modindex', 'search'" | The named warnings are the bug, not behavior to preserve. | Encoded in SPEC and claims PO-1/PO-3. |
| E2 | prompt | "The following directive should be possible and do not rise errors" with entries `genindex`, `modindex`, `search` | These exact toctree entries are in-domain and must be accepted. | Encoded in PO-1. |
| E3 | prompt | Users currently use `:ref:`genindex``, `:ref:`modindex``, `:ref:`search`` | Toctree support should reuse the public standard-domain labels rather than invent unrelated targets. | Encoded in PO-2/PO-3. |
| E4 | source comment | `toctree['entries']` may be a document or external link; `toctree['includefiles']` contains source documents | Generated pages must be entries but not includefiles. | Encoded in PO-1/PO-4. |
| E5 | source code | `StandardDomain.initial_data['labels']` maps `modindex` to `py-modindex` | `modindex` should resolve to `py-modindex`. | Encoded in PO-2/PO-3. |
| E6 | source code | Numbering collectors iterate `toctreenode['entries']` and load `env.tocs` / doctrees for source documents | Generated entries must be skipped where consumers assume source doctrees. | V1 gap fixed in V2; encoded in PO-4. |

