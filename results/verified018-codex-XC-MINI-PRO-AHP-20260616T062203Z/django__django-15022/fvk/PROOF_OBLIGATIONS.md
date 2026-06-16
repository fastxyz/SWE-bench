# Proof Obligations

Status: constructed, not machine-checked.

## O1: Finite token processing

For finite output from `smart_split(search_term)`, the token loop produces one
term clause per token. Fully quoted tokens are unescaped before clause
construction.

Evidence: `get_search_results()` iterates over `smart_split(search_term)` and
retains the existing `unescape_string_literal()` branch.

Finding trace: supports F-001 resolution.

## O2: Lookup construction preservation

For every configured `search_field`, `construct_search()` returns the same ORM
lookup path as before V1/V2:

- `^field` maps to `field__istartswith`.
- `=field` maps to `field__iexact`.
- `@field` maps to `field__search`.
- valid explicit lookups are preserved.
- `pk` resolves through the model primary key name.
- otherwise `__icontains` is appended.

Evidence: `construct_search()` is unchanged.

Finding trace: no open finding.

## O3: Search predicate semantics

For nonempty terms `T` and lookups `L`, the queryset predicate is:

`AND_{t in T} OR_{l in L} predicate(l, t)`.

This is the documented admin search contract.

Finding trace: F-001 fixed, F-003 considered.

## O4: One filter operation for nonempty search terms

For any nonempty term list, `get_search_results()` performs exactly one
`QuerySet.filter()` call for the search terms, independent of token count.

V2 witness:

```python
if term_queries:
    queryset = queryset.filter(*term_queries)
```

Finding trace: F-001 fixed, F-002 cleanup.

## O5: ORM alias-reuse path

All per-term clauses must reach the ORM through one `Query.add_q()` operation so
the ORM can carry one `used_aliases` set through all child clauses.

Source reasoning:

- `QuerySet.filter(*term_queries)` calls `_filter_or_exclude_inplace()` once.
- `_filter_or_exclude_inplace()` calls `self._query.add_q(Q(*args, **kwargs))`.
- `Query.add_q()` calls `_add_q(q_object, self.used_aliases)`.
- `_add_q()` passes that same `used_aliases` set while building child clauses.
- In contrast, normal chained filters clone through `Query.chain()`, which
  clears `used_aliases` when `filter_is_sticky` is false.

Finding trace: F-001 fixed; F-004 marks this as source-proven but not
runtime-inspected.

## O6: Duplicate flag preservation

`may_have_duplicates` remains:

`any(lookup_spawns_duplicates(self.opts, search_spec) for search_spec in orm_lookups)`.

The fix must not suppress duplicate handling for M2M or other duplicate-spawning
lookup paths.

Finding trace: no open finding.

## O7: Public compatibility

The method signature, callsites, override contract, and return tuple shape are
unchanged.

Finding trace: no open finding; see `PUBLIC_COMPATIBILITY_AUDIT.md`.

## O8: No filter for empty term streams

If `search_term` is truthy but `smart_split(search_term)` yields no terms, no
search `filter()` call is made. This preserves prior behavior for whitespace-only
or otherwise empty token streams.

Finding trace: no open finding.
