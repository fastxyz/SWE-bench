# Iteration Guidance

Status: constructed, not machine-checked.

## V2 changes justified by FVK

1. Add `Collector._can_optimize_delete_queryset()`.

   Justification: F1 and PO8 showed that optimization needs dynamic-dispatch
   opt-out for collectors whose purpose is display/materialization rather than
   production deletion.

2. Override `_can_optimize_delete_queryset()` in `NestedObjects`.

   Justification: F1 showed that admin deletion preview calls
   `super().related_objects()` and then `select_related()`, and its existing
   `can_fast_delete()` comment requires loaded objects for display.

3. Return `_delete_fields()` in `opts.concrete_fields` order.

   Justification: F2 and PO7 showed that V1's set expansion was unnecessarily
   nondeterministic even though Django metadata has a stable concrete field
   order.

## V1 decisions confirmed

1. Use `QuerySet.only()` instead of changing the SQL compiler.

   Justification: PO3 ties `only()` to Django's existing deferred-loading
   machinery, keeping the change scoped to the deletion collector.

2. Include non-primary-key `foreign_related_fields`.

   Justification: SPEC E5 and PO1 require `ForeignKey(to_field=...)` support.

3. Disable optimization when relevant signal listeners are present.

   Justification: SPEC E6 and PO5 require preserving full instances for signal
   receivers because Django cannot introspect receiver field usage.

4. Keep `bulk_related_objects()` unchanged.

   Justification: F3 and PO9 classify generic/private relation hooks as a
   separate projection problem.

## Tests to add in a normal environment

Do not add tests in this benchmark, but a normal patch should include tests for:

- Root queryset projection: deleting a model with extra concrete fields selects
  only the primary key when no related key fields are needed.
- Nested cascade projection: deleting through a cascade chain does not select an
  unrelated text field on a related model.
- Non-primary-key reference: a reverse `ForeignKey(to_field=...)` includes the
  target field on the source model.
- Signal opt-out: a model with a `pre_delete` or `post_delete` listener is not
  projected by the new optimization.
- Admin compatibility: `NestedObjects.related_objects()` returns a queryset that
  can still be `select_related()` and display related objects without deferred
  field conflicts.

## Machine-check follow-up

The constructed proof is not machine-checked. If standalone K files are
completed, run:

```sh
kompile fvk/mini-delete.k --backend haskell
kast --backend haskell fvk/delete-collector-spec.k
kprove fvk/delete-collector-spec.k
```

Keep all tests until the K proof and Django test suite can be run in an
appropriate environment.

## Open boundaries

- Generic relation hooks: see F3.
- Annotation and `extra(select=...)` outputs: see F4.
- Custom `on_delete` callables that inspect deferred fields: see F5.

These boundaries do not block V2 because they are not required by the public
issue evidence used in `SPEC.md`.
