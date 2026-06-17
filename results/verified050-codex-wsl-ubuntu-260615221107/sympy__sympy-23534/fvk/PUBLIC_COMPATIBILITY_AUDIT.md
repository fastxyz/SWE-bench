# Public Compatibility Audit

Status: pass.

Changed public symbol: `sympy.core.symbol.symbols`.

## Signature Compatibility

The signature remains `symbols(names, *, cls=Symbol, **args) -> Any`. No caller
needs a new positional or keyword argument, and no existing keyword is renamed or
removed.

## Return Shape Compatibility

The iterable branch still returns `type(names)(result)`. The fix changes only
the constructor class used inside recursive calls. It does not flatten nested
iterables, change tuple/list/set reconstruction, or alter string range parsing.

## Callsite Compatibility

Public source callsites using `symbols(..., cls=...)` continue to call the same
API. The repair broadens documented behavior to iterable inputs by preserving
the caller's class through recursion.

`var()` passes `cls` through its `**args` call to `symbols()` and benefits from
the same correction without any signature or traversal change.

`dynamicsymbols()` calls `symbols(names, cls=Function, **assumptions)` for its
documented string input. The change does not alter that string path. If callers
pass nested iterable names, the outer nested shape remains as before; only the
inner class is corrected.

## Overrides and Virtual Dispatch

No method signature, virtual dispatch call, subclass override, storage format,
or producer/consumer protocol is changed.
