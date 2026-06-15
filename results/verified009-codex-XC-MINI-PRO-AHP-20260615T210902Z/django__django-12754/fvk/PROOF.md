# FVK Proof

Status: constructed, not machine-checked. No `kompile`, `kprove`, Python, or
Django test command was executed.

## Theorem

For every in-scope migration autodetection change where a new concrete subclass
declares a local field removed from one of its direct concrete bases in the
same change set, V1 orders the generated operations so the base `RemoveField`
happens before the subclass `CreateModel`. For related fields split into
`AddField`, V1 also orders the base `RemoveField` before the subclass
`AddField`.

## Proof Sketch

1. Let `B` be a direct string base of new model `M`, and let `F` be a local
   field declared by `M`.

2. Suppose `(B.app, B.model_lower, F)` is in
   `self.old_field_keys - self.new_field_keys`. This is exactly the
   autodetector representation of a field removed from a kept model.

3. By PO-001, V1 appends `(B.app, B.model, F, False)` to the `_auto_deps` list
   of `CreateModel(M)`.

4. By PO-005, `generate_removed_fields()` emits one `RemoveField(B, F)` for
   the removed field and V1 does not emit additional remove operations.

5. By PO-002, `check_dependency(RemoveField(B, F), (B.app, B.model, F, False))`
   returns true.

6. If `B` and `M` are in the same app, PO-003 applies: `_sort_migrations()`
   adds an edge from `CreateModel(M)` to `RemoveField(B, F)`, and stable
   topological sorting emits dependencies first. Therefore `RemoveField(B, F)`
   precedes `CreateModel(M)`.

7. If `B` and `M` are in different apps, PO-004 applies: `_build_migration_list()`
   sees the external dependency as unsatisfied while the matching
   `RemoveField(B, F)` remains unchopped in the base app. After the base app
   migration is generated, the child app migration records a dependency on it.
   Therefore the migration containing `RemoveField(B, F)` precedes the
   migration containing `CreateModel(M)`.

8. If `F` is a related field split into a later `AddField(M, F)`, PO-006
   applies. V1 still detects `F` through `model_state.fields`, and existing code
   makes `AddField(M, F)` depend on `CreateModel(M)`. Therefore the order is
   `RemoveField(B, F)`, then `CreateModel(M)`, then `AddField(M, F)`.

9. By PO-008, migration optimization does not move `RemoveField(B, F)` across
   `CreateModel(M)` when `M` inherits from `B`, because the optimizer treats
   the create operation as referencing the base model.

Thus the reported bad order is eliminated for the specified issue domain.

## Adequacy Result

The theorem is adequate for the public issue because I-001 requires the
reversed operation order, I-002 identifies removed-field dependencies as the
intended mechanism, and I-003 requires preserving a single base `RemoveField`
when several subclasses are added. The proof does not rely on hidden tests,
benchmark verdicts, or upstream patches.

## Residual Risk

This is a partial-correctness proof over an abstract operation-ordering model.
It does not prove full Django state rendering, database schema-editor effects,
termination, or compatibility for issue variants outside the public intent
domain such as simultaneous base-field renaming rather than removal.

The proof is constructed, not machine-checked. If K tooling were available, the
commands to check the abstract proof artifacts would be recorded as:

```sh
kompile fvk/mini-migration-autodetector.k --backend haskell
kast --backend haskell fvk/migration-autodetector-spec.k
kprove fvk/migration-autodetector-spec.k
```

Those commands were not run. No test removal is recommended.

## Verdict

V1 stands unchanged. The FVK obligations close over the public issue domain,
and the remaining caveat is lack of machine execution, not a source-code gap.
