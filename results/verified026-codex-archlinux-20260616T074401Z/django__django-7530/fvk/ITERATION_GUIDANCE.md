# FVK Iteration Guidance

Status: V1 stands unchanged.

## Decision

Keep the V1 source patch. The FVK audit found that V1 satisfies the intent
captured in `fvk/SPEC.md` and discharges the obligations in
`fvk/PROOF_OBLIGATIONS.md`.

## Why No Source Revision Is Needed

The issue's operative defect is invalid app/model pair generation. V1 replaces
the cross-product source with app-local iteration:

```python
for app_config in app_configs
for model in app_config.get_models()
```

The constructed proof shows this emits only valid pairs and preserves the
history-check gate's existential semantics.

## Changes Not Applied

No change was made to `model_name=model._meta.object_name`.

Reason: the public issue evidence does not require changing `model_name` casing
or adding a `model` hint. That would be a separate router API compatibility
decision, not necessary to fix invalid combinations. See F3 and PO6.

No change was made to test files.

Reason: the task forbids modifying tests, and the proof is constructed rather
than machine-checked. See F4 and PO7.

## Suggested Future Tests

Do not add these in this task, but a future test suite could cover:

- two installed apps with disjoint model sets and a router that records every
  `(app_label, model_name)` pair seen by `makemigrations`;
- assertion that no recorded pair combines one app's label with another app's
  model;
- assertion that a non-dummy alias is still checked when at least one valid
  pair is allowed;
- assertion that a non-dummy alias is not checked when no valid pair is allowed.

## If Revisiting Scope Later

A separate issue could audit whether `makemigrations` should align its
`allow_migrate()` call payload with other router helper conventions, such as
lowercase model names or a `model` hint. That question was deliberately not
folded into this fix because it is not required to satisfy the reported
invalid-pair defect.
