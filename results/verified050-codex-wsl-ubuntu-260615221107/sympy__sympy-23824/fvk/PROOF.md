# PROOF.md

Status: constructed, not machine-checked.

No tests, Python, `kompile`, `kast`, or `kprove` were run. The commands below
are emitted for later reproduction only.

## Claims Proved

The proof targets the restoration slice of `kahane_simplify()`:

```text
restore(P, R) = [P ++ ri for ri in R]
```

where `P` is the skipped leading free gamma prefix and `R` is the list of core
result branches produced after Kahane graph traversal.

K claims:

- `RESTORE-ONE`: restoring one branch with V1's descending prepend loop produces
  `P ++ ri`.
- `RESTORE-GENERAL`: restoring all branches maps `P ++` over every branch.
- `RESTORE-WITNESS`: the issue witness `[rho, sigma]` over one empty branch
  produces `[rho, sigma]`.
- `LEGACY-WITNESS`: the old forward-prepend loop produces `[sigma, rho]` for
  the same witness.

## Proof Sketch

### One Branch

Let `P` have length `k`, and let `ri_old` be an arbitrary core branch.

V1 loops over positions:

```text
k - 1, k - 2, ..., 0
```

and performs:

```text
ri.insert(0, P[i])
```

Loop invariant:

```text
after processing positions i+1 through k-1:
    ri = P[i+1:k] ++ ri_old
```

Step:

```text
insert(0, P[i]) changes P[i+1:k] ++ ri_old
to P[i:k] ++ ri_old
```

Base:

Before processing any positions, `ri = ri_old`, which is
`P[k:k] ++ ri_old`.

Exit:

After processing `i = 0`, `ri = P[0:k] ++ ri_old`, so the leading prefix is
restored in original order.

### All Branches

The source applies the same insertion operation to every `ri` in
`resulting_indices`. By induction on the branch list:

- Empty branch list stays empty.
- For `ri :: rest`, RESTORE-ONE gives `P ++ ri`, and the induction hypothesis
  gives `map(P ++, rest)`.

Therefore:

```text
restore(P, [r0, ..., rn]) = [P ++ r0, ..., P ++ rn]
```

### Public Witness

For the issue witness:

```text
P = [rho, sigma]
R = [[]]
C = 4
```

RESTORE-GENERAL yields:

```text
[rho, sigma] ++ [] = [rho, sigma]
```

With the framed coefficient `C = 4`, the observable result is:

```text
4 * GammaMatrix(rho) * GammaMatrix(sigma)
```

### Legacy Counterexample

The legacy loop processed positions `0, 1, ..., k - 1` while also prepending.
For `P = [rho, sigma]`:

```text
[] -> [rho] -> [sigma, rho]
```

That matches the public bug report and falsifies the old loop against PO-1.

## Machine-Check Commands

These commands are provided for a later environment with K installed. They were
not executed in this session.

```sh
kompile fvk/mini-kahane-prefix.k --backend haskell
kast --backend haskell fvk/kahane-prefix-spec.k
kprove fvk/kahane-prefix-spec.k
```

Expected result after machine-checking: `#Top` for the stated mini-model claims.

## Test Recommendation

No tests were added, modified, removed, or run. The public issue examples are
subsumed by RESTORE-WITNESS only after the K proof is machine-checked and normal
integration tests still cover SymPy tensor construction. Until then, keep tests.
