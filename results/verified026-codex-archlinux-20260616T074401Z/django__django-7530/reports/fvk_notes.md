# FVK Notes

## Decision summary

V1 stands unchanged. The audit concluded that the V1 source change satisfies the
public issue intent: router calls made by the `makemigrations` consistency
check are now generated from each app config's own models instead of from a
project-wide model list crossed with every app label.

## Source decisions

`repo/django/core/management/commands/makemigrations.py`

Decision: keep V1 unchanged.

Reasoning trace:

- `fvk/FINDINGS.md` F1 identifies the root defect as the pre-fix
  `app_label`/`apps.get_models(app_label)` cross-product and confirms V1 fixes
  it by using `app_config.get_models()`.
- `fvk/PROOF_OBLIGATIONS.md` PO1 and PO2 require every router call to pair an
  app label with a model yielded by that same app config. V1 discharges this
  directly with the nested generator over `app_config` and
  `app_config.get_models()`.
- PO3 permits Python `any()` short-circuiting because the gate is existential:
  the code need only find whether at least one valid pair is allowed.
- F2 plus PO4 and PO5 confirm V1 preserves the original database-selection
  behavior and dummy-engine skip.

Decision: do not change `model_name=model._meta.object_name` or add a `model`
hint.

Reasoning trace:

- F3 records this as an audited non-change.
- PO6 frames router call-shape compatibility. The public issue requires valid
  app/model combinations; it does not require changing model-name casing or
  hint payload.
- Broadening the patch to alter those router API details would introduce
  behavior not justified by this issue's evidence.

Decision: do not modify tests.

Reasoning trace:

- F4 and PO7 record the task restriction and FVK honesty gate: no tests or K
  tools were run, and no proof result is machine-checked.
- The task explicitly forbids modifying test files.

## Artifact decisions

Created the required FVK artifacts:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

Created additional formal-core artifacts required by the FVK method:

- `fvk/mini-python-router.k`
- `fvk/makemigrations-router-spec.k`

These `.k` files model the router-pair stream rather than all of Django because
the issue's observable behavior is exactly the `(app_label, model_name)` pairs
passed into `allow_migrate()` by this consistency check.

## Commands not run

The following commands are recorded in `fvk/PROOF.md` for a future environment
but were not executed:

```sh
kompile fvk/mini-python-router.k --backend haskell
kast --backend haskell fvk/makemigrations-router-spec.k
kprove fvk/makemigrations-router-spec.k
```

No tests, Python, or K framework tooling were run.
