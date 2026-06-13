# PROOF — V1 fix for django__django-14011 (constructed, not machine-checked)

Constructed proof of the two claims in [`mini-server-spec.k`](mini-server-spec.k)
against [`mini-server.k`](mini-server.k), following the recipe in
fvk_materials/knowledge/reachability-and-circularities.md §4. **The MVP does not run
`kompile`/`kprove`; everything below is *constructed, not machine-checked*.**

---

## 1. What is proved (plain language)

> **For every fresh worker thread, every shared override `OV` of open in-memory
> connections, and every count `N ≥ 0` of non-shared DBs the request touches:**
> running `setOverride ; handleRequest ; closeAll` ends with the thread's connection
> set equal to `closeList(OV) mkClosed(N)` — i.e. **every shared connection preserved
> open, every non-shared connection closed, none left open-and-local** — and the
> request observed the shared connections (`C2-share`), if and when it terminates.

Termination is also immediate here (the `<own>` list strictly shrinks), so this is in
fact **total**, not merely partial, correctness for the modeled fragment.

## 2. `(CLOSEALL)` — the loop circularity

**Claim.** `⟨closeAll⟩ <own>=L <closed>=D  ⇒  ⟨.K⟩ <own>=.List <closed>=D closeList(L)`.

K makes every claim in the module a coinduction hypothesis. Proof by guarded
coinduction, case-splitting on `L`:

- **Genuine step (guardedness).** From a non-empty `<own>`, the `[closeStep]` rule
  fires — a real `=>⁺` transition — moving `ListItem(S)` out of `<own>` and appending
  `close(S)` to `<closed>`. This single step *earns* the right to reuse the hypothesis.

- **Exit branch `L = .List`.** `[closeDone]` fires: `<own>=.List`, `<k> ⇒ .K`. Post
  `<closed> = D = D closeList(.List)` since `closeList(.List)=.List`. **Lands on the
  claimed post-state.** ✔

- **Step branch `L = ListItem(S) REST`.** After `[closeStep]`: state is
  `⟨closeAll⟩ <own>=REST <closed>=D ListItem(close(S))`. Invoke the **circularity** on
  the shifted state `{D := D ListItem(close(S)), L := REST}` (legal — one genuine step
  taken). It yields `<closed> = D ListItem(close(S)) closeList(REST)`. By lemma **L1**
  (`closeList` distributes over concatenation) and the defining equation
  `closeList(ListItem(S) REST) = ListItem(close(S)) closeList(REST)`:
  `D ListItem(close(S)) closeList(REST) = D closeList(ListItem(S) REST) = D closeList(L)`.
  **Lands on the claimed post-state.** ✔

Both branches reach the post-state ⇒ `(CLOSEALL)` holds.

