# PROOF — django__django-16631 (V1 fix), constructed

**Honesty gate:** the proof below is **constructed by symbolic execution against
`fvk/mini_auth.k`, NOT machine-checked.** No `kompile`/`kprove` was run (no
execution environment). Run-commands to upgrade it to machine-checked are in §5.
The Findings (FINDINGS.md) do not depend on machine-checking.

Discharges PROOF_OBLIGATIONS PO1–PO10 against the three claims in
`fvk/mini_auth-spec.k`.

---

## 1. (HASH-EQ) — backward compatibility  [PO1, PO10]

Symbolic execution of the two-assignment program:
```
new = H3(SALT, PWD, resolve(eps)) ;   // _get_session_auth_hash(secret=None)
old = H3(SALT, PWD, resolve(eps)) ;   // pre-fix salted_hmac(salt,pwd) [secret omitted]
```
- `resolve(eps)` fires `rule resolve(eps) => SK` (read `<secret> SK </secret>`),
  on both lines. Each RHS becomes the value `H3(SALT,PWD,SK)`.
- Two assignment steps store it: `<store> … new |-> H3(SALT,PWD,SK)
  old |-> H3(SALT,PWD,SK) …`.
- The post-store implication closes via the map-extensionality
  `[simplification]` `{ M[K<-V] #Equals M[K<-V'] } => { V #Equals V' }`,
  reducing each cell equality to `H3(SALT,PWD,SK) #Equals H3(SALT,PWD,SK)`,
  which is `#Top` by REFL. ∎

**PO10** is the same reduction with `eps` replaced by a fallback key `fb_i`:
`resolve(fb_i) => fb_i` (the `V =/=K eps` rule), so the i-th yielded hash is
`H3(SALT,PWD,fb_i)`. Hence `FB = [H3(SALT,PWD,fb_i) | fb_i ∈ FALLBACKS]`.

> **Why it matters (plain language):** deploying the fix changes *no* existing
> session hash. A user with a valid current-key cookie is unaffected; only the
> *additional* fallback acceptance is new. Had the refactor altered the digest
> (e.g. by defaulting `secret` to something other than `SECRET_KEY`), it would
> have re-created the mass logout the ticket reports — so this is the keystone.

## 2. (SCAN-LOOP) — fallback search circularity  [PO7]

Goal: from `found = F`, `fb = FB`, `h = H`, the loop reaches `found = F or
inList(H, FB)`, `fb = .List`.

K makes the claim its own coinduction hypothesis. The `while` desugars to
`if (notEmpty(fb)) { body while … } else { }`; evaluating `notEmpty(fb)` is the
genuine `=>⁺` step that earns the hypothesis (guardedness). **Case-split** on it:

- **Exit (`fb = .List`):** `notEmpty(.List) => notBool(.List ==K .List) =>
  false`; the `else {}` ends the loop. `inList(H, .List) => false` (DEF), and
  `F orBool false = F` (Z3). Post-state `found = F`, `fb = .List`. ✓
- **Body (`fb = ListItem(X) Rest`):** `notEmpty => true`; run the body:
  `found = found or (head(fb) == h)` evaluates `head(ListItem(X) _) => X`,
  `X == H => X ==K H`, and `found` (=`F`) `or (X==H)`; then
  `fb = tail(ListItem(X) Rest) => Rest`. Now **invoke the circularity** on the
  shifted state `{found := F orBool (X==H), fb := Rest}` (legal — one genuine
  step taken). It yields `found = (F or (X==H)) or inList(H, Rest)`.
  **Consequence/VC:** show
  `(F or (X==H)) or inList(H, Rest)  =  F or inList(H, ListItem(X) Rest)`.
  Unfold the RHS with the cons equation `inList(H, ListItem(X) Rest) => (X==H)
  or inList(H, Rest)` (DEF); both sides are then `F or ((X==H) or inList(H,
  Rest))` modulo `or`-associativity/commutativity — `#Top` by Z3. ✓

No counter side condition is needed (structural recursion of `List` to `.List`);
no nonlinear or inductive-predicate VC arises — the membership recursion is
discharged purely by `inList`'s definitional equations + Boolean SMT, so this
stays inside the bundled tier (contrast: sortedness/permutation would not). ∎

## 3. (GETUSER) — verification contract  [PO2–PO6, PO9]

Compose by Transitivity, driving the `<k>` cell:

1. `verified = false ;` → `<store> … verified |-> false …`.
2. `if (h != eps) { verified = (h == hc) ; } else { }` — case-split on
   `H ==K eps`:
   - `H = eps`: false-branch, `verified` stays `false`.
   - `H ≠ eps`: `verified := (H ==K HC)`.
3. `if (not verified) { … } else { stored = h ; outcome = KEEP ; }` — case-split:
   - **verified = true** (only reachable when `H ≠ eps ∧ H = HC`): take the
     `else`. `stored := H` and (since `H = HC`) `stored = HC`; `outcome := KEEP`.
     ⇒ first postcondition disjunct. **[KEEP case]**
   - **verified = false** (`H = eps`, or `H ≠ eps ∧ H ≠ HC`): enter the block.
     `found = false ;` then `if (h != eps) { scan } else { }`:
     - `H = eps`: skip the scan, `found = false`.
     - `H ≠ eps`: run the scan; **use `(SCAN-LOOP)` as a lemma** at
       `{found := false, fb := FB0}` ⇒ `found = false or inList(H, FB0) =
       inList(H, FB0)`.
     Then `if (found) { stored = hc ; outcome = UPGRADE ; } else { stored = eps ;
     outcome = FLUSH ; }`:
     - `found = true` (⇒ `H ≠ eps ∧ inList(H, FB0)`, and here `H ≠ HC` since
       verified was false): `stored := HC`, `outcome := UPGRADE`. ⇒ second
       disjunct. **[UPGRADE case]**
     - `found = false` (⇒ `H = eps`, or `H ≠ HC ∧ ¬inList(H, FB0)`):
       `stored := eps`, `outcome := FLUSH`. ⇒ third disjunct. **[FLUSH case]**

