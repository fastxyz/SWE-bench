# FVK Specification: django__django-12754

Status: constructed from public issue text and source inspection; not
machine-checked; no tests or project code were run.

## Scope

The audited unit is the migration autodetector behavior for newly created
models in `repo/django/db/migrations/autodetector.py`, especially
`MigrationAutodetector.generate_created_models()`, `_sort_migrations()`,
`_build_migration_list()`, and `check_dependency()`.

This spec covers the issue domain:

- a concrete model base `B` exists in the old state;
- field `F` exists locally on `B` in the old state and is absent from `B` in
  the new state;
- a new concrete model `M` is created in the new state with `B` as a direct
  concrete string base;
- `M` declares a local field named `F`;
- autodetection emits the operations in a single change set.

The proof is partial correctness over operation ordering and dependency
generation. It does not prove termination, full Django runtime behavior, or
schema-editor database effects.

## Public Intent Ledger

I-001. Source: `benchmark/PROBLEM.md`.
Quoted evidence: "The migration generates with CreateModel for Book, then
RemoveField for Readable.title. But running it produces the error. Reversing
the order of the migration operations makes it pass. The auto-detector should
be able to use this order."
Semantic obligation: When a new subclass declares a field removed from its
base in the same change, the generated migration order must place
`RemoveField(base.field)` before `CreateModel(subclass)`.
Status: encoded as S-001 and PO-001 through PO-004.

I-002. Source: `benchmark/PROBLEM.md` public hint.
Quoted evidence: "generate_created_models might need to be adjusted to add a
dependency on field removal of all of its base to make sure the order is
swapped" and "the correct dependency representation is
`(base_app_label, base_model_name, field_name, False)`".
Semantic obligation: The ordering mechanism should use the existing
autodetector dependency tuple for removed fields.
Status: encoded as S-002 and PO-001 through PO-002.

I-003. Source: `benchmark/PROBLEM.md` public hint.
Quoted evidence: "when a field is removed from a base while two subclasses are
added in the same run with this field ... a single RemoveField must be
generated and not multiple ones."
Semantic obligation: The fix may add dependencies to multiple created
subclasses, but it must not duplicate the base `RemoveField`.
Status: encoded as S-003 and PO-005.

I-004. Source: `repo/django/db/migrations/autodetector.py`.
Implementation evidence: `_sort_migrations()` adds an edge from an operation
to another operation when `check_dependency(op2, dep)` is true; `check_dependency()`
already recognizes removed-field dependencies where the last tuple element is
`False`.
Semantic obligation: A fix can be local to dependency generation if it emits a
dependency tuple that existing dependency resolution already understands.
Status: encoded as S-002, PO-002, and PO-003.

I-005. Source: `benchmark/PROBLEM.md` discussion.
Quoted evidence: commenters discuss possible warning or prompt behavior, but
the accepted direction says it should be doable to teach the autodetector to
generate operations in the right order.
Semantic obligation: No prompt, warning, public API, or migration operation
class change is required by the public issue.
Status: encoded as S-005 and compatibility audit.

## Intent-Only Requirements

S-001. For every in-scope tuple `(B, F, M)`, the generated operation order must
apply `RemoveField(B, F)` before `CreateModel(M)`.

S-002. The dependency used to force S-001 must be the removed-field dependency
shape `(base_app_label, base_model_name, field_name, False)`, because existing
`check_dependency()` recognizes it.

S-003. If two or more new subclasses declare the same field `F` moved from the
same base `B`, the operation set must contain one `RemoveField(B, F)` and each
subclass creation must depend on it.

S-004. If the moved field is a related field that is deferred into an
`AddField`, `RemoveField(B, F)` must still happen before the deferred field is
added to the subclass.

S-005. Existing public APIs and operation classes must remain compatible: no
signature changes, no new required prompts, and no test-file edits.

## Abstract Formal Model

The formal model abstracts Django states to sets and relations:

- `OldFields` is a set of triples `(app, model_lower, field)`.
- `NewFields` is a set of triples `(app, model_lower, field)`.
- `RemovedFields = OldFields - NewFields`.
- `Bases(M)` is the set of direct string bases of new model `M`.
- `LocalFields(M)` is the set of local field names declared by `M`.
- `Create(M)` is the `CreateModel` operation for a new model.
- `Remove(B, F)` is the `RemoveField` operation for a removed base field.
- `Deps(Create(M))` is the `_auto_deps` list attached to the create operation.
- `matches(Remove(B, F), dep(B, F, removed))` is Django's
  `check_dependency()` removed-field branch.
- `Topo(Ops, Edges)` is the stable topological sort over operation dependency
  edges.

The core formal claim is:

```text
for all B, F, M:
  if B in Bases(M)
  and F in LocalFields(M)
  and (B.app, B.model_lower, F) in RemovedFields
  and Remove(B, F) is generated,
  then dep(B.app, B.model, F, False) in Deps(Create(M))
  and every valid Topo order places Remove(B, F) before Create(M).
```

For cross-app bases, the same dependency is an inter-app migration dependency:
the migration containing `Create(M)` must depend on the migration containing
`Remove(B, F)`.

## Adequacy Audit

A-001. S-001 is directly entailed by I-001. Pass.

A-002. S-002 is directly entailed by I-002 and by the existing
`check_dependency()` implementation. Pass.

A-003. S-003 is directly entailed by I-003. Pass.

A-004. S-004 is not explicitly named in the issue, but it follows from the
same "field moved to subclass" obligation and from Django's existing split of
some related fields into `AddField` operations. The V1 proof covers it because
the deferred `AddField` already depends on `CreateModel(M)`. Pass.

A-005. S-005 is entailed by absence of a public requirement to change APIs and
by the user instruction not to modify tests. Pass.

## Public Compatibility Audit

Changed public symbol: none.

Changed method signature: none.

Changed operation class or migration serialization shape: none.

Changed prompt/questioner behavior: none.

Compatibility status: pass. The V1 patch only adds `_auto_deps` entries to
generated `CreateModel` operations; it does not alter public APIs or operation
serialization.
