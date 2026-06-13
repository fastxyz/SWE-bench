# FVK PROOF OBLIGATIONS — django__django-13344

Each obligation has: statement, how discharged, and status. "Discharged
(constructed)" = proof constructed against the mini-X semantics, **not**
machine-checked (MVP caveat). "By inspection" = checked directly against the
real Python source (the S1–S5 trusted boundary). Tiers follow `verify.md` §6.

| ID | Obligation | Method | Status |
|----|-----------|--------|--------|
| PO-1 | `_async_check()` postcondition: marker set ⇔ `flag(get_response)` | inspection of `deprecation.py` + rule `initCorrect` | ✅ discharged |
| PO-2 | `(INIT)` for each fixed ctor: `flag(m)==runsAsync(m)` ∀ get_response | rewrite to `#Top` (claim `(INIT)`) | ✅ discharged (constructed) |
| PO-3 | `convert_exception_to_response` preserves the flag (S2) | inspection `exception.py:34` + rule S2 | ✅ discharged |
| PO-4 | `adapt_method_mode` flag contract (S4) | inspection `base.py:97-122` + rules S4 | ✅ discharged |
| PO-5 | `(CHAIN-INV)` preserved by the loop body (circularity) | claim `(STEP)`, requires `flag(H)==a` | ✅ discharged (constructed) |
| PO-6 | runtime dispatch: previous mw awaits this one ⇔ this one async (`(SAFE)`) | symbolic exec of 2-mw chain, both states | ✅ discharged (constructed) |
| PO-7 | completeness: every `MiddlewareMixin` ctor satisfies `(INIT)` | exhaustive enumeration (FINDINGS F5) | ✅ discharged |
| PO-8 | no-regression: sync/WSGI, `get_response=None`, decorator path | inspection + monotonicity (F6, F7) | ✅ discharged |
| PO-9 | termination of `load_middleware` loop | partial-correctness default | ⚪ not attempted (see §Residual) |

---

## PO-1 — `_async_check()` postcondition
`deprecation.py`:
```python
def _async_check(self):
    if asyncio.iscoroutinefunction(self.get_response):
        self._is_coroutine = asyncio.coroutines._is_coroutine
```
Sets the marker exactly when `flag(self.get_response)`. By S3,
`flag(self) = (marker set) = flag(self.get_response)`. Modeled by
`rule initCorrect(G) => inst(G, G)`. **Discharged by inspection.**

## PO-2 — `(INIT)` for the four fixed constructors
Claim `(INIT)`: `iscf(initCorrect(G)) ==Bool runsAsync(initCorrect(G)) => true`.
Symbolic execution:
```
iscf(initCorrect(G))      -> iscf(inst(G,G))      -> G        [initCorrect, S3]
runsAsync(initCorrect(G)) -> runsAsync(inst(G,G)) -> G        [initCorrect, S5]
G ==Bool G                -> true
```
Holds for **all** `G` (no `requires`). Each fixed ctor now ends in
`self.get_response = g; self._async_check()`, which is exactly `initCorrect(flag(g))`
(the other attribute assignments are async-irrelevant — `_async_check` reads only
`get_response`). **Discharged (constructed); `#Top` expected from kprove.**

Instances of PO-2, one per fixed file/class, all by the same reduction:
PO-2(Security), PO-2(Update), PO-2(Fetch), PO-2(Cache).

## PO-3 / PO-4 — the wrappers' flag contracts (trusted boundary)
- **PO-3 (S2):** `convert_exception_to_response` branches on
  `iscoroutinefunction(get_response)` and returns an `async def` iff that is
  true ⇒ `flag(cer(g))=flag(g)`. Modeled `rule iscf(cer(C)) => iscf(C)`.
- **PO-4 (S4):** `adapt_method_mode(is_async, h, h_is_async)` uses the *passed*
  `h_is_async` (only falls back to `iscoroutinefunction` when it is `None`,
  which the chain loop never does); returns `h` if `h_is_async==is_async`, else a
  `(sync|async)_to_(async|sync)` wrapper whose flag is `is_async`. Modeled by the
  two S4 rules. **Both discharged by inspection of the cited source.**

