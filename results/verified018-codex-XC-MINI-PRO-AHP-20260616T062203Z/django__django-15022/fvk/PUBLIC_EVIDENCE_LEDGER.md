# Public Evidence Ledger

Status: constructed from public evidence, not machine-checked.

| ID | Source | Quoted evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | docs | "splits the search query into words" | Tokenize search input before building predicates. | Encoded by O1/O2. |
| E2 | docs | "each word must be in at least one of `search_fields`" | AND over terms, OR over fields. | Encoded by O3. |
| E3 | docs | SQL example with two ANDed OR clauses | Preserve Boolean search semantics for multiple words. | Encoded by O3. |
| E4 | docs | "quoted phrases with spaces" | Quoted phrase is one term after unescaping. | Encoded by O2. |
| E5 | docs | "related lookup on a `ForeignKey` or `ManyToManyField`" | Related lookup paths are in domain. | Encoded by O4/O5. |
| E6 | issue | "each word in the search query leads to additional JOIN ... because of `qs = qs.filter(...)` pattern" | Avoid one queryset filter application per word. | Encoded by O4/O5; fixed. |
| E7 | issue | "admin stalled" for several words with related search fields | The fix must address performance-relevant query shape, not only result membership. | Encoded by O5. |
| E8 | method docstring | "Return a tuple containing a queryset ... and a boolean indicating if the results may contain duplicates." | Preserve public return shape. | Encoded by O6/O7. |
| E9 | implementation | `lookup_spawns_duplicates(self.opts, search_spec)` | Duplicate flag is computed from lookup paths. | Preserved; implementation evidence for O6. |
| E10 | ORM source | `Query.chain()` clears `used_aliases` unless sticky; `Query.add_q()` passes one `used_aliases` set through children. | Chained filters can allocate fresh multi-join aliases; one `filter(*args)` keeps clauses in one `add_q()`. | Encoded by O5. |