The three branch conditions are mutually exclusive and exhaustive; the disjoined
postcondition (`ensures …`) is exactly their union, closed by Z3 (pure Boolean
reasoning over `H ==K eps`, `H ==K HC`, `inList(H, FB0)`). ∎

- **PO2** (keep ⟺ `H ≠ eps ∧ H ∈ {HC} ∪ FB`): KEEP∨UPGRADE ⟺ `(H≠eps ∧ H=HC) ∨
  (H≠eps ∧ H≠HC ∧ inList(H,FB0))` ⟺ `H≠eps ∧ (H=HC ∨ inList(H,FB0))`. ✓
- **PO3** (upgrade target): UPGRADE sets `stored = HC`, the current-key hash. ✓
- **PO5** (`FB0 := []`): `inList(H, []) = false` removes the UPGRADE disjunct ⇒
  keep ⟺ `H ≠ eps ∧ H = HC` = pre-fix contract. ✓
- **PO6** (`H := eps`): step 2 leaves `verified=false`; the inner `if (h!=eps)`
  is false ⇒ scan skipped ⇒ `found=false` ⇒ FLUSH, `stored=eps`. ✓
- **PO9** (convergence): feed `[UPGRADE case]`'s `stored = HC` back as the next
  run's `H`; then `H = HC ≠ eps` ⇒ `verified=true` ⇒ **KEEP**, no scan, no
  re-cycle. One cycle per session; fallback removal afterwards is safe. ✓

## 4. PO4 — no `UnboundLocalError` (control-flow lemma)

Not a reachability VC but a definite-assignment/dominance argument over the
actual Python (mirrored by the mini-X branch structure): the sole read of
`session_auth_hash` (`__init__.py:218`) is dominated by `if session_hash and
any(...)`. `session_hash` is the same value tested by `if not session_hash` that
guards the *only* assignment (line 205). On any path that skipped the
assignment, `session_hash` is falsy, so `session_hash and …` short-circuits to
`False` and line 218 is unreachable. Hence the read is dominated by the
assignment on every executable path. ∎ (Load-bearing: depends on the conjunct
order — see FINDINGS F2 / ITERATION_GUIDANCE.)

## 5. Reproduce the machine check

```sh
kompile fvk/mini_auth.k --backend haskell        # compile the fragment semantics
kast    --backend haskell fvk/mini_auth-spec.k    # (optional) confirm claims parse
kprove  fvk/mini_auth-spec.k                       # expected: #Top for all 3 claims
```
Expected result: `#Top` (HASH-EQ, SCAN-LOOP, GETUSER all discharged). Until then
the proof is **constructed, not machine-checked**.

## 6. Test-redundancy recommendation (benefit 1) — recommendation only

Conditioned on the machine check above returning `#Top`. The project test suite
is **fixed and hidden** here; this is advisory and **nothing is deleted**. By
*kind*:

- **Subsumed-if-proved (in-domain points of `(GETUSER)`/`(HASH-EQ)`):** any unit
  test asserting a single concrete input/output of the keep/upgrade/flush
  decision — e.g. "current-key cookie ⇒ stays logged in" (PO1+KEEP),
  "fallback-key cookie ⇒ stays logged in" (UPGRADE/PO2), "no-match ⇒ logged out"
  (FLUSH), "empty fallbacks ⇒ logged out" (PO5), "empty hash ⇒ logged out"
  (PO6) — is a point on the proven contract. *Recommend keeping until `kprove`
  is actually run*, then these become candidates for consolidation.
- **Always keep:** the **upgrade/convergence** test (PO9 — that the cookie is
  rewritten and a removed fallback doesn't re-invalidate) pins the I3 behavior
  and is cheap insurance; any test for the **F4 duck-typed** path (out of the
  verified domain — a custom user lacking `get_session_auth_fallback_hash`); the
  **constant-time** intent (F6, a timing property outside the functional spec);
  any **`login()`** session-fixation test (F7, deliberately out of scope);
  termination/perf and integration/middleware end-to-end tests.

Net: **no test removal is asserted** (suite hidden + proof not machine-checked).

## 7. What's proved / residual risk

**Proved (constructed):** for every stored hash `H`, current-key hash `HC`, and
fallback-hash list `FB`, `get_user` keeps the user iff `H ≠ eps ∧ H ∈ {HC}∪FB`,
upgrading the cookie to `HC` on a fallback-only match; the `base_user` refactor
preserves the legacy digest; `FB=[]` and `H=eps` reduce to pre-fix behavior; the
rotation converges in one request.

**Residual risk:** (a) *constructed, not machine-checked* — §5 closes this;
(b) *partial correctness* — termination (PO8) is a trivial recommendation;
(c) *trusted base* — `H3`/`constant_time_compare`/HMAC modeled abstractly (we
verify control/data flow, not cryptography or the timing side-channel, F6),
`inList`'s defining equations are spec vocabulary, and the mini-X fragment's
adequacy + the reachability metatheory + the SMT oracle are trusted;
(d) *F4* — duck-typed non-`AbstractBaseUser` users (accepted, see FINDINGS).
Nothing is faked `[trusted]`; no `[ESCALATION BOUNDARY]` was needed.
