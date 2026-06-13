# FVK FINDINGS — django__django-13344

Plain-language findings from formalizing the async-middleware marker contract
`(INIT)`/`(CHAIN-INV)`/`(SAFE)` (see `SPEC.md`). Format: `input → observed vs
expected`. Findings are non-blocking advice; the code edits they justify are in
`reports/fvk_notes.md`.

The spec was **clean and easy to state** — `(INIT)` is a one-line Boolean
equality. The bug is therefore not a spec-difficulty smell but a plain
**dropped precondition**: four constructors never establish `(INIT)`.

---

## Bugs fixed by V1 (the reported issue)

### F1 — `SecurityMiddleware.__init__` omits `_async_check()` (THE reported bug)
- **input:** ASGI server, `MIDDLEWARE = [DummyMiddleware, SecurityMiddleware]`
  (any sync-or-async-capable middleware ahead of `SecurityMiddleware`); a request.
- **observed (pre-fix):** `SecurityMiddleware` instance is built with an async
  `get_response`, but `_is_coroutine` is never set, so
  `iscoroutinefunction(security_instance) → False`.
  `convert_exception_to_response` therefore wraps it in a **sync** `inner`;
  `DummyMiddleware.get_response` looks sync, so `DummyMiddleware.__call__` stays
  on the sync path, calls it **without `await`**, and
  `DummyMiddleware.process_response(request, <coroutine>)` runs — exactly the
  `<class 'coroutine'>` in the issue.
- **expected (`(INIT)`):** `flag(security_instance) == runsAsync(security_instance)`
  so the previous middleware sees it as async and awaits it; `process_response`
  receives an `HttpResponse`.
- **root cause:** `__init__` sets `self.get_response` but never calls
  `self._async_check()` (nor `super().__init__()`), so the marker is missing
  despite `async_capable = True`.
- **fix:** add `self._async_check()` after `self.get_response = get_response`
  (`django/middleware/security.py`). Discharges PO-2(Security).

### F2 — `UpdateCacheMiddleware.__init__` omits `_async_check()`
- **input:** ASGI, `UpdateCacheMiddleware` first in `MIDDLEWARE` (its documented
  position) with anything ahead of it / it ahead of another middleware.
- **observed vs expected:** identical mechanism to F1 — sync-looking async
  instance ⇒ a coroutine reaches the previous middleware's `process_response`.
- **fix:** `self._async_check()` after `self.get_response = get_response`
  (`django/middleware/cache.py`). Discharges PO-2(Update).

### F3 — `FetchFromCacheMiddleware.__init__` omits `_async_check()`
- Same mechanism and fix as F2 (`django/middleware/cache.py`).
  Discharges PO-2(Fetch).

### F4 — `CacheMiddleware.__init__` omits `_async_check()`
- `CacheMiddleware(UpdateCacheMiddleware, FetchFromCacheMiddleware)` overrides
  `__init__` and does **not** chain to either parent, so it independently drops
  the marker. Same mechanism and fix (`django/middleware/cache.py`, after the
  early `self.get_response = get_response`). Discharges PO-2(Cache).

---

## Completeness sweep (positive findings — no change needed, justified)

### F5 — every other `MiddlewareMixin` subclass already satisfies `(INIT)`
Exhaustive enumeration of `MiddlewareMixin` subclasses in `django/` that
override `__init__`:
- `SessionMiddleware` — already calls `self._async_check()`
  (`contrib/sessions/middleware.py:18`). ✓
- `RedirectFallbackMiddleware` — calls `super().__init__(get_response)`, which
  runs `_async_check()` (`contrib/redirects/middleware.py:21`). ✓
- `SecurityMiddleware`, `UpdateCacheMiddleware`, `FetchFromCacheMiddleware`,
  `CacheMiddleware` — F1–F4, now fixed.

