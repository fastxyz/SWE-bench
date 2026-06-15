# FVK Proof Obligations

Status: constructed, not machine-checked.

The obligations below are the formal core used to audit V1. They are written
as K-style reachability claims over the abstract model in `fvk/SPEC.md`; no K
tooling was run.

## Mini Semantics Sketch

```k
module MINI-MIGRATION-AUTODETECTOR
  imports BOOL
  imports STRING

  syntax Dep ::= depRemove(String, String, String)
               | depCreate(String, String)
  syntax Op  ::= create(String, String)
               | remove(String, String, String)

  // Abstract predicates supplied by the symbolic state:
  // removedField(App, ModelLower, Field)
  // baseOf(Model, BaseApp, BaseModel, BaseModelLower)
  // localField(Model, Field)
  // generated(Op)
  // autoDep(Op, Dep)
  // before(Op, Op)
endmodule
```

## PO-001: CreateModel receives removed-base-field dependency

Claim:

```text
requires baseOf(M, BApp, BModel, BModelLower)
     and localField(M, F)
     and removedField(BApp, BModelLower, F)
ensures autoDep(create(MApp, M), depRemove(BApp, BModel, F))
```

Source code evidence: `generate_created_models()` computes
`removed_field_keys = self.old_field_keys - self.new_field_keys`, filters those
keys by the normalized base model name, intersects with `model_state.fields`,
and appends `(base_app_label, base_name, field_name, False)` to dependencies
at `repo/django/db/migrations/autodetector.py:561-574`.

Discharges: F-001, F-003.

## PO-002: Removed-field dependency matches RemoveField operation

Claim:

```text
requires generated(remove(BApp, BModel, F))
     and D == depRemove(BApp, BModel, F)
ensures check_dependency(remove(BApp, BModel, F), D) == true
```

Source code evidence: `check_dependency()` branch for removed fields returns
true for `RemoveField` with matching lowercased model and field names at
`repo/django/db/migrations/autodetector.py:399-405`.

Discharges: F-001.

## PO-003: Same-app topological sort orders RemoveField before CreateModel

Claim:

```text
requires autoDep(create(App, M), depRemove(App, BModel, F))
     and generated(remove(App, BModel, F))
     and check_dependency(remove(App, BModel, F), depRemove(App, BModel, F))
ensures before(remove(App, BModel, F), create(App, M))
```

Source code evidence: `_sort_migrations()` adds `op2` as a dependency of `op`
when `check_dependency(op2, dep)` is true at
`repo/django/db/migrations/autodetector.py:342-356`. The stable topological
sort emits dependency-free layers first at `repo/django/utils/topological_sort.py:15-36`.

Discharges: F-001.

## PO-004: Cross-app dependency blocks subclass migration until base removal

Claim:

```text
requires autoDep(create(ChildApp, M), depRemove(BaseApp, BModel, F))
     and ChildApp != BaseApp
     and generated(remove(BaseApp, BModel, F))
ensures migrationContaining(create(ChildApp, M))
        dependsOn migrationContaining(remove(BaseApp, BModel, F))
```

Source code evidence: `_build_migration_list()` marks external dependencies as
unsatisfied while a matching operation remains in the other app at
`repo/django/db/migrations/autodetector.py:284-292`, then records a dependency
on the other app's last generated migration after it exists at
`repo/django/db/migrations/autodetector.py:293-298`.

Discharges: F-004.

## PO-005: RemoveField generation remains unique

Claim:

```text
requires removedField(BApp, BModelLower, F)
ensures count(generated(remove(BApp, BModelLower, F))) == 1
     and adding subclass dependencies does not create remove operations
```

Source code evidence: V1 edits only the dependency list for `CreateModel`.
`generate_removed_fields()` remains the sole generator for removed fields and
iterates the set difference `self.old_field_keys - self.new_field_keys` at
`repo/django/db/migrations/autodetector.py:894-897`.

Discharges: F-002.

## PO-006: Deferred related AddField remains after CreateModel

Claim:

```text
requires localField(M, F)
     and relatedField(M, F)
     and autoDep(create(MApp, M), depRemove(BApp, BModel, F))
     and autoDep(addField(MApp, M, F), depCreate(MApp, M))
ensures before(remove(BApp, BModel, F), create(MApp, M))
     and before(create(MApp, M), addField(MApp, M, F))
```

Source code evidence: V1 checks `model_state.fields`, so relation fields split
out of the `CreateModel.fields` list are still considered at
`repo/django/db/migrations/autodetector.py:568-574`. Existing related-field
generation appends `(app_label, model_name, None, True)` before adding the
`AddField` operation at `repo/django/db/migrations/autodetector.py:601-612`.

Discharges: F-003.

## PO-007: Frame condition for unrelated fields and compatibility

Claim:

```text
requires not (localField(M, F) and removedField(BApp, BModelLower, F))
ensures no depRemove(BApp, BModel, F) is required for create(M)
     and public signatures, operation classes, and questioner behavior are unchanged
```

Source code evidence: V1 adds a dependency only for
`removed_base_fields & model_state.fields.keys()` at
`repo/django/db/migrations/autodetector.py:573-574`; it changes no method
signature and no operation class.

Discharges: F-005.

## PO-008: Migration optimizer does not undo the required order

Claim:

```text
requires before(remove(App, BModel, F), create(App, M))
     and B is a base of M
ensures optimizer does not reduce remove(B, F) across create(M)
```

Source code evidence: `Operation.references_field()` delegates to
`references_model()` at `repo/django/db/migrations/operations/base.py:94-101`.
`CreateModel.references_model()` returns true when the model inherits from the
referenced base at `repo/django/db/migrations/operations/models.py:102-112`.
Therefore `RemoveField.reduce(CreateModel)` cannot optimize across this
operation pair.

Discharges: F-001.

## PO-009: Honesty gate

Claim:

```text
ensures proof status == constructed_not_machine_checked
     and no test removal is recommended
```

Source evidence: benchmark instructions prohibit running tests, Python, or K
tooling.

Discharges: F-006.
