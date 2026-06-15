# FVK Proof

Status: constructed, not machine-checked. This proof was reasoned from source and the K-style artifacts; no tests, Python, `kompile`, or `kprove` were run.

## Machine-check Commands Not Run

```sh
kompile fvk/mini-django-prefetch.k --backend haskell
kast --backend haskell fvk/django-11211-spec.k
kprove fvk/django-11211-spec.k
```

Expected machine-check result if the mini semantics and claims are accepted: `#Top`.

## Claims

C-001: For valid UUID text `S`, `uuidPrep(Str(S))` rewrites to `UUID(canonUuid(S))`.

C-002: For valid UUID text `S`, `keysMatch(Str(S), UUID(canonUuid(S)), Foo)` rewrites to `true`.

C-003: `uuidPrep(None)` rewrites to `None`.

## Constructed Proof Sketch

1. By V1 source code, `UUIDField.get_prep_value(value)` first applies base field preparation and then `UUIDField.to_python(value)`.

2. For in-domain `Str(S)` where `validUuid(S)`, `UUIDField.to_python(S)` returns `uuid.UUID(S)`. This discharges PO-001 and corresponds to C-001.

3. `GenericForeignKey.gfk_key(source)` computes `model = ContentType(...).model_class()` and returns `(model._meta.pk.get_prep_value(source_fk), model)`. In the issue domain, `model` is `Foo` and `model._meta.pk` is `UUIDField`, so by step 2 the source key is `(uuid.UUID(S), Foo)`.

4. `prefetch_one_level()` builds `rel_obj_cache` from `rel_obj_attr(rel_obj)`. For GFK prefetch, `rel_obj_attr` is `lambda obj: (obj.pk, obj.__class__)`. The in-domain related object is an instance of `Foo` with loaded UUID primary key `uuid.UUID(S)`, so the related key is `(uuid.UUID(S), Foo)`.

5. The source key from step 3 equals the related key from step 4. Therefore the dictionary lookup in `prefetch_one_level()` returns a non-empty `vals` list. Since GFK prefetch is a single relation, the existing branch chooses `val = vals[0]` and assigns the descriptor/cache to the related object. This discharges PO-002 and PO-003 and corresponds to C-002.

6. For `None`, existing GFK prefetch skips object ids before querying. Independently, V1's `get_prep_value(None)` returns `to_python(None)`, which is `None`; this preserves the null frame and discharges PO-004 / C-003.

7. Query compatibility is preserved because ORM lookup preparation may now pass a `uuid.UUID` value into `UUIDField.get_db_prep_value(..., prepared=True)`, and that method already accepts `uuid.UUID`, returning either the native UUID value or `value.hex` for non-native backends. This discharges PO-005.

8. Public compatibility is preserved because no public signature changes and no `GenericForeignKey` filtering behavior changes. This discharges PO-006 and PO-007.

## Adequacy Gate

The formal English claims are adequate for the public intent:

- I-001 requires GFK prefetch to populate a UUID target instead of returning `None`; C-001 and C-002 model the only mismatching axis found in source: textual source id versus UUID target pk.
- I-002 requires Python-side joining; C-002 explicitly states the join-key equality.
- I-003 requires no direct GFK filter support; no claim or source edit adds that behavior.
- I-004 requires preserving existing prefetch behavior; the GFK algorithm is unchanged and field preparation is narrowed to UUIDField.

No claim depends on hidden tests, benchmark results, or upstream patches.

## Test Recommendation

Do not remove any tests. The proof is constructed, not machine-checked, and the task forbids test edits.

Recommended future test, outside this task's edit permissions: a regression test with a `GenericForeignKey` stored in a `CharField` pointing at a model with `UUIDField(primary_key=True)`, asserting that `prefetch_related()` returns the target object from cache.

## Residual Risk

This is a partial-correctness proof over a mini semantics, not a full machine-checked proof over real Python and the full Django ORM. It covers the issue's value/type mismatch and relevant compatibility frames. It does not prove database query execution, ContentType cache behavior, or ORM termination.
