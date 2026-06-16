# FINDINGS

Status: constructed, not machine-checked. Findings are based only on public
issue text, source inspection, and FVK reasoning.

## F-001: V0 stale lookup cache after unregister

Classification: code bug fixed by V1.

Input/state:

- `ForeignObject.class_lookups["exactly"] = Exactly`.
- `Article.author.get_lookups()` or `ForeignObject.get_lookups()` has already
  populated an `lru_cache` entry containing `"exactly"`.
- `_unregister_lookup(ForeignObject, Exactly)` deletes
  `class_lookups["exactly"]`.

Observed in V0: the registry entry is gone, but the cached lookup map for
`ForeignObject` or a dependent subclass can still contain `"exactly"`.

Expected: unregistering mutates the lookup registry and must clear the
dependent `get_lookups()` caches, so a later lookup is recomputed from the
current registry.

Evidence: SPEC E-001, E-002, E-003, E-004, E-007.

Resolution: V1 calls `cls._clear_cached_lookups()` after the delete. This
satisfies PROOF_OBLIGATIONS O-002, O-003, and O-004.

## F-002: Clearing only the target class would be incomplete

Classification: avoided implementation pitfall.

Input/state:

- `cls` has a lookup registered.
- A subclass has already cached `get_lookups()` and inherited the lookup from
  `cls`.
- `_unregister_lookup(cls, lookup)` removes the registry entry.

Observed if only `cls.get_lookups.cache_clear()` were used: subclass caches
could still return the stale inherited lookup.

Expected: every subclass cache that may include `cls.class_lookups` must be
cleared.

Evidence: SPEC E-004 and existing `_clear_cached_lookups()` implementation.

Resolution: V1 uses `_clear_cached_lookups()`, not a one-class clear. This
satisfies PROOF_OBLIGATIONS O-003 and O-006.

## F-003: Existing manual cache clear after unregister is now redundant

Classification: test cleanup opportunity, not a production source bug.

Input/state:

- `tests/model_fields/test_jsonfield.py` registers a temporary transform,
  calls `_unregister_lookup(MyTransform)`, then manually calls
  `_clear_cached_lookups()`.

Observed after V1: the extra manual clear is redundant because
`_unregister_lookup()` now owns the invalidation.

Expected: production code should be correct even without caller-side manual
cache clearing. Tests may later be simplified, but this task forbids modifying
test files.

Evidence: SPEC E-008.

Resolution: no source change. Record as guidance only. This supports
PROOF_OBLIGATIONS O-007.

## F-004: Missing lookup remains outside the intended domain

Classification: preserved precondition/partial API behavior.

Input/state:

- `_unregister_lookup(cls, lookup_name)` is called when
  `cls.class_lookups[lookup_name]` is absent.

Observed and expected: `del cls.class_lookups[lookup_name]` raises `KeyError`.
The method is documented as test-only cleanup and existing behavior does not
promise idempotence.

Evidence: SPEC E-006 and the existing method body.

Resolution: V1 does not add an idempotent guard. This satisfies
PROOF_OBLIGATIONS O-001 and O-005.

## F-005: Public compatibility is unchanged

Classification: compatibility confirmation.

Input/state:

- Internal callers invoke `_unregister_lookup(lookup, lookup_name=None)`.
- `django.contrib.postgres.apps.uninstall_if_needed()` and
  `django.test.utils.register_lookup()` depend on the existing signature and
  exception behavior.

Observed after V1: signature, return value, and deletion behavior are
unchanged. Only cache invalidation is added after a successful mutation.

Expected: callers get the same registry cleanup behavior plus correct cache
state.

Evidence: SPEC E-006, E-007, E-008 and `PUBLIC_COMPATIBILITY_AUDIT.md`.

Resolution: no compatibility code changes needed. This satisfies
PROOF_OBLIGATIONS O-005 and O-007.

## Proof-derived Findings From `/verify`

No proof-derived code defect remains in V1. The constructed proof requires the
precondition that the lookup entry exists before deletion; this is intentional
and supported by the method's test-only cleanup contract. Total correctness,
thread safety, and K machine checking are not established.