## PO-5 — `(CHAIN-INV)` circularity (the loop)
Claim `(STEP)`: `iscf(buildHandler(AMW,H,A)) ==Bool nextA(AMW) => true`
`requires iscf(H) ==Bool A`. Symbolic execution:
```
iscf(buildHandler(AMW,H,A))
  -> iscf(cer(initCorrect(iscf(adapt(AMW,H,A)))))            [buildHandler]
  -> iscf(initCorrect(iscf(adapt(AMW,H,A))))                 [S2]
  -> iscf(adapt(AMW,H,A))                                    [initCorrect+S3: iscf(inst(X,X))=X]
  case A ==Bool AMW : adapt->H, iscf(H)=A=AMW                [S4a + requires iscf(H)=A]
  case A =/=Bool AMW: adapt->raw(AMW), iscf=AMW              [S4b]
  -> AMW
AMW ==Bool nextA(AMW) -> AMW ==Bool AMW -> true             [nextA]
```
The `requires iscf(H)==A` is consumed exactly once, in the `A==AMW` branch — the
**coinductive hypothesis** role (the incoming invariant). Z3 closes the Boolean
case split. **Discharged (constructed).**

**Guardedness:** the genuine `=>⁺` step is the `buildHandler` rewrite (the loop
body advancing one middleware) before the invariant is re-used; no Reflexivity
short-circuit. **Base case (BASE):** `iscf(cer(raw(B)))==Bool B => true` reduces
via S2/S1; in ASGI `B = flag(_get_response_async) = true = is_async = a_0`.

## PO-6 — end-to-end runtime dispatch (`(SAFE)`)
Two-middleware async chain `[Outer, Inner]`, both `async_capable`. Symbolic
execution of `MiddlewareMixin.__call__`/`__acall__` under S5, in both worlds:

*Pre-fix (Inner = `initBuggy(true)`):*
`flag(Inner)=false` ⇒ `flag(cer(Inner))=false` ⇒ but `a=true` (tracked) ⇒
`adapt(true, cer(Inner), true)` returns it unchanged ⇒ `Outer.get_response` has
`flag=false` ⇒ `runsAsync(Outer)=false` ⇒ Outer sync-calls `cer(Inner)` →
`Inner.__call__` is async (`runsAsync(Inner)=flag(h0)=true`) → returns a
**coroutine** → Outer's `process_response(request, coroutine)`. ❌ = the bug.

*Post-fix (Inner = `initCorrect(true)`):*
`flag(Inner)=true` ⇒ `flag(cer(Inner))=true=a` ⇒ `Outer.get_response` flag=true ⇒
`runsAsync(Outer)=true` ⇒ Outer `await cer(Inner)(request)` (async inner awaits
`Inner(request)`) → resolves to `HttpResponse` → Outer's
`process_response(request, HttpResponse)`. ✅ = `(SAFE)`.
**Discharged (constructed); both worlds traced.**

## PO-7 — completeness
Enumerated in FINDINGS F5: the set of `MiddlewareMixin` subclasses overriding
`__init__` is {Security, Update, Fetch, Cache, Session, RedirectFallback}.
Session and RedirectFallback already establish `(INIT)`; the other four are the
V1 fix set. No other subclass overrides `__init__`. **Discharged by exhaustive
enumeration.**

## PO-8 — no-regression
- **sync/WSGI:** handler handed to each middleware is sync ⇒ `flag=false` ⇒
  marker never set ⇒ identical to pre-fix. ✅
- **`get_response=None`:** `flag(None)=false` ⇒ marker unset; `(INIT)` vacuous. ✅
- **decorator path (F7):** `_wrapped_view` never reads `flag(instance)` nor calls
  `__call__`; adding the marker is inert there. ✅
**Discharged by inspection + monotonicity (F6).**

## PO-9 — termination (not attempted)
`load_middleware` iterates `reversed(settings.MIDDLEWARE)` (finite); the runtime
chain is finite. Partial correctness is the FVK default; termination is a
recommendation only and is not part of this bug. **Not attempted.**
