# Constructed Proof

Constructed, not machine-checked. The K commands below were written as
artifacts only and were not executed.

## Machine-Check Commands

```sh
cd fvk
kompile mini-backend.k --backend haskell
kast --backend haskell backend-rcparams-spec.k
kprove backend-rcparams-spec.k
```

Expected machine-checked success, if the fragment and claims parse and the
constructed proof discharges, is `#Top`.

## Proof Shape

The model has no loops or recursion, so no circularity claim is needed. The
proof is finite symbolic execution plus case analysis on the backend state:

1. `rcBackend` is a concrete backend.
2. `rcBackend` is `auto` and `backendLoaded` is true.
3. `rcBackend` is `auto` and `backendLoaded` is false.

## Claim 1: Loaded Backend, Stale Sentinel

Initial symbolic state:

- `globalRc = true`
- `rcBackend = auto`
- `pyplotImported = true`
- `backendLoaded = true`
- `selectedBackend = B`
- `gcfFigs = FS`
- `B =/= auto`

The second `getBackend` rule in `mini-backend.k` matches exactly this state.
One rewrite step changes:

- `<k> getBackend </k>` to `<k> B </k>`
- `<rcBackend> auto </rcBackend>` to `<rcBackend> B </rcBackend>`

No rule in this path rewrites `<gcfFigs>`, so framing preserves
`<gcfFigs> FS </gcfFigs>`. By consequence, the postcondition of PO-1 holds.

This is the key discriminator versus V0: the V0 path would have called
`switchBackend(auto)`, whose rule rewrites `<gcfFigs> _ </gcfFigs>` to
`<gcfFigs> .Figs </gcfFigs>`.

## Claim 2: Initial Lazy Resolution

Initial symbolic state:

- `globalRc = true`
- `rcBackend = auto`
- `backendLoaded = false`
- `autoChoice = B`
- `gcfFigs = .Figs`
- `B =/= auto`

The third `getBackend` rule matches and rewrites `getBackend` to
`switchBackend(auto)`. The auto-selection rule rewrites that to
`switchBackend(B)`. The concrete switch rule then records `B`, marks the
backend loaded, and rewrites `gcfFigs` to `.Figs`.

Because the precondition already has `.Figs`, the postcondition preserves the
empty collection. This proves PO-2 while keeping real switch cleanup modeled as
destructive.

## Claim 3: Concrete Backend Read

Initial symbolic state:

- `rcBackend = B`
- `gcfFigs = FS`
- `B =/= auto`

The first `getBackend` rule matches and rewrites only `<k> getBackend </k>` to
`<k> B </k>`. The figure-manager collection is framed unchanged. PO-3 holds.

## Compatibility Proof Notes

- PO-4 holds because the modeled repair path requires `globalRc = true`, matching
  the source guard `self is globals().get("rcParams")`.
- PO-5 holds because the destructive `switchBackend` rule is unchanged and is
  still used for actual backend switching or initial lazy resolution.
- PO-6 holds by source inspection: V1 changes no public signature and edits only
  the global backend accessor branch.

## Test Guidance

No tests were run and no test files were edited. If this proof is later
machine-checked, tests that only assert PO-1 for one backend become redundant in
principle, but removal should remain conditional on `kprove` returning `#Top`.
Integration tests around real GUI backends, backend import failures, and actual
`switch_backend()` cleanup should be kept.
