# FVK Findings

Status: constructed, not machine-checked.

## F-1: Pre-fix save alias mismatch

Input/state: `schema_editor.connection.alias = "tenant"`, `router.db_for_write(ContentType, instance=content_type) = "default"`, and the old content type row exists only on `"tenant"`.

Observed before V1: `content_type.save(update_fields={'model'})` calls `Model.save()` with `using=None`, so `Model.save()` may select `router.db_for_write(...)`. In the reported dynamic-router setup, the write is attempted on `"default"`, where `django_content_type` does not exist.

Expected: the save must target `"tenant"`, the alias used by the migration schema editor.

Classification: code bug, resolved by V1.

Related proof obligations: PO-1, PO-2, PO-3.

## F-2: `transaction.atomic(using=db)` is not a routing proof

Input/state: any `_rename()` path where the save call omits `using=db`.

Observed before V1: the transaction context is opened for `db`, but `Model.save()` still computes its database independently when `using` is absent.

Expected: the explicit model save must receive `using=db`.

Classification: proof-derived finding explaining why the pre-fix code fails.

Related proof obligations: PO-2, PO-3.

## F-3: V1 satisfies the routing obligation

Input/state: migration allowed on `db`, old content type exists on `db`, and no stale-content-type conflict occurs.

Observed in V1 by static source reasoning: `_rename()` calls `content_type.save(using=db, update_fields={'model'})`; `Model.save()` preserves the explicit alias because `using = using or router.db_for_write(...)`; `_save_table()` builds its update queryset with `.using(using)`.

Expected: the write target equals `schema_editor.connection.alias`.

Classification: resolved, no additional source edit justified.

Related proof obligations: PO-1, PO-3, PO-5.

## F-4: Existing no-op and conflict behavior remains in scope

Input/state: migration disallowed, old content type missing, or a stale-content-type conflict raises `IntegrityError`.

Observed in V1: these branches are unchanged from the pre-existing code.

Expected: the issue does not ask to change these branches; they are frame conditions needed to keep the fix minimal.

Classification: resolved frame condition.

Related proof obligations: PO-4, PO-6, PO-7.

## F-5: No public API compatibility issue from the V1 call

Input/state: direct call to Django's `Model.save()` from `_rename()`.

Observed in source: `Model.save()` already accepts `using=None` and `update_fields=None`. V1 adds a keyword at a concrete call site and does not change method signatures.

Expected: existing public APIs and migration operation injection remain compatible.

Classification: resolved compatibility check.

Related proof obligations: PO-8.

## F-6: Proof status is constructed, not machine-checked

Input/state: all formal claims in the FVK artifacts.

Observed in this session: K tooling was not run because the benchmark forbids executing K framework tooling.

Expected: keep the proof honesty caveat and do not remove or modify tests based on the constructed proof.

Classification: proof process limitation, not a code bug.

Related proof obligations: PO-9.
