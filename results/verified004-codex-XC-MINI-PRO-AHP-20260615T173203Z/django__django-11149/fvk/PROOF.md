# PROOF

Status: constructed, not machine-checked. No tests, Python, `kompile`, or `kprove` were run.

## Claims Proved

The proof targets the reduced permission semantics in `fvk/mini-admin-permissions.k` and the claims in `fvk/admin-inline-permissions-spec.k`.

The audited production path has no loops, so there are no circularities. The proof is symbolic rewriting of pure permission expressions plus a preservation abstraction for the inline formset save effect.

## Symbolic Proof Sketch

### VIEW-OR-CHANGE-CAN-VIEW

Initial term:

```k
autoM2MView(TARGET_VIEW, TARGET_CHANGE)
```

By the `autoM2MView` rule, the term rewrites in one semantic step to:

```k
TARGET_VIEW orBool TARGET_CHANGE
```

This is exactly the claim postcondition.

### WRITE-FOLLOWS-TARGET-CHANGE

Initial term:

```k
autoM2MWrite(TARGET_CHANGE)
```

By the `autoM2MWrite` rule, the term rewrites in one semantic step to:

```k
TARGET_CHANGE
```

This proves that target view is not a contributor to write permission.

### VIEW-ONLY-WRITE-FALSE

Instantiate `WRITE-FOLLOWS-TARGET-CHANGE` with `TARGET_CHANGE = false`.

```k
autoM2MWrite(false) => false
```

This is the direct formal version of the reported view-only user case.

### VIEW-ONLY-POST-PRESERVES

Initial term:

```k
applyInlinePost(autoM2MWrite(false), ORIGINAL, SUBMITTED)
```

Strict evaluation of the first argument rewrites:

```k
autoM2MWrite(false) => false
```

The term becomes:

```k
applyInlinePost(false, ORIGINAL, SUBMITTED)
```

By the `applyInlinePost(false, ...)` rule, it rewrites to:

```k
ORIGINAL
```

Thus a submitted add/remove/change request cannot affect the relationship state without target `change` permission.

### TARGET-CHANGE-POST-APPLIES

Initial term:

```k
applyInlinePost(autoM2MWrite(true), ORIGINAL, SUBMITTED)
```

Strict evaluation rewrites `autoM2MWrite(true)` to `true`, then `applyInlinePost(true, ORIGINAL, SUBMITTED)` rewrites to `SUBMITTED`.

This preserves the existing positive behavior for users with target model `change` permission.

## Connection To Source

The K model abstracts the following source facts:

- `has_view_permission()` for `self.opts.auto_created` checks target `view` or `change`.
- `has_add_permission()`, `has_change_permission()`, and `has_delete_permission()` for `self.opts.auto_created` check target `change`.
- Inline rendering and save logic use those hook results as their add/change/delete gates.

The abstraction preserves the property under test because it distinguishes:

- failing case: `target_view = true`, `target_change = false`, `submittedRel != originalRel`, result should be `originalRel`;
- allowed case: `target_change = true`, result may be `submittedRel`.

## Machine Check Commands

These commands are emitted for a later environment with K installed. They were not run.

```sh
kompile fvk/mini-admin-permissions.k --backend haskell
kast --backend haskell fvk/admin-inline-permissions-spec.k
kprove fvk/admin-inline-permissions-spec.k
```

Expected machine-check result: `#Top` for all claims.

## Test Recommendation

Do not delete tests unless the K claims are machine-checked.

Conditionally redundant after machine-checking:

- A focused unit test asserting that target-view-only auto-created m2m inline write hooks are false.
- A focused unit test asserting that target-change auto-created m2m inline write hooks are true.

Keep:

- Integration tests that exercise real admin rendering, formset construction, transactions, and HTTP POST behavior.
- Permission matrix tests for ordinary FK inlines and explicit through models.
- Any regression test for this ticket until the constructed proof is actually machine-checked and maintainers choose to rely on it.

## Residual Risk

- Constructed, not machine-checked.
- Partial correctness only. Termination and performance are not proved.
- The mini semantics verifies the permission/save-effect axis, not the full Django runtime.
