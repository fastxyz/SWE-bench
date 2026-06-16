# FVK Proof

Status: constructed, not machine-checked. No tests, Python, `kompile`, `kast`,
or `kprove` were run.

## Claims proved in the constructed model

The mini-semantics in `fvk/mini-serializer-queryset.k` models the relevant
queryset state as selected relations, field loading mask, and related rows. The
spec claims in `fvk/serializer-m2m-spec.k` establish:

- C1: uncached non-natural-key m2m serialization returns related primary keys
  for any inherited `select_related` state.
- C2: cached non-natural-key m2m serialization returns cached related primary
  keys.
- C3: the pre-fix operation reaches `fieldError()` when a selected relation is
  combined with `only("pk")`.

## Symbolic proof sketch

Start with an arbitrary related queryset:

`qs(SEL, LOAD, ROWS)`

V1 composes the query as:

`iteratorPks(onlyPk(clearSelectRelated(qs(SEL, LOAD, ROWS))))`

Step 1:

`clearSelectRelated(qs(SEL, LOAD, ROWS)) => qs(noSelectRelated(), LOAD, ROWS)`

This follows PO-3 and the local QuerySet API for `select_related(None)`.

Step 2:

`onlyPk(qs(noSelectRelated(), LOAD, ROWS)) => qs(noSelectRelated(), onlyPkField(), ROWS)`

This preserves `ROWS` and changes only the field-loading mask.

Step 3:

`iteratorPks(qs(noSelectRelated(), onlyPkField(), ROWS)) => ok(projectPks(ROWS))`

The FieldError rule is not reachable because selected relation state is
`noSelectRelated()`.

By transitivity, for all `SEL`, `LOAD`, and `ROWS`:

`serializeM2MNonNatural(uncached(qs(SEL, LOAD, ROWS))) => ok(projectPks(ROWS))`

This discharges PO-1 and PO-2.

## Pre-fix counterexample

For the reported custom manager case, model the inherited queryset as:

`qs(someSelectRelated(), LOAD, ROWS)`

The old composition was:

`iteratorPks(onlyPk(qs(someSelectRelated(), LOAD, ROWS)))`

After `onlyPk`, the selected relation remains:

`qs(someSelectRelated(), onlyPkField(), ROWS)`

The mini-semantics then reaches:

`fieldError()`

This matches the traceback in the issue and localizes the cause to the
combination of inherited selected relations and the primary-key-only load mask.

## Serializer-family proof

Python-derived serializers use `repo/django/core/serializers/python.py`. JSON,
JSONL, and YAML subclass that serializer, so the Python claim covers those
formats.

XML uses `repo/django/core/serializers/xml_serializer.py`, which duplicates the
same non-natural-key m2m query path. V1 applies the same sequence there:

`select_related(None).only("pk").iterator()`

The proof above applies to XML with the output constructor changed from a Python
list entry to an XML `<object pk="...">` element. The query-state safety
obligation is identical, discharging PO-4.

## Frame conditions

The natural-key branch is unchanged. It does not apply `only("pk")`, so the
reported conflict is absent there, and clearing manager-level `select_related`
would be unjustified because `natural_key()` may need related fields.

The explicit-through branch is unchanged because both serializers already skip
serialization unless `field.remote_field.through._meta.auto_created` is true.

No public signatures or serializer output shapes changed.

## Test guidance

No tests were edited. Existing or future tests that assert the reported
non-natural-key m2m serialization case would be subsumed by C1 only after the K
claims are machine-checked. Until then, keep tests.

Recommended conventional tests for maintainers:

- JSON serialization of an object with an auto-created m2m to a model whose
  default manager uses `select_related("master")`.
- XML serialization of the same setup.
- A natural-key m2m serialization case to confirm the frame condition remains
  unchanged.

## Commands to machine-check later

These commands were not executed:

```sh
kompile fvk/mini-serializer-queryset.k --backend haskell
kast --backend haskell fvk/serializer-m2m-spec.k
kprove fvk/serializer-m2m-spec.k --definition fvk/mini-serializer-queryset-kompiled
```

Expected outcome in a K environment: `kprove` returns `#Top` for the claims.
