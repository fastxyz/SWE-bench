# FVK Proof

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Claims

The proof is over the abstract cache transition in `prefetch-cache-spec.k`.

- `PRESERVE-CACHED-RELATION` proves PO1.
- `SEED-MISSING-RELATION` proves PO2.
- `COVER-RELATION-FAMILY` is a coverage claim tying the three edited source
  loops to the same cache transition and proving PO3 by source inspection.

## Source-to-Model Mapping

The source operation being modeled is the descriptor-side write:

- `remote_field.set_cached_value(rel_obj, instance)`
- `self.related.field.set_cached_value(rel_obj, instance)`
- `setattr(rel_obj, self.field.name, instance)`

V1 wraps each write with the corresponding cache-membership guard:

- `if not remote_field.is_cached(rel_obj):`
- `if not self.related.field.is_cached(rel_obj):`
- `if not self.field.is_cached(rel_obj):`

`FieldCacheMixin.is_cached(instance)` is key membership in
`instance._state.fields_cache`. `set_cached_value(instance, value)` writes that
same cache key. `setattr(rel_obj, self.field.name, instance)` invokes the
forward descriptor path, which writes the forward field cache for the same
field name. Therefore the source operation is faithfully represented by
`seedIfMissing(REL, KEY, ORIGIN)`.

## Proof Sketch

### PO1: Preserve Already-Cached Relation

Assume the cache map contains `cacheKey(REL, KEY) |-> INNER` before
`seedIfMissing(REL, KEY, ORIGIN)`.

Symbolic execution of `seedIfMissing` evaluates the cache-membership guard.
Because the key is present, the cached branch fires and rewrites only the
`<k>` cell to `.K`; the `<cache>` cell is framed unchanged. By map
extensionality, the value at `cacheKey(REL, KEY)` remains `INNER`.

This proves that a nested prefetched `Profile.user` object is not overwritten
by the outer origin `User` object. The reported `kind` field therefore remains
the one loaded by the inner `User.objects.only("kind")` queryset.

### PO2: Seed Missing Relation With Origin

Assume `cacheKey(REL, KEY)` is absent before
`seedIfMissing(REL, KEY, ORIGIN)`.

Symbolic execution evaluates the cache-membership guard. Because the key is
absent, the missing-cache branch fires and rewrites the `<cache>` cell to
`CACHE[cacheKey(REL, KEY) <- ORIGIN]`. By the map update semantics, lookup of
that key after the step returns `ORIGIN`.

This preserves the pre-existing Django optimization when no nested prefetch or
select-related cache has already populated the relation.

### PO3: Cover the Public Relation Family

Source inspection shows all public issue variants reach one of the three edited
manual cache-seeding loops:

- The one-to-one example reaches
  `ReverseOneToOneDescriptor.get_prefetch_queryset()`, which now preserves a
  cached `Profile.user`.
- The ForeignKey reverse example reaches
  `RelatedManager.get_prefetch_queryset()` from
  `create_reverse_many_to_one_manager()`, which now preserves a cached child
  forward relation.
- The symmetric forward many-to-one non-multiple reverse-cache path uses the
  same rule through `ForwardManyToOneDescriptor.get_prefetch_queryset()`.

Each path uses the same guard-before-write structure, so PO1 and PO2 compose
with all public issue variants.

## Adequacy Check

The formal English claims match the intent ledger:

- The preserve claim corresponds to the public requirement that inner prefetch
  loaded fields are not discarded.
- The missing-cache claim corresponds to the public hint to keep default origin
  assignment behavior.
- The coverage claim corresponds to the issue's one-to-one example and
  ForeignKey note.

No claim preserves the pre-fix buggy behavior. No ordered result, winner rule,
or frame condition is derived solely from V1.

## Machine Check Commands

These commands are emitted for later use only. They were not run.

```sh
cd fvk
kompile mini-prefetch-cache.k --backend haskell
kast --backend haskell prefetch-cache-spec.k
kprove prefetch-cache-spec.k
```

Expected result after a real machine check: `#Top` for the stated claims.

## Residual Risk

This is a partial-correctness proof over an abstract cache update model, not a
machine-checked proof of the full Django ORM. It does not prove database query
planning, SQL generation, queryset evaluation termination, or integration with
all descriptor variants outside the audited manual cache-seeding paths.

No test removal is recommended because the proof was not machine-checked and
the relevant behavior is integration-level ORM behavior.
