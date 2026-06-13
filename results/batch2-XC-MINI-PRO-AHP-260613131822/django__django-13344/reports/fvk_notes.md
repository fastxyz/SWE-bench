# FVK Notes — django__django-13344

How the Formal Verification Kit audit was applied to the V1 fix, and why every
decision was made, traced to `fvk/FINDINGS.md` and `fvk/PROOF_OBLIGATIONS.md`.

## Method adaptation

This issue is a **flag-bookkeeping** bug, not an arithmetic/loop bug, so the
arithmetic recipe (closed forms, `/Int` halving) does not apply. I adapted FVK
faithfully: the async-ness of every callable is abstracted to one Bool
(`flag(x) = asyncio.iscoroutinefunction(x)`), giving a clean Boolean-algebra
mini-X semantics (`fvk/middleware-async.k`). Real coroutine/`await`/asgiref
internals are an explicit **escalation boundary** (binders + concurrency),
modeled by named contracts S1–S5 (`SPEC.md`) — *not* faked as `[trusted]`
claims, per `verify.md`. The specification was clean and easy to write, which
itself signals the bug is a simple dropped precondition rather than a deep
design flaw.

## The specification (SPEC.md)

The contract is `(INIT)`: for every `MiddlewareMixin` adapter `m`,
`iscoroutinefunction(m)` must equal "`m` actually runs async"
(`flag(m) == runsAsync(m)`). Its silently-assumed **precondition** is "the
constructor calls `_async_check()` after assigning `get_response`." `(STEP)`
(the chain loop circularity) and `(SAFE)` show this per-adapter contract is
exactly what makes each middleware get *awaited* by the one in front of it — so
that `process_response` never receives a coroutine.

## Decision 1 — Keep the four V1 edits unchanged

**Decision:** confirm V1; the `self._async_check()` additions to
`SecurityMiddleware`, `UpdateCacheMiddleware`, `FetchFromCacheMiddleware`,
`CacheMiddleware` stand as written.

**Justification:**
- Findings **F1–F4** identify exactly these four constructors as violating
  `(INIT)`: each sets `self.get_response` but never runs `_async_check()`, so the
  `_is_coroutine` marker is missing despite `async_capable = True`.
- Obligation **PO-2** is discharged (constructed `#Top`) *because* each fixed
  `__init__` now reduces to `initCorrect(flag(g))` — i.e. `get_response` assigned,
  then `_async_check()`. `PROOF.md` §2 shows the reduction
  `iscf(initCorrect(G)) == runsAsync(initCorrect(G)) ⇒ true` for all `G`.
- Obligation **PO-6** (`PROOF.md` §4, the two-world trace) shows the post-fix
  chain hands `process_response` an `HttpResponse`, while the pre-fix chain hands
  it a `coroutine` — reproducing the issue's `<class 'coroutine'>` and confirming
  the edit removes it.
- The placement (after `self.get_response = get_response`) is required because
  `_async_check()` reads `self.get_response` (PO-1). I re-verified all four spots:
  `security.py:22-23`, `cache.py:73-74`, `cache.py:136-137`, `cache.py:179-180`.
  For `CacheMiddleware` the call sits right after the early `get_response`
  assignment; the remaining attribute writes are async-irrelevant (PO-2 note).

## Decision 2 — Change nothing else; the fix set is exactly right

**Decision:** no other source file is touched.

**Justification:** Obligation **PO-7** + Finding **F5** are an exhaustive
enumeration of `MiddlewareMixin` subclasses overriding `__init__`:
{Security, Update, Fetch, Cache, Session, RedirectFallback}. `SessionMiddleware`
already calls `_async_check()` and `RedirectFallbackMiddleware` calls
`super().__init__(get_response)` — both already satisfy `(INIT)`, so touching
them would be unjustified churn. Every other subclass (Common, XFrameOptions,
Csrf, GZip, Locale, Message, etc., and the test-only `CSPMiddleware`) does **not**
override `__init__`, inheriting the correct base. So V1 changed exactly the
violating set — no middleware missed, none changed needlessly.

## Decision 3 — Reject `super().__init__()` as the mechanism

**Decision:** use `self._async_check()`, not `super().__init__(get_response)`.

**Justification:** confirmed by inspection during the audit (and consistent with
PO-2's model). For Security/Update/Fetch, `super().__init__()` would duplicate the
deprecation check and the `get_response` assignment; for `CacheMiddleware` it
would route through the MRO into `UpdateCacheMiddleware.__init__` and run the
wrong cache-setup logic. The single `_async_check()` call is the minimal move and
matches Django's own already-correct `SessionMiddleware` (F5). This is the same
rationale recorded in `baseline_notes.md`, now backed by the `(INIT)` contract.

## Decision 4 — Do NOT add robustness hardening (G2)

**Decision:** leave the implicit-invariant fragility (Finding **F8**) unaddressed
in code.

**Justification:** F8 is a real maintainability signal (4 of 7 overrides forgot
the call), but it is **not a current correctness bug** — PO-2/PO-7 are fully
discharged by the minimal fix. The task calls for a minimal, targeted change, and
G1 matches Django's established pattern. The structural options (a system check,
an `__init_subclass__` post-init hook, or removing the `get_response=None` shim so
`super().__init__()` becomes clean) are larger changes recorded in
`ITERATION_GUIDANCE.md` G2 for a follow-up, not this fix.

## Decision 5 — Treat the `cache_page` decorator/async-view gap as out of scope

**Decision:** no change to `utils/decorators.py`.

**Justification:** Finding **F7** / obligation **PO-8(decorator)**: the
`make_middleware_decorator` wrapper drives `process_request`/`process_response`
directly and never consults `iscoroutinefunction(instance)`, so V1's added marker
is inert there — V1 neither fixes nor breaks it. The async-view-through-`cache_page`
limitation is a distinct, pre-existing issue (ITERATION_GUIDANCE G3), outside this
ticket's domain (SPEC §3).

## No-regression confirmation

Obligation **PO-8** + Finding **F6**: `_async_check()` sets the marker **iff**
`flag(get_response)`, so the change is monotone — it can only make
`iscoroutinefunction(instance)` *more* accurate. WSGI/sync chains (handler always
sync ⇒ marker never set) and the deprecated `get_response=None` path
(`flag(None)=False`) are byte-for-byte unchanged. Finding **PV3** notes `(INIT)`
is an equality, so the fix also cannot introduce the dual error (marker set while
running sync).

## Honesty gate

The proof is **constructed, not machine-checked** (no execution environment; MVP
does not run `kprove`). `PROOF.md` §8 emits the would-be `kompile`/`kast`/`kprove`
commands and their expected results (`#Top` for `(BASE)`,`(INIT)`,`(STEP)`;
intentional non-`#Top` for `(REFUTATION)`, which encodes the pre-fix bug). No
tests are recommended for removal (`PROOF.md` §6); the recommended ASGI regression
tests are advisory only, since the test suite is fixed and hidden.

## Outcome

**V1 stands unchanged.** The FVK audit upgraded it from "looks right" to
"specified and proof-obligation-checked": the contract `(INIT)` is stated, the
four violations are localized (F1–F4), the fix set is proved exactly complete
(PO-7), correctness is traced end-to-end to the reported symptom (PO-6), and
no-regression is established (PO-8).
