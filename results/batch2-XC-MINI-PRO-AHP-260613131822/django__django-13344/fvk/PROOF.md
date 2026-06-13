# FVK PROOF — django__django-13344 (constructed, not machine-checked)

Proves the V1 fix establishes the middleware async-marker contract from
`SPEC.md`. Semantics: `fvk/middleware-async.k`; claims:
`fvk/middleware-async-spec.k`. Per the MVP honesty gate, the proof is
**constructed by symbolic execution, not run through `kprove`**; the `S1–S5`
boundary is trusted by inspection of the cited Python.

---

## 1. What is proved (plain language)

> For every Django `MiddlewareMixin` adapter `m` built with any `get_response`
> `g`, `asyncio.iscoroutinefunction(m)` is `True` **iff** `m` actually behaves
> asynchronously (`m.__call__` returns a coroutine), `(INIT)`. Consequently, in
> any handler chain each middleware is awaited by the one in front of it exactly
> when it is async, `(CHAIN-INV)`/`(SAFE)`, so **no `process_response` ever
> receives a coroutine** — the failure reported in the issue.

V1 makes `(INIT)` hold for the four constructors that violated it
(`SecurityMiddleware`, `UpdateCacheMiddleware`, `FetchFromCacheMiddleware`,
`CacheMiddleware`); the other constructors already satisfied it.

## 2. Function contract `(INIT)` — proof

Claim: `iscf(initCorrect(G)) ==Bool runsAsync(initCorrect(G)) => true`, all `G`.

```
initCorrect(G) =>* inst(G, G)                          // _async_check sets marker := flag(g)=G
iscf(inst(G,G))       => G                              // S3: marker
runsAsync(inst(G,G))  => G                              // S5: get_response flag
G ==Bool G            => true                            // K-EQUAL
```
No `requires`; `#Top` for every `G`. Each fixed `__init__` now literally is
`self.get_response = g; self._async_check()` (= `initCorrect(flag(g))`), the
remaining attribute writes being async-irrelevant. ∎ (PO-2)

## 3. Loop circularity `(STEP)` — proof (coinduction)

Claim: `iscf(buildHandler(AMW,H,A)) ==Bool nextA(AMW) => true`
`requires iscf(H) ==Bool A`.

```
iscf(buildHandler(AMW,H,A))
  => iscf(cer(initCorrect(iscf(adapt(AMW,H,A)))))        // buildHandler   (genuine =>+ step: guardedness)
  => iscf(initCorrect(iscf(adapt(AMW,H,A))))             // S2
  => iscf(adapt(AMW,H,A))                                // S3 ∘ initCorrect: iscf(inst(X,X)) = X
  #Or-split on (A ==Bool AMW):
    true  branch: adapt => H ;  iscf(H) = A = AMW        // S4a + hypothesis iscf(H)==A
    false branch: adapt => raw(AMW) ; iscf = AMW         // S4b
  => AMW
AMW ==Bool nextA(AMW) => AMW ==Bool AMW => true          // nextA, K-EQUAL
```
The incoming invariant `iscf(H)==A` is the **coinductive hypothesis**, used once
(true-branch). It is *earned* by the genuine `buildHandler` rewrite (≥1 step)
before reuse — guardedness holds; no goal is closed by Reflexivity alone. The
Boolean case split is discharged by Z3. ∎ (PO-5)

**Composition (the chain, by Transitivity).**
- BASE: `iscf(cer(raw(true))) => true`, and `a_0 = is_async = true` in ASGI ⇒
  `flag(H_0)==a_0`.
- STEP carries `flag(H_i)==a_i` forward for each middleware (finite list).
- Hence `flag(H_i)==a_i` for all layers — `(CHAIN-INV)`. ∎

## 4. End-to-end safety `(SAFE)` — the two worlds

Two async-capable middlewares `[Outer, Inner]`, `h0 = cer(_get_response_async)`
(`flag=true`). The only difference is the Inner constructor.

