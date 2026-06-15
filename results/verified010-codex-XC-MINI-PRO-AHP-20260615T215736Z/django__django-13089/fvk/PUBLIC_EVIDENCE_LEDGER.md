# Public Evidence Ledger

Status: constructed, not machine-checked.

E-001. Source: prompt. Evidence: "cache.backends.db._cull sometimes fails with 'NoneType' object is not subscriptable." Obligation: `_cull()` must tolerate a missing cutoff row without a TypeError. Status: encoded by PO-001.

E-002. Source: prompt. Evidence: "cursor after running connection.ops.cache_key_culling_sql() command is not returning any data." Obligation: the no-row result is an in-domain cache-maintenance case, not behavior to preserve as an exception. Status: encoded by PO-001.

E-003. Source: docs. Evidence: "`CULL_FREQUENCY`: The fraction of entries that are culled ... actual ratio is `1 / CULL_FREQUENCY`." Obligation: frequency `1` means cull all current rows. Status: encoded by PO-002.

E-004. Source: docs. Evidence: "A value of `0` for `CULL_FREQUENCY` means that the entire cache will be dumped." Obligation: keep the existing zero-frequency clear behavior. Status: encoded by PO-004.

E-005. Source: backend operation comment. Evidence: "Return an SQL query that retrieves the first cache key greater than the n smallest." Obligation: with a present cutoff row, normal culling uses the existing cutoff strategy. Status: encoded by PO-003.

E-006. Source: schema. Evidence: `cache_key` is a `CharField(... unique=True, primary_key=True)`. Obligation: a returned cutoff row has a usable non-null key. Status: domain assumption A-002.

E-007. Source: implementation. Evidence: `_base_set()` calls `_cull(db, cursor, now)` before updating or inserting cache rows. Obligation: `_cull()` must remain void and compatible with that caller. Status: encoded by PO-005.
