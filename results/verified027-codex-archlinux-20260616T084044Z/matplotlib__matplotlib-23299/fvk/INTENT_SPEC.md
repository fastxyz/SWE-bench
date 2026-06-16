# Intent Spec

Constructed, not machine-checked.

## Required Behavior

1. `matplotlib.get_backend()` returns the current backend name.

2. If the global `rcParams["backend"]` value is the auto-backend sentinel
   because `rc_context()` restored a saved value, but pyplot has already loaded
   a concrete backend, `get_backend()` must report that loaded backend without
   destroying existing pyplot figure managers.

3. In the issue reproduction, the contents of `plt._pylab_helpers.Gcf.figs`
   before and after `get_backend()` must be the same.

4. Initial lazy backend resolution remains valid: when no backend has been
   loaded yet, reading the global backend may resolve the auto sentinel through
   pyplot backend selection.

5. Real backend switches may keep their existing behavior of closing figures;
   the issue only rejects a destructive switch caused by stale sentinel
   re-resolution after a backend already exists.

## Frame Conditions

- Preserve `Gcf.figs` for a loaded-backend stale-sentinel read.
- Preserve the behavior of standalone `RcParams` instances: the special
  resolving behavior applies only to the global `rcParams`.
- Preserve public signatures for `RcParams.__getitem__`, `get_backend()`,
  `rc_context()`, and `pyplot.switch_backend()`.
