# FVK Specification

Status: constructed, not machine-checked.

## Scope

This FVK pass audits the V1 fix for `django__django-11179`: the observable behavior of `Model.delete()` on a saved, fast-deletable model instance with no dependencies. The full Django ORM is not modeled; source inspection supplies frame obligations for queryset deletes, cascades, signal paths, and field updates.

## Public Intent Ledger

- E1/E2: The issue explicitly requires that deleting an instance with no dependencies clears the in-memory primary key to `None`.
- E3/E6: The existing normal collected-instance path already clears primary keys and is the reference behavior the optimized branch must match.
- E4: `Model.delete()` delegates to `Collector.delete()`, so the root behavior sits in `repo/django/db/models/deletion.py`.
- E5: `can_fast_delete()` excludes cascades, parents, signal listeners, and private bulk-related fields, so the optimized branch is a no-dependencies/no-field-update path.
- E7: `QuerySet.delete()` does not expose a specific instance whose PK must be cleared.
- E8: V1 adds the missing PK clear after the optimized branch's SQL delete returns.

## Contract

For every saved instance `instance` of model `model` with primary key value `P`, if `Collector.delete()` takes the optimized single-object fast-delete branch and `DeleteQuery(model).delete_batch([P], using)` returns normally with row count `C`, then:

- `getattr(instance, model._meta.pk.attname) is None` after `delete()`;
- the returned delete count and per-model dictionary remain `C, {model._meta.label: C}`;
- no queryset, cascade, signal, or field-update behavior is changed by this branch-local cleanup.

The normal collected-instance path retains its existing postcondition: after database deletion and post-delete signals, all collected concrete instances have their model primary-key attname set to `None`.

## Formal Artifacts

- `fvk/mini-django-delete.k` defines a minimal K-style semantics fragment for the issue-relevant delete steps.
- `fvk/django-delete-spec.k` states the optimized fast-delete and normal collected-delete cleanup claims with SPEC-PROVENANCE comments.
- `fvk/FORMAL_SPEC_ENGLISH.md` paraphrases the K claims.
- `fvk/SPEC_AUDIT.md` checks those paraphrases against this intent spec.

## Domain and Boundaries

The proof is partial correctness over normal return from the database delete step. It intentionally does not claim behavior for exceptions raised by `delete_batch()`. It also does not prove full database integrity, SQL row-count accuracy, signal dispatch, cascade ordering, or queryset deletion internals; those are frame conditions because the V1 source change does not alter them.
