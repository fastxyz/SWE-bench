# FVK Spec: django__django-15104

Status: constructed, not machine-checked. No tests, Python, or K tooling were run.

## Unit Under Audit

`MigrationAutodetector.only_relation_agnostic_fields(fields)` in `repo/django/db/migrations/autodetector.py`.

The helper is used by `generate_renamed_models()` to compare old and new model field definitions while ignoring the model target of relational fields.

## Public Intent Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| I-001 | `benchmark/PROBLEM.md` | "KeyError with migration autodetector and FK field with hardcoded reference" | A relational field whose runtime target is hardcoded must not crash migration autodetection merely because its deconstructed kwargs omit `to`. | Encoded in PO-001 and PO-003. |
| I-002 | `benchmark/PROBLEM.md` | The custom field sets `kwargs['to']` in `__init__()` and deletes `kwargs["to"]` in `deconstruct()`. | `field.remote_field.model` can be truthy even when `deep_deconstruct(field)[2]` has no `to` key. | Encoded in PO-001 and PO-003. |
| I-003 | `benchmark/PROBLEM.md` | "what related fields actually relate to" should be ignored; suggested change is `pop('to', None)`. | For relational fields, the normalized comparison value must omit `to` when present, and tolerate it when absent. | Encoded in PO-002 and PO-003. |
| I-004 | Source docstring | "Return a definition of the fields that ignores field names and what related fields actually relate to. Used for detecting renames." | Field names are not included in each returned deconstruction; relation targets are excluded from comparison. | Encoded in PO-002, PO-005. |
| I-005 | Source implementation of `deep_deconstruct()` and `Field.deconstruct()` | Field deconstruction returns `(path, args, kwargs)` after stripping the field name; `Field.deconstruct()` documents kwargs as a dict. | The proof may model each field's deconstruction as a triple whose third element is a finite dictionary. | Encoded in PO-007. |
| I-006 | Source call sites | The helper is called only from `generate_renamed_models()`. | No public API signature or call protocol should change. | Encoded in PO-006. |

No hidden tests, benchmark results, internet sources, or upstream patch knowledge were used.

## Intent-Only Contract

For a finite mapping `fields` from field names to field objects, `only_relation_agnostic_fields(fields)` returns a list containing one normalized deconstruction for each input field, ordered by sorted field name.

Let `D(field) = (path, args, kwargs)` be `deep_deconstruct(field)`, with `kwargs` a finite dictionary.

Let `Rel(field)` mean `field.remote_field and field.remote_field.model`.

The intended normalized deconstruction is:

```text
Normalize(field) =
    (path, args, kwargs without key "to")    if Rel(field)
    (path, args, kwargs)                    otherwise
```

The removal of `"to"` is total over dictionaries: if `"to"` is absent, the result is the original dictionary unchanged.

## Formal Model

The FVK model abstracts Python objects to the minimum state needed for this issue:

```text
Field ::= field(name, relFlag, deconstruction)
Deconstruction ::= dec(path, args, kwargs)
Kwargs ::= finite map from string keys to values

removeTo(kwargs) = kwargs with key "to" removed if present; kwargs unchanged if absent

normalize(field(_, true, dec(path, args, kwargs))) =
    dec(path, args, removeTo(kwargs))

normalize(field(_, false, dec(path, args, kwargs))) =
    dec(path, args, kwargs)

onlyRelationAgnosticFields(fields) =
    [normalize(fields[name]) for name in sorted(keys(fields))]
```

This model intentionally represents the property under audit: the presence or absence of the `"to"` key and the branch determined by `remote_field.model`.

## K-Style Claims

These are the claims the proof reasons about. They are written here rather than executed because the task prohibits K tooling.

```k
// SPEC-PROVENANCE:
// - I-001/I-002: relation fields may have no "to" key in deconstructed kwargs.
// - I-003/I-004: relation target must be ignored for rename comparison.
claim <k> normalize(field(N, true, dec(P, A, KWS))) => dec(P, A, removeTo(KWS)) </k>
  requires isDict(KWS)

// SPEC-PROVENANCE:
// - I-004: non-relation fields are compared by their ordinary deconstruction.
claim <k> normalize(field(N, false, dec(P, A, KWS))) => dec(P, A, KWS) </k>
  requires isDict(KWS)

// SPEC-PROVENANCE:
// - I-004/I-006: every field is normalized exactly once in sorted-name order.
claim <k> onlyRelationAgnosticFields(FIELDS) => mapList(normalize, valuesBySortedKey(FIELDS)) </k>
  requires finiteFieldMap(FIELDS)
```

Supporting totality axiom:

```k
claim <k> removeTo(KWS) => KWS -Map "to" </k>
  requires isDict(KWS)
```

Here `KWS -Map "to"` is defined whether or not `"to"` is a member of `KWS`.

## Scope And Non-Goals

This audit covers `only_relation_agnostic_fields()` and its direct rename-detection use. It does not attempt to prove all migration autodetector behavior.

The proof assumes field `deconstruct()` methods follow Django's documented contract and return a kwargs dictionary. A custom field returning a non-dict kwargs value is outside this spec.

Termination is not machine-proved. The source loop is over a finite mapping supplied by model state, so the partial-correctness proof is sufficient for the reported issue.
