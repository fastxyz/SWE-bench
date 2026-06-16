# Constructed Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`, Python, or test command was run.

## Claims Proved in the Model

The proof targets the two claims in `changelist-list-editable-spec.k`:

- `LIST_EDITABLE_FAILURE_ROLLBACK`: failure during any changed-form write bundle rolls back the whole batch.
- `LIST_EDITABLE_SUCCESS_COMMIT`: success commits exactly one write bundle per changed form.

The semantics in `mini-admin-transaction.k` has these relevant cells:

- `<db>`: committed database write count for the selected connection.
- `<pending>`: writes accumulated inside the current atomic block.
- `<inAtomic>`: whether execution is inside `transaction.atomic()`.
- `<failed>`: whether an exception/failure escaped the write bundle.

## Failure Rollback Proof Sketch

Assume `N >= 0` and `0 <= F < N`.

1. `processListEditable(N, F)` rewrites to `atomic { #loop(0, N, F) }`.
2. Entering `atomic` sets `<inAtomic>` to `true`, clears `<pending>`, and runs the loop body before `#commit`.
3. For each `I < F`, `#loop(I, N, F)` runs `#saveBundle(I, F)`, which increments `<pending>` and returns normally, then continues with `#loop(I + 1, N, F)`.
4. At `I == F`, `#saveBundle(F, F)` increments `<pending>` and rewrites to `#fail`.
5. Because `<inAtomic>` is `true`, `#fail` discards the remaining continuation and rewrites to `#rollback`.
6. `#rollback` clears `<pending>`, sets `<inAtomic>` to `false`, leaves `<db>` unchanged, and records `<failed> true`.

By induction over the number of successful bundles before `F`, pending writes may accumulate but no committed writes are produced before rollback. The final committed state is therefore the initial `D`, satisfying `LIST_EDITABLE_FAILURE_ROLLBACK`.

## Success Commit Proof Sketch

Assume `N >= 0` and `F < 0 or F >= N`.

1. `processListEditable(N, F)` enters one atomic block and starts `#loop(0, N, F)`.
2. For each `I` with `0 <= I < N`, `I =/= F`, so `#saveBundle(I, F)` increments `<pending>` and returns normally.
3. When `I >= N`, `#loop(I, N, F)` rewrites to `.K`.
4. Control reaches `#commit`, which adds all pending writes to `<db>`, clears `<pending>`, and exits the atomic block.
5. Exactly `N` successful bundle steps occurred, so `<db>` changes from `D` to `D + N`.

This satisfies `LIST_EDITABLE_SUCCESS_COMMIT`.

## Source Mapping

The modeled `processListEditable()` corresponds to the V1 block at `repo/django/contrib/admin/options.py:2012-2024`.

The modeled write bundle corresponds to the source sequence:

```python
obj = self.save_form(request, form, change=True)
self.save_model(request, obj, form, change=True)
self.save_related(request, form, formsets=[], change=True)
change_msg = self.construct_change_message(request, form, None)
self.log_change(request, obj, change_msg)
```

The source transaction boundary corresponds to:

```python
with transaction.atomic(using=router.db_for_write(self.model)):
```

## Adequacy

`SPEC_AUDIT.md` marks the formal English claims as matching the public intent. `PUBLIC_COMPATIBILITY_AUDIT.md` finds no unhandled public API, callsite, override, or branch compatibility issue.

## Residual Risk

This is partial correctness over a small transaction model, not a machine-checked proof against full Python/Django semantics. The trusted base is:

- the adequacy of the mini transaction model for committed-versus-pending writes;
- Django's documented/standard transaction behavior for `transaction.atomic()`;
- K reachability proof metatheory and the eventual `kprove` run.

External side effects inside user overrides are not claimed to roll back.

## Reproduce the Machine Check Later

These commands are recorded only; they were not executed:

```sh
cd fvk
kompile mini-admin-transaction.k --backend haskell
kast --backend haskell changelist-list-editable-spec.k
kprove changelist-list-editable-spec.k
```

Expected machine-check result after any syntax adjustments required by the local K installation: `#Top` for both claims.

## Test Guidance

No tests are removed. Existing public tests around successful list-editable saves, action/list-editable branch selection, and edited queryset filtering should be kept. A focused regression test would mock or trigger an exception inside a changed-form save/log bundle and assert that earlier changed objects are rolled back, plus a multidatabase check that `transaction.atomic()` receives the router-selected alias.
