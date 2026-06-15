# Proof

Status: constructed, not machine-checked.

## Claims proved in the constructed model

Claim: `ORDERED-UNION-DERIVED-VALUES-FRAME` in
`fvk/query-clone-spec.k`.

Plain English: deriving a `values_list('pk')`-style query from an ordered union
creates separate child query objects for the derived query. Narrowing the
derived select list does not narrow the original union's child select lists, so
the original union remains orderable by position `4`.

## Symbolic execution sketch

Initial configuration:

```text
<k> deriveValuesPk(orig, derived, d1, d2); assertOrderable(orig) </k>
<queries>
  orig |-> query(4, 4, kids(c1, c2))
  c1   |-> query(4, 0, noKids)
  c2   |-> query(4, 0, noKids)
</queries>
<status> ok </status>
```

Step 1: sequencing exposes `deriveValuesPk`.

Step 2: the `deriveValuesPk` rule copies the source query and creates cloned
children `d1` and `d2`, then narrows only `derived`, `d1`, and `d2` to width
`1`. The original bindings for `orig`, `c1`, and `c2` are framed unchanged.

Intermediate configuration:

```text
<k> assertOrderable(orig) </k>
<queries>
  orig    |-> query(4, 4, kids(c1, c2))
  c1      |-> query(4, 0, noKids)
  c2      |-> query(4, 0, noKids)
  derived |-> query(1, 0, kids(d1, d2))
  d1      |-> query(1, 0, noKids)
  d2      |-> query(1, 0, noKids)
</queries>
<status> ok </status>
```

Step 3: `assertOrderable(orig)` checks `4 <= 4 and 4 <= 4`, which is true.
The successful assertion rule fires and the status remains `ok`.

Final configuration matches the claim's right-hand side.

## Why the pre-V1 shallow clone fails the discriminator

With a shallow clone, the derived query would reuse `c1` and `c2` rather than
new children `d1` and `d2`. The derived values-list narrowing step would change
the width of `c1` and `c2` to `1`. `assertOrderable(orig)` would then require
`4 <= 1`, which is false, and the model would enter `error`. This derives the
reported symptom from the modeled mechanism instead of merely restating it.

## Adequacy and completeness check

The proof covers the full public behavior space named by the issue:

- ordered combined querysets;
- derived `order_by().values_list()` querysets;
- preservation of the original combined queryset's component select lists;
- the observable failure mode where an order position is missing from the
  select list.

The model intentionally does not prove unrelated SQL generation, database
execution, or queryset evaluation semantics. Those are outside the public issue
unless they affect the aliasing/select-width observable, which this model keeps.

## Test redundancy recommendation

No tests were modified. If machine-checking later returns `#Top`, an in-domain
unit regression test that only checks the specific two-branch aliasing frame
property would be subsumed by the proof. Integration tests covering real
database SQL generation should be kept because this proof uses a reduced model.

## Commands to machine-check later

Do not run these in this task. They are emitted for a future environment with K
installed:

```sh
kompile fvk/mini-query-clone.k --backend haskell
kast --backend haskell fvk/query-clone-spec.k
kprove fvk/query-clone-spec.k
```

Expected result after successful machine checking: `#Top`.

## Residual risk

This is a partial-correctness proof over a mini model. Termination is immediate
in the model and no Django/Python runtime semantics were executed. The trusted
base is the adequacy of the aliasing abstraction, K reachability logic, and the
future `kprove` run.
