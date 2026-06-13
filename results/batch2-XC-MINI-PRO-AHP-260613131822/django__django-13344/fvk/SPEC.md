# FVK SPEC — django__django-13344 (async middleware marker)

Target of formalization: the sync/async **dispatch bookkeeping** of Django's
`MiddlewareMixin` adapter and the handler chain that wraps it
(`django/utils/deprecation.py`, `django/core/handlers/base.py`,
`django/core/handlers/exception.py`), as fixed by V1.

This is **intent-spec mode**: the intended behaviour comes from the issue
(`benchmark/PROBLEM.md` — "the first middleware receives a coroutine instead of
an HttpResponse"), the public hints (the `_async_check()` diagnosis), and the
existing correct middlewares (`SessionMiddleware`, `RedirectFallbackMiddleware`)
that already do the right thing. The code is checked against that intent.

Companion K artifacts (mini-X fragment): `fvk/middleware-async.k` (semantics),
`fvk/middleware-async-spec.k` (claims).

---

## 1. Scope and abstraction

This bug is **not** arithmetic and has **no loop over data** — so the arithmetic
recipe (closed forms, `/Int` halving) does not apply directly. What *does* apply
is the FVK core: write the precise contract, find the silently-assumed
precondition, and prove the fix restores it.

**Abstraction.** The async-ness of every callable is collapsed to one Bool:

```
flag(x) == ( asyncio.iscoroutinefunction(x) is True )
```

`asyncio.iscoroutinefunction(x)` is `True` when `x` is an `async def`, or when
`x` is any object carrying the magic attribute
`x._is_coroutine is asyncio.coroutines._is_coroutine`. asgiref's
`SyncToAsync` instances carry that marker; `AsyncToSync` instances do not. So
the whole problem is **Boolean algebra over `flag`**, which is the "mini-X"
fragment we model in `middleware-async.k`.

### Trusted side conditions (ESCALATION BOUNDARY — modeled by contract only)

Real coroutine objects, `await`, scheduling, and asgiref internals are out of
the mini-X fast path (binders + concurrency). We model their **flag contract**
and trust it by inspection:

- **S1** `flag(async def f)=True`, `flag(def f)=False`, `flag(SyncToAsync(f))=True`,
  `flag(AsyncToSync(f))=False`. (asgiref + CPython `asyncio`.)
- **S2** `convert_exception_to_response(g)` returns an `async def inner` iff
  `flag(g)`, so it **preserves** the flag: `flag(cer(g)) = flag(g)`.
  (`exception.py:34`.)
- **S3** For a `MiddlewareMixin` instance `m`, `flag(m) = (m._is_coroutine set)`.
  (`asyncio.iscoroutinefunction` on a callable object reads `_is_coroutine`.)
- **S4** `adapt_method_mode(is_async, h, h_is_async)` **trusts the passed flag**
  `h_is_async` (never re-derives it when given): returns `h` unchanged if
  `h_is_async == is_async`, else wraps it so the result's flag becomes
  `is_async`. Hence `flag(adapt(A,h,M)) = flag(h)` if `M==A`, else `A`.
  (`base.py:97-122`.)
- **S5** `MiddlewareMixin.__call__(m, request)` dispatches to the async
  `__acall__` (and thus returns a coroutine) iff `flag(m.get_response)`.
  Define `runsAsync(m) = flag(m.get_response)`. (`deprecation.py:110-113`.)

---

## 2. The intended contract

### 2a. `_async_check()` — postcondition

After `m.get_response = g; m._async_check()`:

```
m._is_coroutine is set   ⇔   flag(g)            (deprecation.py:_async_check)
```

i.e., by S3, `flag(m) = flag(m.get_response)`.

### 2b. (INIT) — the constructor contract (the heart of the spec)

For **every** `MiddlewareMixin` subclass instance `m` built with get_response
`g`, the constructor must establish:

```
(INIT)      flag(m)  ==  runsAsync(m)            ( == flag(g) )
```

Read in English: *an adapter advertises itself as a coroutine-function to the
outside world (`iscoroutinefunction(m)`) exactly when it will actually behave as
one (`__call__` returns a coroutine).* This is the **self-consistency** every
adapter owes its callers. Its **precondition** is "the constructor calls
`_async_check()` after assigning `get_response`." That precondition is what the
buggy middlewares silently dropped.

K claim (`middleware-async-spec.k`, `(INIT)`):

```k
claim <k> iscf(initCorrect(G:Bool)) ==Bool runsAsync(initCorrect(G)) => true ... </k>
```

### 2c. (STEP) — the chain loop invariant (circularity)

`BaseHandler.load_middleware` builds the chain bottom-up, carrying a handler `H`
and an explicitly tracked flag `a = handler_is_async`. The loop invariant is:

```
(CHAIN-INV)      flag(H_i)  ==  a_i        at the end of every iteration i
```

This is what keeps S4's *trusted* `handler_is_async` honest: `adapt_method_mode`
believes `a`, so `a` must equal the real `flag(H)`. The loop body preserves it
**iff (INIT) holds** for the middleware it just constructed:

```
H'  = cer( mw ),   mw = middleware( adapt(Amw, H, a) ),   a' = Amw
flag(H') = flag(mw)                         (S2)
         = runsAsync(mw)                     (INIT, the obligation)
         = flag(adapt(Amw,H,a)) = Amw = a'   (S4 + IH flag(H)=a)
```

K claim (`middleware-async-spec.k`, `(STEP)`, the coinductive circularity):

```k
claim <k> iscf(buildHandler(AMW:Bool, H:Callable, A:Bool)) ==Bool nextA(AMW) => true ... </k>
  requires iscf(H) ==Bool A
```

**Base case (BASE).** Entry handler `cer(_get_response_async)` has
`flag = True` and `a_0 = is_async = True` in ASGI, so `flag(H_0)==a_0`. K claim
`(BASE)`: `iscf(cer(raw(B))) ==Bool B => true`.

### 2d. The end-to-end safety property the user observes

From (CHAIN-INV) + S5: for every adjacent pair (outer `O`, inner `I`) in the
chain, `O.get_response = cer(I)` has `flag = flag(I) = runsAsync(I)`. So:

```
(SAFE)   O runs async  ⇔  I returns a coroutine
```

Therefore an async inner is always *awaited* by an async outer before the outer
calls `process_response`. Equivalently: **`process_response` never receives a
coroutine.** That is exactly the property the issue says was broken.

---

## 3. Domain / preconditions

- The contract is stated for `MiddlewareMixin` subclasses (the sync/async
  adapter). New-style plain middlewares manage their own `__call__` and are
  out of scope.
- `get_response = None` (the deprecated constructor path) is in-domain:
  `flag(None) = False`, marker correctly left unset; `(INIT)` holds vacuously.
- Out of scope (explicitly): the `cache_page`/`decorator_from_middleware` path,
  which drives `process_request`/`process_response` directly and never consults
  `flag(instance)` (see FINDINGS F7); and real coroutine scheduling (S1–S5
  boundary).

---

## 4. Human-readable spec note

Every Django middleware *adapter* (`MiddlewareMixin` subclass) must tell the
truth about whether it is asynchronous. The single source of truth is the
`_is_coroutine` marker, set by `MiddlewareMixin._async_check()` whenever the
`get_response` it was handed is a coroutine function. The handler chain and
`convert_exception_to_response` read that marker (via
`asyncio.iscoroutinefunction`) to decide whether the *previous* middleware must
`await` this one. If a subclass overrides `__init__` and forgets to run
`_async_check()`, it lies (claims to be sync while behaving async); the previous
middleware then calls it without awaiting and hands the resulting **coroutine**
straight to its own `process_response`. The contract `(INIT)` —
*`iscoroutinefunction(m)` equals "`m` actually runs async"* — must hold for
every adapter, and `(STEP)`/`(SAFE)` show that this per-adapter contract is what
keeps the whole chain awaiting correctly.
