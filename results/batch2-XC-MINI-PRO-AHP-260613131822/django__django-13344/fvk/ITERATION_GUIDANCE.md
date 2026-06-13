# FVK ITERATION GUIDANCE — django__django-13344

Feedback package for the next generate→formalize→verify pass. Each item:
evidence → classification → UltimatePowers question → recommended change →
tests. Per the FVK loop, `/verify` does **not** silently regenerate code; this
file records what a follow-up pass *should* consider.

---

## G1 — Establish `(INIT)` in every middleware constructor (DONE in V1)
- **Evidence:** FINDINGS F1–F4; PO-2; refutation PV2 (`G=true` counterexample).
- **Classification:** code bug / dropped precondition.
- **UltimatePowers question:** "When a middleware subclass overrides `__init__`,
  must it always re-run the async self-check?" → **Yes**, it is part of the
  adapter contract.
- **Change (applied):** add `self._async_check()` after
  `self.get_response = get_response` in `SecurityMiddleware`,
  `UpdateCacheMiddleware`, `FetchFromCacheMiddleware`, `CacheMiddleware`.
- **Tests:** add an ASGI regression (≥2 middlewares) asserting the first
  middleware's `process_response` gets an `HttpResponse` for each of the four
  classes. *(Recommendation only — tests are fixed/hidden here.)*

## G2 — Harden against re-dropping `(INIT)` (NOT done; recommend follow-up)
- **Evidence:** FINDINGS F8 — 4 of 7 overriding constructors had forgotten the
  call; the invariant is implicit and easy to miss.
- **Classification:** robustness / maintainability gap (not a current bug).
- **UltimatePowers question:** "Prefer a minimal per-class fix now, or a
  structural guard so the marker can't be forgotten again?"
- **Recommended options (pick later, deliberately NOT in this minimal bugfix):**
  1. A Django **system check** (or test) that asserts every `MiddlewareMixin`
     subclass advertises `iscoroutinefunction` consistently with an async
     `get_response`.
  2. A base-class **post-init hook** / `__init_subclass__` that runs
     `_async_check()` after subclass `__init__`, so overrides can't skip it.
  3. Long-term: drop the `RemovedInDjango40Warning` `get_response=None` shim so
     these `__init__`s can simply `super().__init__(get_response)` (the cleanest
     end state, but it changes the deprecation timeline — out of scope now).
- **Why deferred:** the task asks for a minimal, targeted fix; G1 matches
  Django's own established pattern (`SessionMiddleware`). G2 is a separate,
  larger change.

## G3 — `cache_page`/decorator + async views (separate ticket)
- **Evidence:** FINDINGS F7; `utils/decorators.py::make_middleware_decorator`
  builds a **sync** `_wrapped_view` that calls `view_func` directly.
- **Classification:** pre-existing limitation, **out of scope** for this issue;
  V1 neither fixes nor worsens it.
- **UltimatePowers question:** "Should `cache_page` (and other
  `decorator_from_middleware` users) support async views?"
- **Recommended change:** none here; file/track independently. If pursued, the
  decorator wrapper must detect `iscoroutinefunction(view_func)` and provide an
  async wrapper that awaits the view — a different fix from this one.

## G4 — Spec/abstraction debt to retire (FVK roadmap)
- **Evidence:** PROOF §7 trusted base S1–S5; `middleware-async.k` is a Bool
  abstraction, not real coroutine semantics.
- **Classification:** proof capability gap / escalation boundary (binders +
  concurrency), not a code bug.
- **Recommended change:** when real per-language async semantics are available
  in K, replace S1–S5 contracts with the actual `await`/`SyncToAsync` rules and
  re-discharge `(INIT)`/`(STEP)` against them.
- **Tests:** keep the F1–F4 regression tests until the claims are machine-checked
  (`kprove ⇒ #Top`); only then are any test-redundancy removals safe (none are
  proposed anyway — see PROOF §6).

---

## Summary for the next pass
V1 is **confirmed correct and complete** for the reported issue (G1 discharges
PO-1..PO-8; PO-7 shows the fix set is exactly right). The only forward-looking,
*optional* work is the robustness hardening G2 and the unrelated G3; both are
deliberately excluded from this minimal fix and recorded here so they are not
lost.
