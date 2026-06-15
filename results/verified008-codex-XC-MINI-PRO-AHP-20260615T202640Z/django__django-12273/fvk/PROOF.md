# Constructed Proof

Status: constructed, not machine-checked. No K tooling, tests, Python, or
Django code was executed.

## Claims

The formal claims are in `fvk/model-pk-spec.k`.

- `SET-PK-CHAIN`: running `setPk(F, V)` from an acyclic parent-link PK chain
  updates the attribute map to `setChain(A, NEXT, F, V)`.
- `SAVE-CONSEQUENCE`: when `V` is `None`, every field in the active PK chain is
  mapped to `None`, which is the state needed for Django's parent save path to
  avoid updating old rows through stale PKs.

## Proof sketch for PO1 and PO2

Use guarded circularity on the recursive operational rule for `setPk`.

Base case:

1. `setPk(F, V)` writes `V` to `F`.
2. `<next>` maps `F` to `noParent`.
3. `continue(noParent, V)` rewrites to `.K`.
4. The final attribute map is `A[F <- V]`, which equals
   `setChain(A, NEXT, F, V)` by the simplification rule for `noParent`.

Inductive/circular case:

1. `setPk(F, V)` writes `V` to `F`.
2. `<next>` maps `F` to `parent(G)`.
3. `continue(parent(G), V)` rewrites to `setPk(G, V)`, a genuine progress step.
4. Invoke the same claim on `G` under the acyclicity side condition.
5. The resulting attribute map is
   `setChain(A[F <- V], NEXT, G, V)`, equal to
   `setChain(A, NEXT, F, V)` by the parent simplification rule.

The circular use is guarded because the first assignment and continuation step
occur before the recursive claim is reused.

## Proof sketch for PO3

The only map update rule in `mini-django-pk.k` is `A [F <- V]`, where `F` is
the current chain field. The only successor comes from `<next> F |-> parent(G)`.
Therefore no field outside the successor closure rooted at `self._meta.pk` is
assigned.

## Proof sketch for PO4

Static source reasoning links the abstract proof to Django:

1. `_save_parents()` recursively saves concrete parents before the child.
2. `_save_table()` computes `pk_val = self._get_pk_val(meta)`.
3. It attempts an update only if `pk_val is not None` and `force_insert` is
   false.
4. PO1 establishes that the class-specific PK values in the active parent-link
   chain are `None` after `pk = None`.
5. Therefore ordinary save reaches the insert path for those parent tables
   instead of updating the old row through a stale PK.

## Machine-check commands

These commands are emitted for later checking only. They were not run.

```sh
kompile fvk/mini-django-pk.k --backend haskell
kast --backend haskell fvk/model-pk-spec.k
kprove fvk/model-pk-spec.k
```

Expected machine result: `#Top` for the claims. Until then, this proof remains
constructed, not machine-checked.

## Test recommendations

Do not remove tests based on this constructed proof. After machine checking,
unit tests that assert the same in-domain points would be candidates for
redundancy, but Django should still keep integration tests around actual
database save behavior.

Recommended tests to add or keep:

- one-level MTI copy with `obj.pk = None` preserves the original parent row;
- multi-level MTI copy with `obj.pk = None` inserts every parent table in the
  active PK chain;
- a child model with an explicit own primary key and a non-primary parent link
  does not have that parent link cleared by assigning `pk = None`.
