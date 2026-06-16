# FVK Specification

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Scope

This FVK pass audits the V1 change to
`repo/django/db/models/fields/related_descriptors.py`. The relevant observable
is the relation cache selected for a prefetched related object after an outer
prefetch has evaluated a related queryset that may itself contain nested
prefetches.

The proof target is not full Django ORM semantics. It is the cache-update rule
used by the three descriptor prefetch paths changed in V1:

- `ForwardManyToOneDescriptor.get_prefetch_queryset()`, when it manually seeds a
  non-multiple reverse cache on the fetched related object.
- `ReverseOneToOneDescriptor.get_prefetch_queryset()`, when it manually seeds
  the forward field cache on the fetched related object.
- `create_reverse_many_to_one_manager(...).RelatedManager.get_prefetch_queryset()`,
  when it manually seeds the forward field cache on each fetched child object.

## Public Intent Ledger

| ID | Source | Evidence | Obligation | Status |
|---|---|---|---|---|
| I1 | `benchmark/PROBLEM.md` | "I'd expect the following test case to pass" followed by `assertNumQueries(0)` for `user.profile.user.kind`. | After the outer and inner prefetches complete, the cached `Profile.user` selected by `user.profile.user` must have `kind` loaded, so `kind` access issues no query. | Encoded in PO1 and claim `PRESERVE-CACHED-RELATION`. |
| I2 | `benchmark/PROBLEM.md` | "This is exactly the query I'd expect to see if kind on the inner User queryset had been deferred, which it hasn't." | The inner queryset's loaded fields, not the outer queryset's deferred field set, must determine the object reached through the nested relation cache. | Encoded in PO1. |
| I3 | `benchmark/PROBLEM.md` | "instances are inheriting the set of fields they 'think' have been deferred from the outer User queryset". | The outer origin object must not overwrite an already-cached nested related object. | Encoded in PO1 and FINDING F1. |
| I4 | Public hint in `benchmark/PROBLEM.md` | "default to using the origin's object but allow overrides with nested prefetches". | Missing relation caches should still be seeded with the origin object; existing relation caches from nested prefetches should win. | Encoded in PO1 and PO2. |
| I5 | `benchmark/PROBLEM.md` | "this also happens if the relationship between Profile and User is a ForeignKey". | The same cache-winner rule applies to reverse many-to-one prefetches. | Encoded in PO3. |
| I6 | Django source comments | "Since we're going to assign directly in the cache, we must manage the reverse relation cache manually." | Descriptor prefetch paths must maintain relation caches directly and keep the existing no-query optimization when no nested cache exists. | Encoded in PO2 and frame conditions. |

## Intent Spec

For every descriptor prefetch path that attaches a fetched related object back to
an origin object:

1. If the fetched related object already has the relevant relation cache key,
   preserve the cached value exactly.
2. If the fetched related object does not have the relevant relation cache key,
   seed that cache with the origin object as before.
3. Apply the rule to reverse one-to-one and reverse many-to-one paths, because
   both are named by the public issue, and to the symmetric forward many-to-one
   path that seeds a non-multiple reverse cache through the same mechanism.
4. Do not change public method signatures, return tuple shape from
   `get_prefetch_queryset()`, prefetch filtering, query construction, or test
   files.

## Formal Model

The K files model the descriptor cache update as `seedIfMissing(REL, KEY,
ORIGIN)`, with a `<cache>` map keyed by `(REL, KEY)`.

- Existing cache case: if `(REL, KEY)` is present, the map is unchanged.
- Missing cache case: if `(REL, KEY)` is absent, the map is updated to store
  `ORIGIN`.

This abstraction is property-complete for the bug because the reported failure
is exactly the distinction between "cached inner user is preserved" and "cached
inner user is overwritten by outer user."

## Formal Spec English

- `PRESERVE-CACHED-RELATION`: Starting with a cache entry for a fetched related
  object and relation key, running the descriptor cache seeding step leaves that
  entry equal to the original inner prefetched object.
- `SEED-MISSING-RELATION`: Starting without a cache entry for a fetched related
  object and relation key, running the descriptor cache seeding step creates an
  entry equal to the origin object.
- `COVER-RELATION-FAMILY`: The same `seedIfMissing` rule is used by the audited
  one-to-one and ForeignKey reverse paths, plus the symmetric forward path, so
  the proof obligations cover all public issue variants.

## Spec Audit

| Formal obligation | Intent entries | Audit |
|---|---|---|
| Preserve existing relation cache. | I1, I2, I3, I4 | Pass. This is the public bug and requested override behavior. |
| Seed missing relation cache with origin. | I4, I6 | Pass. The hint asks to keep default origin-object behavior. |
| Cover reverse one-to-one and reverse many-to-one. | I1, I5 | Pass. The issue names both cases. |
| Include forward many-to-one non-multiple reverse cache. | I4, I6 | Pass. This is the symmetric descriptor-side cache seeding path and preserves the same winner rule. |
| Keep signatures and tuple shape. | I6, public compatibility default | Pass. V1 adds guards only. |

## Public Compatibility Audit

No public symbol signatures changed. The three edited methods still return the
same tuple shapes and still accept the same parameters. No callsite, subclass
override, manager protocol, or test file requires an update.

