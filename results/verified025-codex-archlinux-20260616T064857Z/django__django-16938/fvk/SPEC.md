# FVK Spec

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Scope

The audited units are the non-natural-key many-to-many serialization branches in:

- `repo/django/core/serializers/python.py::Serializer.handle_m2m_field`
- `repo/django/core/serializers/xml_serializer.py::Serializer.handle_m2m_field`

JSON, JSONL, and YAML inherit the Python serializer behavior. The XML serializer
has a separate implementation of the same primary-key reference behavior.

## Intent-only specification

1. For auto-created many-to-many relations whose related model is serialized by
   primary key, serialization must return references to the related primary keys.
2. A related model's default manager may use `select_related(...)`; that manager
   customization must not make primary-key-only m2m serialization raise
   `FieldError`.
3. The primary-key-only optimization should be preserved: the serializer should
   not fetch unrelated fields merely to serialize m2m primary key references.
4. Natural-key serialization remains outside this fix because it may need fields
   other than the primary key to compute `natural_key()`.
5. Non-auto-created through models remain outside this serializer path, matching
   the existing branch guard.

## Public evidence ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | "Serialization of m2m relation fails with custom manager using select_related" | Serialization must handle m2m relations even when the related default manager adds `select_related`. | Encoded in C1/PO-1. |
| E2 | `benchmark/PROBLEM.md` | The traceback raises `FieldError: Field TestTag.master cannot be both deferred and traversed using select_related at the same time.` | The fix must remove the `select_related`/`only("pk")` conflict, not preserve it. | Encoded in C1 and F-001. |
| E3 | `benchmark/PROBLEM.md` | "Maybe we could clear select_related()" | Clearing inherited `select_related` is public hint evidence. | Encoded as `select_related(None)`, not no-arg `select_related()`. |
| E4 | `repo/django/core/serializers/python.py` | Non-natural m2m values use `self._value_from_field(value, value._meta.pk)`. | The observable value is the related primary key list. | Encoded in C1/C2. |
| E5 | `repo/django/core/serializers/xml_serializer.py` | "Related objects are only serialized as references to the object's PK" | XML has the same primary-key-reference obligation. | Encoded in C4/PO-4. |
| E6 | `repo/django/db/models/query.py` | `select_related(None)` comment: "clear the list"; no-arg `select_related()` selects related objects. | The clearing operation must be `select_related(None)`. | Encoded in PO-3 and F-003. |
| E7 | `repo/django/db/models/query_utils.py` | `select_related_descend()` raises when a requested relation is absent from the select mask. | A selected relation plus `only("pk")` is the modeled failure. | Encoded in the pre-fix counterclaim. |

## Formal model

The K-style model is in `fvk/mini-serializer-queryset.k`; claims are in
`fvk/serializer-m2m-spec.k`.

The model abstracts a related queryset as:

- `Sel`: inherited `select_related` state (`noSelectRelated()` or
  `someSelectRelated()`).
- `Load`: selected-field mask (`allFields()` or `onlyPkField()`).
- `Rows`: related rows, each modeled only by primary key.

The fixed serializer operation is modeled as:

`serializeM2MNonNatural(uncached(QS)) = iteratorPks(onlyPk(clearSelectRelated(QS)))`

The pre-fix operation is modeled as:

`serializeM2MNonNaturalOld(QS) = iteratorPks(onlyPk(QS))`

## Formal spec English and adequacy audit

| Claim | English paraphrase | Intent match |
| --- | --- | --- |
| C1 | For any uncached related queryset, non-natural m2m serialization first clears inherited `select_related`, then loads only primary keys, then returns the related primary keys. | Pass: E1, E2, E3, E4. |
| C2 | For cached related objects, non-natural m2m serialization returns the cached related primary keys. | Pass: source-backed frame condition; not changed by V1. |
| C3 | The old operation raises `fieldError()` for a queryset with `someSelectRelated()` followed by `onlyPk`. | Pass as a counterexample: E2 and E7 identify the reported failure. |
| C4 | XML non-natural m2m serialization has the same primary-key-reference obligation as Python-derived serializers. | Pass: E5 plus the duplicated implementation. |
| C5 | Natural-key branches are not changed by the fix. | Pass: E4/E5 limit the primary-key-only obligation to the non-natural-key branch. |

No claim preserves a legacy error. No expected ordering rule is derived from the
candidate implementation; the list order is the related queryset iteration order,
which V1 does not change.

## Public compatibility audit

- No public symbol, method signature, return type, or storage format is changed.
- The new call uses the existing public QuerySet/Manager API
  `select_related(None)`, whose local source comment says it clears
  `select_related`.
- Existing serializer output shape is preserved: Python-derived serializers still
  produce a list of m2m values; XML still emits `<object pk="...">` elements.
- The only changed internal query state is removal of inherited
  `select_related` on a path that serializes primary keys only.
- Custom managers that implement Django's public QuerySet method surface remain
  compatible. A manager with an incompatible custom `select_related` override is
  outside the public contract modeled here and is not public evidence against V1.

## Commands to machine-check later

These commands were written but not executed:

```sh
kompile fvk/mini-serializer-queryset.k --backend haskell
kast --backend haskell fvk/serializer-m2m-spec.k
kprove fvk/serializer-m2m-spec.k --definition fvk/mini-serializer-queryset-kompiled
```
