# Proof Obligations

Constructed, not machine-checked.

## PO-1: Stale Sentinel Must Not Clear Figures

**Intent source:** E1, E2, E3, E4.

**Precondition:** global `rcParams["backend"]` stores `auto`; pyplot is imported;
pyplot has already loaded a concrete backend `B`; `Gcf.figs` is arbitrary `FS`.

**Postcondition:** `get_backend()` returns `B`, global `rcParams["backend"]`
becomes `B`, and `Gcf.figs` remains `FS`.

**V1 status:** discharged by the new `plt is not None and
getattr(plt, "_backend_mod", None)` branch.

## PO-2: Initial Lazy Resolution Must Still Work

**Intent source:** E5, E6.

**Precondition:** global `rcParams["backend"]` stores `auto`; no pyplot backend
is loaded; `Gcf.figs` is empty.

**Postcondition:** `get_backend()` may call `switch_backend(auto)`, select a
concrete backend, and leave `Gcf.figs` empty.

**V1 status:** discharged because the new branch does not fire when
`_backend_mod` is absent.

## PO-3: Concrete Backend Reads Are Observational

**Intent source:** E5 and the API name `get_backend`.

**Precondition:** global `rcParams["backend"]` already stores a concrete backend
`B`; `Gcf.figs` is arbitrary `FS`.

**Postcondition:** `get_backend()` returns `B` and `Gcf.figs` remains `FS`.

**V1 status:** unchanged from existing behavior.

## PO-4: Non-Global RcParams Must Not Resolve The Sentinel

**Intent source:** E8.

**Precondition:** `RcParams.__getitem__("backend")` is called on an `RcParams`
object that is not the global `rcParams`.

**Postcondition:** the V1 global-backend repair path is not taken.

**V1 status:** discharged by the existing `self is globals().get("rcParams")`
guard, which V1 preserved.

## PO-5: Real Backend Switch Semantics Must Remain Destructive

**Intent source:** E6.

**Precondition:** code explicitly calls `pyplot.switch_backend(newbackend)` or
global backend lookup genuinely has no loaded backend and must resolve the auto
sentinel.

**Postcondition:** `switch_backend()` keeps its existing `close("all")`
behavior. The fix only avoids entering this path when the backend is already
loaded.

**V1 status:** discharged because V1 changes only `RcParams.__getitem__`; it
does not edit `pyplot.switch_backend()`.

## PO-6: Public API Compatibility

**Intent source:** C1-C5 in `PUBLIC_COMPATIBILITY_AUDIT.md`.

**Precondition:** public users call `get_backend()`, global
`rcParams["backend"]`, standalone `RcParams["backend"]`, `rc_context()`, or
`pyplot.switch_backend()`.

**Postcondition:** signatures are unchanged; only the stale-sentinel
loaded-backend side effect is removed.

**V1 status:** discharged by inspection.