| step | pre-fix (`Inner=initBuggy(true)`) | post-fix (`Inner=initCorrect(true)`) |
|---|---|---|
| `flag(Inner)` | `false` (marker unset) | `true` |
| `flag(cer(Inner))` | `false` | `true` |
| tracked `a` | `true` | `true` |
| `flag` vs `a` | **mismatch** (false≠true) | match |
| `adapt(true, cer(Inner), true)` | returns it (flag stays `false`) | returns it (flag `true`) |
| `runsAsync(Outer)` | `false` → sync path | `true` → `__acall__` |
| Outer calls inner | `cer(Inner)(req)` **not awaited** | `await cer(Inner)(req)` |
| inner result | coroutine (Inner runs async) | awaited → `HttpResponse` |
| `Outer.process_response` gets | **`coroutine`** ❌ | `HttpResponse` ✅ |

The pre-fix column reproduces the issue's
`<class 'django.core.handlers.asgi.ASGIRequest'> <class 'coroutine'>`; the
post-fix column is the intended behaviour. ∎ (PO-6)

## 5. Refutation of the pre-fix code (benefit #2)

Claim `(REFUTATION)` `iscf(initBuggy(G)) ==Bool runsAsync(initBuggy(G)) => true`
does **not** reduce to `#Top`:
```
iscf(initBuggy(G))      => iscf(inst(false,G))      => false
runsAsync(initBuggy(G)) => runsAsync(inst(false,G)) => G
false ==Bool G          => residual: ¬G            // NOT #Top
```
Residual `¬G`; counterexample `G = true`. A non-`#Top` here *is* the bug,
localized to "async handler." This is the proof-derived finding PV2.

## 6. Test-redundancy report (benefit #1) — recommendation only

Because no execution environment exists and the project's test suite is hidden
and fixed, this is advisory and **conditioned on machine-checking** (`kprove ⇒
#Top`). It recommends **no removals** — the contract is new and the regression
tests for it are valuable.

- **Keep (add, ideally):** an ASGI test asserting that with ≥2 middlewares the
  first one's `process_response` receives an `HttpResponse`, not a coroutine —
  for each of `SecurityMiddleware`, `UpdateCacheMiddleware`,
  `FetchFromCacheMiddleware`, `CacheMiddleware`. These pin `(INIT)`/`(SAFE)` and
  are the direct regression guard for F1–F4. *(Test authoring is out of scope
  here — tests are fixed/hidden — so this is a recommendation only.)*
- **Keep:** all WSGI/sync middleware tests (out of the async domain, PO-8).
- **Keep:** `cache_page`/decorator tests (F7 path, unaffected by V1).
- **Redundant:** none flagged. The fix adds a contract; it does not subsume
  existing assertions.

## 7. Residual risk

- **Constructed, not machine-checked.** No `kprove` run (MVP + no-exec
  environment). `#Top` on the claims would upgrade this to machine-verified.
- **Trusted base (S1–S5).** Adequacy of the flag abstraction and the cited
  contracts of `asyncio.iscoroutinefunction`, asgiref `Sync/AsyncToSync`,
  `convert_exception_to_response`, and `adapt_method_mode`. The real coroutine /
  `await` semantics are an **escalation boundary** (binders + concurrency),
  modeled by contract only — *not* faked as `[trusted]` claims but stated as
  named side conditions in `SPEC.md`.
- **Partial correctness.** Termination of `load_middleware` not proved (PO-9);
  it iterates a finite settings list, so this is a formality.
- **Scope.** Contract covers `MiddlewareMixin` adapters; new-style middlewares
  and the decorator path are out of domain (and unaffected).

## 8. Reproduce the machine check (would-be commands)

```sh
kompile fvk/middleware-async.k --backend haskell        # compile the fragment semantics
kast    --backend haskell fvk/middleware-async-spec.k   # (optional) confirm claims parse
kprove  fvk/middleware-async-spec.k                     # expected: #Top for (BASE),(INIT),(STEP);
                                                        #          NON-#Top for (REFUTATION) [the bug]
```
Expected: `(BASE)`, `(INIT)`, `(STEP)` ⇒ `#Top`; `(REFUTATION)` ⇒ residual `¬G`
(intentional — it encodes the pre-fix bug). **Not run here** (no toolchain /
no-exec); labeled *constructed, not machine-checked*.
