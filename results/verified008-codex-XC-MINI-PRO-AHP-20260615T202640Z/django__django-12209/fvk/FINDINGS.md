# FINDINGS

Status: constructed, not machine-checked. Findings are derived from public intent, source inspection, and the FVK proof obligations; no tests or tooling were run.

## F1 - Raw fixture reloads with explicit primary keys were the operative regression

Input: `raw=True`, `force_insert=False`, `adding=True`, primary-key default present, `pk_set=True`, and the row already exists.

Observed before V1: the optimization ignored `raw`, set `force_insert=True`, skipped UPDATE, and attempted INSERT. With an existing primary key this produced the duplicate-insert failure described by the issue's `loaddata` side effect.

Expected: raw deserialization should preserve the update-then-insert save behavior. Existing rows should be updated and no INSERT should be attempted.

V1 status: resolved. The `not raw` guard prevents the optimization from running in this input class.

Proof obligation: PO1.

## F2 - Raw fixture loads must still insert missing rows

Input: `raw=True`, `force_insert=False`, `adding=True`, primary-key default present, `pk_set=True`, and no row exists.

Expected: `_save_table()` should try UPDATE, observe that no row was updated, and then INSERT.

V1 status: confirmed. Because `raw=True` disables the optimization, `pk_set and not force_insert` enters the UPDATE branch, and `not updated` then reaches INSERT.

Proof obligation: PO2.

## F3 - Normal non-raw explicit-pk saves remain a residual compatibility limitation

Input: `raw=False`, `force_insert=False`, `adding=True`, primary-key default present, `pk_set=True`, and the row already exists because the caller supplied `Sample(pk=existing_pk)`.

Observed in V1: the optimization still sets `force_insert=True`, so this path attempts INSERT and may fail on duplicate primary key.

Expected under the strongest opening issue sentence: UPDATE should be attempted first, matching Django 2.2 behavior.

Selected patch interpretation: not fixed in V2. The public discussion explicitly says Django does not track whether a pk came from `Model.__init__()` defaults or from the caller, accepts preserving the optimization, and suggests `force_update` as the workaround for the direct non-raw pattern while branching on `raw` for fixtures.

Status: documented residual limitation, not a proof of complete backward compatibility. This finding blocks any claim that V1 fixes every behavior mentioned in the opening example, but it does not block confirming V1 for the selected fixture/raw repair.

Proof obligation: PO4.

## F4 - A `pk_set`-only condition is not adequate in this codebase

Input family: model instances whose primary key field has a Python default such as `UUIDField(default=uuid4)`.

Observed implementation fact: `Model.__init__()` assigns field defaults before `_save_table()`, so `pk_set=True` for both a generated default pk and a caller-supplied pk.

Rejected alternative: changing the optimization to require `not pk_set`.

Reason: it would disable the insert-only optimization for the common generated-default case and would contradict the public discussion's desire to keep the optimization.

Proof obligation: PO3.

## F5 - Public compatibility risk from V1 is low

Input: public callers of `save()`, `save_base()`, serializer `DeserializedObject.save()`, and `_save_table()` internals.

Observed: V1 does not change signatures, return values, or public call shapes. It only changes a branch condition inside `_save_table()`.

Expected: raw serializer saves continue to pass `raw=True`; ordinary saves continue to pass `raw=False`.

V1 status: confirmed by source inspection.

Proof obligation: PO5.
