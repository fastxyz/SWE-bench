# FVK Spec

Constructed, not machine-checked.

## Scope

This FVK pass audits the V1 fix for
`matplotlib__matplotlib-23299`: global backend lookup after `rc_context()`
restores the auto-backend sentinel while pyplot has already selected a backend.

The formal unit is the observable behavior of:

- `matplotlib.get_backend()`, which returns `rcParams["backend"]`;
- global `RcParams.__getitem__("backend")`;
- the relevant destructive behavior of `pyplot.switch_backend()`;
- the preservation or clearing of `Gcf.figs`.

The source under audit is [repo/lib/matplotlib/__init__.py](/home/yuqing/.swe-fvk-runs/verified027-codex-archlinux-20260616T084044Z/matplotlib__matplotlib-23299/repo/lib/matplotlib/__init__.py:673).

## Public Intent Ledger

| ID | Source | Evidence | Obligation |
| --- | --- | --- | --- |
| E1 | Problem | "get_backend() clears figures from Gcf.figs if they were created under rc_context" | `get_backend()` must not remove existing `Gcf` managers in the reported stale-sentinel state. |
| E2 | Problem | "The figure should not be missing from Gcf." | `Gcf.figs` is framed across the reported `get_backend()` call. |
| E3 | Problem | "`plt.close(fig2)` doesn't work because `Gcf.destroy_fig()` can't find it" | The actual manager collection must be preserved, not just the `Figure` object. |
| E4 | Public hint | "`rcParams['backend']` in the auto-sentinel ... stashed by rc_context ... get_backend() re-resolves" | The bug mechanism is stale-sentinel re-resolution after backend selection. |
| E5 | Source | `get_backend()` returns `rcParams['backend']`. | The backend accessor is the right source location to audit. |
| E6 | Source | `pyplot.switch_backend()` calls `close("all")`. | Real backend switches remain destructive; the fix must avoid unnecessary switching. |
| E7 | Source | `switch_backend()` records the selected backend in pyplot/global backend state. | When `_backend_mod` is loaded, the selected backend is authoritative. |
| E8 | Source/public tests | Sentinel resolution is guarded to the global `rcParams` object. | Standalone `RcParams` must not gain global lazy-resolution behavior. |

The standalone ledger is also recorded in
[PUBLIC_EVIDENCE_LEDGER.md](/home/yuqing/.swe-fvk-runs/verified027-codex-archlinux-20260616T084044Z/matplotlib__matplotlib-23299/fvk/PUBLIC_EVIDENCE_LEDGER.md).

## Formal Model

The model is a deliberately small state machine:

- `Backend`: either `auto` or a concrete `backend("name")`.
- `rcBackend`: the value stored in global `rcParams["backend"]`.
- `pyplotImported` and `backendLoaded`: whether pyplot exists and has selected
  a concrete backend.
- `selectedBackend`: the already-loaded backend.
- `gcfFigs`: an abstraction of `Gcf.figs`; equality means the same managers are
  still registered.

`switchBackend(B)` is modeled as destructive: it sets `gcfFigs` to `.Figs`.
This preserves the public `pyplot.switch_backend()` behavior and focuses the fix
on avoiding a redundant switch in the stale-sentinel loaded-backend case.

Formal files:

- [mini-backend.k](/home/yuqing/.swe-fvk-runs/verified027-codex-archlinux-20260616T084044Z/matplotlib__matplotlib-23299/fvk/mini-backend.k)
- [backend-rcparams-spec.k](/home/yuqing/.swe-fvk-runs/verified027-codex-archlinux-20260616T084044Z/matplotlib__matplotlib-23299/fvk/backend-rcparams-spec.k)

## Claims

1. **Loaded backend, stale sentinel**: if global `rcParams["backend"]` is
   `auto`, pyplot is imported, a backend is loaded, and `Gcf.figs` is `FS`,
   then `getBackend` returns the selected backend, updates `rcBackend` to that
   backend, and leaves `FS` unchanged.

2. **Initial lazy resolution**: if global `rcParams["backend"]` is `auto` and no
   backend is loaded, `getBackend` may resolve through `switchBackend(auto)`.
   The claim requires `Gcf.figs` to be empty, matching the state before any
   pyplot figure manager can exist.

3. **Concrete backend read**: if `rcBackend` already stores a concrete backend,
   `getBackend` returns it and frames `Gcf.figs`.

## Adequacy

The formal English paraphrase is in
[FORMAL_SPEC_ENGLISH.md](/home/yuqing/.swe-fvk-runs/verified027-codex-archlinux-20260616T084044Z/matplotlib__matplotlib-23299/fvk/FORMAL_SPEC_ENGLISH.md), and the round-trip audit is in
[SPEC_AUDIT.md](/home/yuqing/.swe-fvk-runs/verified027-codex-archlinux-20260616T084044Z/matplotlib__matplotlib-23299/fvk/SPEC_AUDIT.md). All three claims pass the audit against
[INTENT_SPEC.md](/home/yuqing/.swe-fvk-runs/verified027-codex-archlinux-20260616T084044Z/matplotlib__matplotlib-23299/fvk/INTENT_SPEC.md).
