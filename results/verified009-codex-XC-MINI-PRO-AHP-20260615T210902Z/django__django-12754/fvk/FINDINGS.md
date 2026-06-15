# FVK Findings

Status: constructed from source inspection only. No tests, Python code, or K
tooling were run.

## F-001: Legacy operation order creates the reported `FieldError`

Input:

```python
class Readable(models.Model):
    title = models.CharField(max_length=200)

# changed to:
class Readable(models.Model):
    pass

class Book(Readable):
    title = models.CharField(max_length=200)
```

Observed before V1: autodetection could emit `CreateModel(Book)` before
`RemoveField(Readable.title)`. Applying that state asks Django to render
`Book` while `Readable.title` still exists, causing the reported field clash.

Expected from intent I-001: `RemoveField(Readable.title)` before
`CreateModel(Book)`.

Classification: code bug in operation dependency generation.

Status: closed by V1. The patch adds the removed-field dependency in
`generate_created_models()`; PO-001 through PO-003 prove that same-app sorting
places `RemoveField` before `CreateModel`.

## F-002: Multiple subclasses must not duplicate `RemoveField`

Input:

```python
class Readable(models.Model):
    title = models.CharField(max_length=200)

# changed to:
class Readable(models.Model):
    pass

class Book(Readable):
    title = models.CharField(max_length=200)

class Magazine(Readable):
    title = models.CharField(max_length=200)
```

Observed risk from public hint I-003: a naive fix could create one
`RemoveField(Readable.title)` per subclass.

Expected: one `RemoveField(Readable.title)`, with both subclass `CreateModel`
operations depending on it.

Classification: duplicate-operation risk.

Status: closed by V1. The patch only adds dependencies to `CreateModel`
operations and leaves `generate_removed_fields()` as the sole producer of
`RemoveField` operations. See PO-005.

## F-003: Related fields split into `AddField` must still be ordered

Input: a field named `F` is removed from base `B` and reintroduced on new
subclass `M`, but Django defers `M.F` into an `AddField` because it is a
relation.

Observed risk: if only the concrete `CreateModel` field list were considered,
the dependency might miss relation fields that are split out of the create
operation.

Expected: `RemoveField(B.F)` before `CreateModel(M)` before `AddField(M.F)`.

Classification: branch coverage risk in the generator.

Status: closed by V1. The patch intersects removed base fields with
`model_state.fields`, not with the filtered `CreateModel.fields`, and the
existing related-field path makes `AddField(M.F)` depend on `CreateModel(M)`.
See PO-006.

## F-004: Cross-app base/subclass ordering must become a migration dependency

Input: base model `B` lives in app `baseapp`, new subclass `M` lives in app
`childapp`, and `M` declares a field removed from `B`.

Observed risk: same-app topological sorting cannot order operations across
apps.

Expected: the migration containing `CreateModel(M)` depends on the migration
containing `RemoveField(B.F)`.

Classification: cross-app ordering risk.

Status: closed by V1 and existing `_build_migration_list()` behavior. The V1
dependency tuple is visible to external dependency resolution; PO-004 proves
the create migration is blocked until the remove migration exists.

## F-005: Warning or prompt behavior is not required for this fix

Input: the issue discussion mentions possible warnings about data loss.

Observed risk: broadening the patch into prompt/questioner behavior would add
unrequested UX and compatibility surface.

Expected: generate an applyable order; leave warning/prompt behavior unchanged.

Classification: underspecified intent / avoid unrelated change.

Status: closed as no code change. S-005 and PO-007 justify keeping V1 scoped to
dependency generation.

## F-006: Formal proof and tests are not machine-run

Input: this benchmark workspace has no execution environment.

Observed: FVK and Django test commands were not run.

Expected: artifacts state the proof is constructed, not machine-checked, and
test removal is not recommended.

Classification: residual verification risk, not a code bug.

Status: open caveat. See PO-009 and `fvk/PROOF.md`.

## Summary

No open code bug was found in V1 for the public issue domain. The only open
finding is the mandated honesty caveat that neither tests nor K tooling were
executed.
