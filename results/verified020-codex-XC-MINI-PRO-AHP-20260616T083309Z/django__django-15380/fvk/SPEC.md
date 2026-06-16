# FVK Specification

Status: constructed, not machine-checked. No tests, Python, or K tooling were run.

## Scope

Target under audit:

- `repo/django/db/migrations/autodetector.py`
- `MigrationAutodetector.generate_renamed_models()`
- `MigrationAutodetector._prepare_field_lists()`
- `MigrationAutodetector.generate_renamed_fields()`

The formalized unit is the state-key contract needed to detect a field rename
after a model rename. This is the property that directly distinguishes the
reported crash from the intended behavior. The full Django `ProjectState`,
field deconstruction, questioner interaction, operation sorting, and migration
graph construction are treated as trusted context outside this focused model.

## Intent Spec

I-001. If `makemigrations` detects and accepts a model rename, and a field on
that renamed model was also renamed in the same autodetection pass, migration
autodetection must not crash with `KeyError`.

I-002. After a model rename, the old model name is still the correct key for
reading the historical model from `from_state`.

I-003. After a model rename, the new model name is the correct key for reading
the target model from `to_state`.

I-004. Field rename operations produced after a model rename must be attached
to the new model key, because `generate_renamed_models()` rewrites
`old_model_keys` to keep the renamed model under the new key for the rest of
autodetection.

I-005. Behavior without a model rename must be preserved: when no rename map
entry exists, the old and new model keys are the same.

I-006. Public API and dispatch shape must be preserved. The fix must not change
method signatures, return types, call protocols, or test files.

## Public Evidence Ledger

E-001. Source: `benchmark/PROBLEM.md`.
Quoted evidence: "Migration autodetector crashes when renaming a model and
field in a single step".
Obligation: simultaneous model and field rename is in domain and must not crash.
Status: encoded by O-001, O-002, and O-004.

E-002. Source: `benchmark/PROBLEM.md`.
Quoted evidence: traceback points to
`generate_renamed_fields`: `new_model_state =
self.to_state.models[app_label, old_model_name]`, followed by
`KeyError: ('test_one', 'mymodel')`.
Obligation: the pre-fix old-name lookup in `to_state` is suspect legacy
behavior and must not be preserved.
Status: encoded by O-003 as the failing counterexample.

E-003. Source: implementation.
Quoted evidence: `self.renamed_models[app_label, model_name] = rem_model_name`
in `generate_renamed_models()`.
Obligation: for a renamed model, `renamed_models[(app_label, new_model_name)]`
returns the old model name.
Status: encoded by O-001.

E-004. Source: implementation.
Quoted evidence: `self.old_model_keys.remove((rem_app_label, rem_model_name))`
then `self.old_model_keys.add((app_label, model_name))`.
Obligation: after model rename detection, the kept model key for later field
processing is the new model key.
Status: encoded by O-001 and O-002.

E-005. Source: implementation.
Quoted evidence: `_prepare_field_lists()` reads old fields from
`from_state.models[app_label, self.renamed_models.get(...)]` while storing
field-key tuples under `(app_label, model_name)`.
Obligation: old fields are read from the old model state but keyed under the
new model name for comparison.
Status: encoded by O-002.

E-006. Source: implementation.
Quoted evidence: `_prepare_field_lists()` reads new fields from
`self.to_state.models[app_label, model_name]`.
Obligation: the new-state lookup key is the current kept model key.
Status: encoded by O-002 and O-004.

E-007. Source: implementation.
Quoted evidence: adjacent generators such as `create_altered_indexes()` and
`_get_altered_foo_together_operations()` use `old_model_name` for
`from_state` and `model_name` for `to_state`.
Obligation: the same old/new key split is the local invariant for renamed
models.
Status: encoded by O-004 and O-005.

## Formal Spec English

FSE-001. For any app `A`, old model key `(A, O)`, and new model key `(A, N)`,
after an accepted model rename from `O` to `N`, the rename map stores
`(A, N) -> O`, and the later kept model key is `(A, N)`.

FSE-002. Field-list preparation for that renamed model constructs old field
keys under `(A, N, old_field)` by reading field names from
`from_state.models[(A, O)]`, and constructs new field keys under
`(A, N, new_field)` by reading field names from `to_state.models[(A, N)]`.

FSE-003. On the simultaneous rename scenario where `to_state.models` contains
`(A, N)` and does not contain `(A, O)`, a target-state lookup with
`old_model_name = O` is undefined and reproduces the reported `KeyError`.

FSE-004. Under the same scenario, the V1 target-state lookup with
`model_name = N` is defined before `get_field(new_field)` is called.

FSE-005. If there is no model rename, `old_model_name == model_name`; the V1
lookup is extensionally the same as the pre-existing lookup.

FSE-006. The source fix changes one internal lookup expression only and does
not alter public method signatures, operation classes, or test files.

## Spec Audit

FSE-001 passes. It is entailed by E-003 and E-004.

FSE-002 passes. It is entailed by E-005 and E-006.

FSE-003 passes. It is the failing behavior reported by E-002 and is used only
as a counterexample, not as intended behavior.

FSE-004 passes. It is entailed by E-001, E-004, E-006, and E-007.

FSE-005 passes. It is the default-domain frame condition for unchanged
non-renamed models and follows from `dict.get(key, model_name)` when no rename
entry exists.

FSE-006 passes. It is confirmed by the V1 diff and by unchanged method
signatures.

No formal-English claim is candidate-derived without public or local invariant
support. No claim preserves the suspect pre-fix `to_state[(A, O)]` lookup.

## Public Compatibility Audit

Changed symbol: `MigrationAutodetector.generate_renamed_fields()`.

Compatibility status:

- Method name and signature are unchanged.
- Return behavior is unchanged: the method mutates autodetector state and adds
  operations as before.
- Public operation classes are unchanged.
- No caller protocol, virtual dispatch keyword, storage format, or test file is
  changed.

Conclusion: no public compatibility issue is introduced.

## Formal Artifacts

Constructed K artifacts:

- `fvk/mini-django-autodetector.k`
- `fvk/autodetector-spec.k`

Commands to machine-check later, not executed here:

```sh
kompile fvk/mini-django-autodetector.k --backend haskell
kast --backend haskell fvk/autodetector-spec.k
kprove fvk/autodetector-spec.k
```
