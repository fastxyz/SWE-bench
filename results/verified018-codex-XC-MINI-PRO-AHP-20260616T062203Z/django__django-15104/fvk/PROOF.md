# FVK Proof

Status: constructed, not machine-checked. No commands in this file were executed.

## Claim Being Proved

For every finite in-contract `fields` mapping, `only_relation_agnostic_fields(fields)` returns the sorted list of field deconstructions where:

1. field names are ignored,
2. non-relational fields are unchanged,
3. relational fields have the `"to"` keyword removed if it exists,
4. relational fields whose deconstructed kwargs omit `"to"` do not raise and are otherwise unchanged.

## Proof Sketch

Let `D(field) = (path, args, kwargs)` be the result of `deep_deconstruct(field)`.

The function iterates over `sorted(fields.items())`, so every input field is visited exactly once in sorted-name order. Each iteration appends exactly one `deconstruction` value to `fields_def`, so the output cardinality and order follow directly from the loop structure.

For each visited field, there are two top-level cases.

Case 1: `field.remote_field and field.remote_field.model` is false. The function executes no dictionary mutation and appends `D(field)`. This proves PO-004 for that field.

Case 2: `field.remote_field and field.remote_field.model` is true. V1 executes `deconstruction[2].pop('to', None)`. Since `deconstruction[2]` is a dictionary by the field deconstruction contract, Python dictionary `pop(key, default)` is total for both membership cases:

* If `"to" in kwargs`, it removes `"to"` and preserves every other key/value pair. This proves PO-002.
* If `"to" not in kwargs`, it returns `None` and leaves `kwargs` unchanged. This proves PO-001 and PO-003.

By induction over the finite sorted field list, the per-field result composes into the full returned list. The only state mutation is to the newly constructed deconstruction dictionary returned by `deep_deconstruct()`, so no public call protocol or field object state is changed by the V1 edit.

## Symbolic Trace For The Reported Failure

Pre-fix relational missing-key path:

```text
Rel(field) = true
D(field) = (P, A, KWS)
"to" not in KWS

old body: del KWS["to"]  ==> KeyError
```

V1 relational missing-key path:

```text
Rel(field) = true
D(field) = (P, A, KWS)
"to" not in KWS

new body: KWS.pop("to", None) ==> None, KWS unchanged
append (P, A, KWS)
```

This is exactly the public reproducer's failing branch.

## Adequacy Check

The formalized English contract matches the public intent:

* The issue asks for custom hardcoded relation targets with omitted serialized `to` to be accepted rather than crashing.
* The helper docstring asks for relation targets to be ignored for rename detection.
* V1 preserves target erasure when `to` exists and expands the behavior only to tolerate the missing-key case.

No proof obligation depends on hidden tests, upstream fixes, or candidate behavior alone.

## Non-Executed Machine-Check Commands

The task prohibits K tooling. If standalone `.k` files were extracted from the K-style claims in `SPEC.md`, the commands to run outside this session would be:

```sh
kompile mini-python.k --backend haskell
kast --backend haskell autodetector-spec.k
kprove autodetector-spec.k
```

Expected result after a faithful extraction: `#Top` for the listed claims.

## Test Recommendation

No tests were run and no test files were modified. Keep all tests in this session.

Future tests worth adding outside this task:

* a custom `ForeignKey` subclass whose `deconstruct()` omits `"to"` and whose model state is passed through `MigrationAutodetector._detect_changes()`;
* a normal relational field whose deconstruction includes `"to"` to confirm target erasure remains unchanged;
* a non-relational field to confirm no unrelated kwargs are removed.
