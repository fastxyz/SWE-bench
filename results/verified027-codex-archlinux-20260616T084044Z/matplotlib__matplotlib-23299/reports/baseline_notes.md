# Baseline Notes

## Root cause

`matplotlib.get_backend()` returns `rcParams["backend"]`. For the global
`rcParams` object, reading `"backend"` resolves the private auto-backend
sentinel by calling `pyplot.switch_backend(_auto_backend_sentinel)`.

When a figure is first created inside `rc_context()`, backend resolution happens
inside the context and pyplot stores the selected concrete backend. On context
exit, `rc_context()` restores the saved rcParams with `dict.update`, so the
saved auto sentinel can overwrite the concrete backend value in `rcParams` even
though pyplot is already using that backend and `Gcf` still contains figure
managers for it.

The next `get_backend()` sees the sentinel and calls `switch_backend()` again.
`switch_backend()` closes all figures before resolving the backend, so the
figure manager created inside the context is removed from `Gcf.figs`.

## Files changed

`repo/lib/matplotlib/__init__.py`

Updated `RcParams.__getitem__` for the global `"backend"` key. If the stored
value is the auto-backend sentinel but `matplotlib.pyplot` already has a loaded
backend module, the code now restores `rcParams["backend"]` from
`matplotlib.backends.backend` and returns it. This preserves the existing
backend selection and avoids calling `pyplot.switch_backend()` solely because
`rc_context()` restored the sentinel.

## Assumptions

The already loaded pyplot backend is the authoritative backend once
`pyplot._backend_mod` is set. That matches the existing `switch_backend()`
behavior, which records the selected backend in `matplotlib.backends.backend`
and updates `rcParams` during backend selection.

`get_backend()` should be observational in this scenario: it may force initial
lazy backend resolution, but it should not destroy figures when a backend has
already been selected.

## Alternatives considered

Changing `rc_context()` to preserve a resolved backend on exit would fix the
reported reproduction, but it would only address this specific context manager
and would leave other paths that restore the auto sentinel able to trigger the
same destructive re-resolution.

Moving or removing the unconditional `close("all")` in `pyplot.switch_backend()`
would be broader than necessary because real backend switches still need to
discard managers tied to the old backend.

Special-casing `matplotlib.get_backend()` directly would leave direct reads of
the global `rcParams["backend"]` with the same problematic behavior.
