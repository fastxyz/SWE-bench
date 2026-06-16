# Formal Spec In English

Constructed, not machine-checked.

## Claim 1: Loaded Backend, Stale Sentinel

For every concrete backend `B` and every figure-manager collection `FS`, if:

- this is the global rcParams object,
- `rcParams["backend"]` currently stores the auto sentinel,
- pyplot is imported,
- pyplot already has a loaded backend,
- the selected backend is `B`, and
- `Gcf.figs` is `FS`,

then evaluating `getBackend` returns `B`, updates `rcParams["backend"]` to `B`,
and leaves `Gcf.figs` exactly `FS`.

## Claim 2: Initial Lazy Resolution

For every concrete backend `B`, if:

- this is the global rcParams object,
- `rcParams["backend"]` stores the auto sentinel,
- pyplot has not loaded a backend,
- auto backend selection chooses `B`, and
- `Gcf.figs` is empty,

then evaluating `getBackend` resolves the backend to `B`, records the backend as
loaded and selected, and leaves `Gcf.figs` empty.

## Claim 3: Concrete Backend Read

For every concrete backend `B` and every figure-manager collection `FS`, if
`rcParams["backend"]` already stores `B`, then evaluating `getBackend` returns
`B` and leaves `Gcf.figs` exactly `FS`.
