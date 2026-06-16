# Public Evidence Ledger

Status: constructed, not machine-checked.

| ID | Source | Evidence | Semantic Obligation | Status |
|---|---|---|---|---|
| E1 | prompt/problem | "Message.locations duplicate unnecessary" | A message's location collection should not retain unnecessary duplicates. | Encoded by PO1, PO4, PO5. |
| E2 | prompt/problem | Examples show repeated `#: ../../manual/...:0` lines for one `msgid`. | The observable POT location lines must be unique per message. | Encoded by PO1. |
| E3 | prompt/problem | "There should only be ONE instance ... and there are NO duplications of other locations." | The absence of duplicates is a general location-output property, not only the shown file. | Encoded by PO1 and PO2. |
| E4 | public hint | "`self.locations = list(set(locations))` ... is NOT enough" | Exact tuple de-duplication alone is insufficient. | Encoded by PO3 and PO5. |
| E5 | public hint | "`__iter__` needed ... `os.path.relpath(source, start=os.getcwd())`" | Normalize source paths before creating `Message` locations. | Encoded by PO3 and PO5. |
| E6 | public hint | "location lines includes the working directory in the front part of it" | Textually different source paths may denote the same rendered file. | Encoded by PO3. |
| E7 | source/template | `#: {{ relpath(source) }}:{{ line }}` | The observable location identity is based on rendered relative path plus line. | Encoded by PO1 and PO3. |
| E8 | source/comment | `self.messages: List[str] = []  # retain insertion order` | Message traversal order should remain stable. | Encoded as frame condition PO7. |
| E9 | implementation path | `Message.__init__`, `Catalog.__iter__`, and `GettextRenderer.render` jointly produce location lines. | The proof must cover all contributors to the location observable, not only the new helper. | Encoded by PO4, PO5, PO6, PO7. |
| E10 | prompt/problem | Notes about Babel wrapping and sorting are framed as further observations. | These are adjacent concerns but not necessary to satisfy duplicate location removal in Sphinx's template path. | Finding F2 records no source change. |
