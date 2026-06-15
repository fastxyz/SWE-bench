# SPEC

Status: constructed, not machine-checked. No tests, Python, `kompile`, or `kprove` were run.

## Intent Specification

The audited unit is the `_save_table()` branch in `repo/django/db/models/base.py` that decides whether to skip the UPDATE attempt for new model instances whose primary key field has a default.

Required behavior in scope:

1. Raw deserialization saves with an explicit primary key, a primary-key default, and an existing database row must try UPDATE rather than forcing INSERT.
2. Raw deserialization saves with an explicit primary key, a primary-key default, and no existing row must preserve Django's ordinary update-then-insert fallback.
3. Non-raw creation of a new instance whose primary key was generated from a Python field default must preserve the insert-only optimization that avoids the extra UPDATE.
4. The change must not alter public method signatures or the serializer protocol. `DeserializedObject.save()` must still call `Model.save_base(..., raw=True, **kwargs)`.

Out of scope for the selected patch:

1. Normal non-raw `Sample(pk=existing_pk).save()` remains an accepted limitation in this issue discussion. The public discussion says Django does not track whether a constructor primary key came from a default or from the caller, and proposes documenting `force_update` for this direct pattern while fixing fixture loading through the `raw` branch.

## Public Evidence Ledger

| ID | Source | Evidence | Obligation | Status |
| --- | --- | --- | --- | --- |
| I1 | prompt | "loaddata ... fixture contains explicit pk values and the objects already exist" | Raw fixture loads must not force INSERT when the fixture pk already exists. | Encoded by K claim `raw_existing_updates`. |
| I2 | prompt | "loading the fixture multiple times" | Repeated fixture loads should update existing rows instead of raising duplicate primary-key insert errors. | Encoded by K claim `raw_existing_updates`; V1 satisfies it. |
| I3 | public hint | "Regarding the fixture loading we should branch of raw ... to disable the optimiation." | The optimization must be disabled when `raw=True`. | Encoded by the `not raw` condition in V1 and by the K transition rule. |
| I4 | public hint | "it does reduce the number of queries significantly when using primary key defaults" | Keep the non-raw insert-only optimization for new objects whose pk comes from the default. | Encoded by K claim `nonraw_default_insert_only`. |
| I5 | public hint | "documenting it as a backward incompatible change that can be worked around by passing force_update" | Direct non-raw explicit-pk saves are a residual compatibility limitation, not a required code change in this patch. | Recorded as Finding F3, not used as a success proof. |
| C1 | code | `DeserializedObject.save()` calls `models.Model.save_base(self.object, using=using, raw=True, **kwargs)`. | Fixture/deserializer saves reach `_save_table(raw=True, ...)`. | Used as implementation evidence for the raw-path claim. |
| C2 | code | `_save_table()` only attempts UPDATE under `if pk_set and not force_insert`. | The proof must show `force_insert` remains false for raw fixture saves. | Encoded in the mini K model. |

## Domain and Abstraction

The K model abstracts the `_save_table()` branch to six Boolean inputs:

- `Raw`: the `raw` argument to `_save_table()`.
- `ForceInsertIn`: incoming `force_insert`.
- `Adding`: `self._state.adding`.
- `HasPkDefault`: the primary key field has a non-`NOT_PROVIDED` truthy default, matching the optimized branch.
- `PkSet`: `_save_table()` has a non-`None` primary key value.
- `RowExists`: the database contains a row matching the primary key.

The observable is the query class sequence and whether the row was updated:

- `saved(true, update .Queries)` means UPDATE happened and no INSERT was attempted.
- `saved(false, update insert .Queries)` means UPDATE found no row, then INSERT happened.
- `saved(false, insert .Queries)` means INSERT-only.
- `saved(false, duplicate .Queries)` models the duplicate primary-key failure shape when INSERT is attempted for an existing row.

This abstraction is property-complete for the issue because the defect is exactly whether the `force_insert` optimization suppresses the UPDATE branch. It intentionally frames out signals, parent saves, field pre-save conversion, and database-specific SQL because those do not decide this branch.

## Formal Core

Formal semantics file: `fvk/mini-django-save.k`.

Formal claim file: `fvk/save-table-spec.k`.

Exact commands to machine-check later, not run in this session:

```sh
kompile fvk/mini-django-save.k --backend haskell
kast --backend haskell fvk/save-table-spec.k
kprove fvk/save-table-spec.k
```

Expected machine-check result after running the commands in an environment with K installed: `#Top`.

## Formal Spec English

Claim 1, raw existing row: For any raw save in the issue domain with incoming `force_insert=False`, adding state, a primary-key default, a non-`None` primary key, and an existing row, execution reaches `saved(true, update .Queries)`. In Django terms, `_save_table()` tries UPDATE and does not attempt INSERT.

Claim 2, raw missing row: For the same raw save domain when no row exists, execution reaches `saved(false, update insert .Queries)`. In Django terms, `_save_table()` first attempts UPDATE, then falls back to INSERT.

Claim 3, non-raw generated-default creation: For a non-raw save in adding state with a primary-key default, a set primary key, incoming `force_insert=False`, and no existing row, execution reaches `saved(false, insert .Queries)`. In Django terms, `_save_table()` preserves the insert-only optimization.

## Spec Audit

| Claim | Adequacy result | Reason |
| --- | --- | --- |
| Raw existing row updates | Pass | Directly matches I1, I2, and I3. The formal model's discriminator distinguishes V1 from the pre-fix branch: without `not raw`, this input reaches `duplicate`, not `update`. |
| Raw missing row falls back to insert | Pass | Entailed by historical save behavior and required to keep fixture loading useful when rows are absent. |
| Non-raw generated-default insert-only | Pass | Entailed by I4 and the accepted compromise in I5. |
| Normal non-raw explicit-pk update | Ambiguous / excluded from success proof | The opening issue example asks for this behavior, but later public discussion explicitly accepts the `force_update` workaround to preserve the optimization. This remains Finding F3 and cannot be used as proof that the broader compatibility concern is fixed. |

## Public Compatibility Audit

No public API signature changed. The V1 code adds only a Boolean guard inside `_save_table()`.

Public callsite checks:

- `Model.save()` still calls `save_base()` with the same arguments.
- `Model.save_base()` still passes the `raw` argument into `_save_table()`.
- `DeserializedObject.save()` still calls `Model.save_base(self.object, using=using, raw=True, **kwargs)`.
- Public serializers can continue passing `force_insert` through `DeserializedObject.save(**kwargs)`.

No subclass override or virtual dispatch compatibility issue is introduced by V1.