**VCs.** Only list-fold identities: `closeList(.List)=.List`, the cons step, and L1's
associativity of list concatenation — all structural, discharged by the
`[simplification]` lemmas in `mini-server-spec.k` (no nonlinear arithmetic; contrast the
`sum` example's even-product `/Int 2` VC, which does not arise here).

## 3. `(PRT)` — the `process_request_thread` contract (composition)

**Claim.** pre `<own>=.List ∧ allShared(OV) ∧ N≥0`; post `<own>=.List ∧ <closed> =
closeList(OV) mkClosed(N)`. Prove by Transitivity through the three statements:

1. **`setOverride`** (Axiom): `<own> .List ⇒ OV`. Now `<own> = OV`.
2. **`handleRequest`** (Axiom, `requires N≥0`): appends `mkLocals(N)`. Now
   `<own> = OV mkLocals(N)`.
   - *Side note for `C2-share`:* `OV` is already in `<own>` at this step, so the request
     reads the shared conns rather than minting new ones. This is the program-order
     argument for PO4 — it needs only Transitivity (`setOverride` before `handleRequest`),
     no loop.
3. **`closeAll`** (the `(CLOSEALL)` circularity used as a **lemma**, instantiated at
   `L := OV mkLocals(N)`, `D := .List`): reaches `<own>=.List`,
   `<closed> = .List closeList(OV mkLocals(N)) = closeList(OV) closeList(mkLocals(N))`
   (lemma **L1**) `= closeList(OV) mkClosed(N)` (lemma **L3**). ∎

**Consequence / arithmetic.** `N ≥ 0` is the only numeric side condition; `mkLocals`,
`mkClosed`, and the `N -Int 1 ≥ 0` recursion guards are linear and fall to Z3. No
map-extensionality lemma is needed (the postcondition is a `<closed>` list equality, not
a `result <- V` map pin).

## 4. The fix corollary (mapping the math back to the bug)

`close(openShared)=openShared` and `close(openLocal)=closed`, so:

- `closeList(OV)` — since `allShared(OV)` (SPEC P3) — is **`OV` unchanged**: every shared
  in-memory connection stays open ⇒ **the in-memory DB survives** (C2-preserve, PO3).
- `mkClosed(N)` is `N` × `closed`: **every non-shared connection the request opened is
  closed** (C1, C3, PO2).
- The union contains **no `openLocal`** ⇒ no thread-local DB connection leaks past the
  request. Summed over all worker threads and the server thread (PO6), no open non-shared
  connection survives to teardown ⇒ `destroy_test_db()` no longer races into
  `OperationalError: database … is being accessed by other users`. **The root cause is
  removed.**

## 5. Test-redundancy report (benefit 1) — *conditioned on machine-checking*

This audit may not edit tests, and the proof is **constructed, not machine-checked**, so
**nothing is recommended for removal**; the mapping is advisory only.

- A unit test asserting *"after a LiveServer request, `ThreadedWSGIServer._close_connections`
  was called"* is **subsumed** by `(PRT)`/PO1 once machine-checked — `close_request` always
  calls it. **Keep until `kprove` returns `#Top`.**
- A test asserting *"an in-memory-SQLite LiveServerTestCase view sees rows created by the
  test"* is subsumed by `(PRT)`/C2 (PO3+PO4). **Keep until machine-checked.**
- **Always keep** (outside the verified single-thread domain or below partial correctness):
  - **concurrency / load** tests against the live server (PO8 / F5 escalation boundary);
  - **termination / hang** tests of `serve_forever`/`terminate` (not modeled);
  - **integration / end-to-end** Selenium-style `LiveServerTestCase` tests (wiring, not unit);
  - any test exercising a **custom `server_class` / `_create_server` override** (F4 contract).

Estimated CI saving: negligible and not claimed — the value of this fix is correctness
(benefit 2), not test deletion.

## 6. Proof-derived findings (fed to FINDINGS.md / ITERATION_GUIDANCE.md)

- The proof **needed** `allShared(OV)` as a precondition (step 3 / corollary). That is the
  implicit contract on `connections_override` surfaced as **F2** — a precondition the code
  *relies on* and the in-tree caller satisfies, but does not state. → ITERATION_GUIDANCE Q1.
- The clean single-trace proof **only exists per-thread**; the multi-thread version has no
  clean `[all-path]` contract → **F5 / PO8 escalation boundary**. → ITERATION_GUIDANCE Q2.
- No proof obstacle indicated a code bug; the obstacles were a *precondition to document*
  and a *capability boundary*, not a defect. Hence **V1 stands** (see FINDINGS summary).

## 7. Residual risk

- **Constructed, not machine-checked.** Upgrade by running the §6/SPEC commands; success is
  `kprove … ⇒ #Top`.
- **Trusted base:** adequacy of the mini-X fragment (it abstracts the socket, the SQL layer,
  and—deliberately—concurrency); the reachability metatheory + `kprove`; the Z3 /
  `[simplification]` oracle for the list-fold lemmas L1–L3.
- **Partial vs total:** total for the modeled fragment (the `<own>` list strictly shrinks);
  the *unmodeled* `serve_forever` loop's termination is out of scope (handled operationally
  by `terminate()` → `shutdown()`).
- **Concurrency (PO8/F5):** the one genuinely open obligation, routed to sources, not faked.

## 8. Reproduce the machine check

```sh
cd fvk
kompile mini-server.k --backend haskell
kast    --backend haskell mini-server-spec.k     # optional parse check
kprove  mini-server-spec.k                        # expect: #Top  (both claims discharged)
```