All other `MiddlewareMixin` subclasses (`CommonMiddleware`,
`BrokenLinkEmailsMiddleware`, `XFrameOptionsMiddleware`, `ConditionalGetMiddleware`,
`CsrfViewMiddleware`, `GZipMiddleware`, `LocaleMiddleware`, `MessageMiddleware`,
`CurrentSiteMiddleware`, `AuthenticationMiddleware`, `RemoteUserMiddleware`,
`PersistentRemoteUserMiddleware`, `FlatpageFallbackMiddleware`, `XViewMiddleware`,
and the test-only `CSPMiddleware`) do **not** override `__init__`; they inherit
`MiddlewareMixin.__init__`, which runs `_async_check()`. ✓ Discharges PO-7.
- **expected:** the fix set is exactly {Security, Update, Fetch, Cache} — and
  V1 changed exactly that set. No middleware was missed; none was changed
  unnecessarily.

### F6 — the fix can only make `iscoroutinefunction(instance)` *more* accurate
- **input:** any `get_response` (sync `def`, async `def`, or `None`).
- **observed:** `_async_check()` sets the marker **iff** `flag(get_response)`.
  In WSGI mode the handler handed to a middleware is always sync, so the marker
  is never set — byte-for-byte the old behaviour. With `get_response=None`
  (deprecated path) `flag(None)=False`, marker unset. The marker is set *only*
  when the instance genuinely runs async.
- **expected:** no sync/WSGI regression; the change is monotone — it never sets
  the marker when it should be unset. Discharges PO-8(sync) and PO-8(None).

---

## Out-of-scope / pre-existing (NOT introduced or worsened by V1)

### F7 — `cache_page` decorator + async view (separate, pre-existing)
- **input:** `@cache_page(t)` (i.e. `decorator_from_middleware_with_args(CacheMiddleware)`)
  on an `async def` view.
- **observed:** `make_middleware_decorator._wrapped_view` is a plain `def` that
  calls `view_func(request)` directly and feeds the result to
  `middleware.process_response`; an async view returns a coroutine there. It
  **never** calls `CacheMiddleware.__call__` and **never** consults
  `iscoroutinefunction(instance)`.
- **relation to V1:** V1 adds `_async_check()` to `CacheMiddleware`, which now
  *may* set `_is_coroutine` on the instance — but this path never reads it, so
  V1 **neither fixes nor breaks** F7. It is a distinct issue, outside this
  ticket's domain (SPEC §3). Discharges PO-8(decorator) as "no regression".
- **recommendation:** track separately; not part of this fix.

---

## Design observation (robustness, recommendation-only)

### F8 — `(INIT)` is an implicit, easily-dropped invariant
- The contract `(INIT)` is re-established by hand in every overriding `__init__`.
  Four of seven overrides forgot it — a 57% miss rate is a strong "fragile
  pattern" signal even though each individual fix is trivial.
- **recommendation (not done in V1, deliberately minimal):** consider making the
  marker harder to drop — e.g. a base-class post-init hook, asserting the marker
  in `__call__`, or a system check. Tracked in `ITERATION_GUIDANCE.md`; out of
  scope for a minimal bugfix.

---

## Proof-derived findings from `/verify`

### PV1 — `(STEP)` needs `flag(H)==a` as a `requires` (the silently-assumed precondition)
The chain circularity `(STEP)` only discharges under `requires iscf(H) ==Bool A`
(`middleware-async-spec.k`). That side condition **is** the dropped precondition:
`adapt_method_mode` *trusts* `handler_is_async` (S4), so the tracked flag must
equal the real flag. `(INIT)` is precisely what makes the freshly-built
middleware re-establish `iscf(H')==a'`. Classification: **missing precondition /
needed code guard** — discharged by V1.

### PV2 — the pre-fix `(REFUTATION)` claim fails with witness `G = true`
`iscf(initBuggy(G)) ==Bool runsAsync(initBuggy(G))` does **not** reduce to
`#Top`: it leaves residual `false ==Bool G`, false at `G = true`. A failed proof
here is the bug, machine-localizable to the async-handler case. Post-fix the
analogous `(INIT)` claim reduces to `#Top` for all `G`. Classification: **code
bug**, fixed.

### PV3 — exactly-one-of marker vs. behaviour (no over-fix)
`(INIT)` is an *equality*, not an implication, so the proof also rules out the
dual error (marker set while running sync). V1 cannot cause it because
`_async_check` sets the marker *from* `flag(get_response)`. Classification:
**confirmation** — V1 is tight, not over-broad.
