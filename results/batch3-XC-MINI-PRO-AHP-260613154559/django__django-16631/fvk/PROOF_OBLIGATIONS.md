# PROOF OBLIGATIONS — django__django-16631 (V1 fix)

Discrete obligations that together establish V1 correct against `fvk/SPEC.md`.
Each lists the claim it belongs to, the discharge method, and status. Tier:
**Z3** = linear/Boolean SMT; **DEF** = definitional unfolding (`inList`,
`resolve`); **CIRC** = loop circularity (coinduction); **REFL** = reflexivity.
All "discharged" results are **constructed, not machine-checked** (see PROOF.md).

| PO | Statement | Claim | Tier | Status |
|---|---|---|---|---|
| PO1 | `get_session_auth_hash()` (V1) computes the *same* digest as the pre-fix code for the current `SECRET_KEY`: both reduce to `H3(SALT,PWD,SK)`. | (HASH-EQ) | DEF+REFL | ✅ discharged |
| PO2 | In `get_user`, the user is kept (`KEEP`∨`UPGRADE`) **iff** `H ≠ eps ∧ H ∈ {HC} ∪ FB`. | (GETUSER) | CIRC+Z3+DEF | ✅ discharged |
| PO3 | A fallback-only match yields `UPGRADE` with `stored = HC` (current-key hash), never leaving the old hash in place. | (GETUSER) | Z3 | ✅ discharged |
| PO4 | No `UnboundLocalError`: every read of `session_auth_hash` is dominated by an assignment. (Line 218 read is guarded by `session_hash and …`, falsy exactly when line 205's assignment was skipped.) | (GETUSER) control-flow | REFL (dominance) | ✅ discharged |
| PO5 | Backward-compat reduction: with `FB = []`, `(GETUSER)` collapses to the pre-fix contract "kept iff `H ≠ eps ∧ H = HC`". | (GETUSER)[FB:=[]] | DEF+Z3 | ✅ discharged |
| PO6 | Empty stored hash: `H = eps ⇒ FLUSH ∧ stored = eps`, and the fallback generator is **not** evaluated. | (GETUSER)[H:=eps] | Z3 | ✅ discharged |
| PO7 | `(SCAN-LOOP)` computes membership: from `found = F`, the loop ends with `found = F or inList(H, FB)` and `fb = .List`. | (SCAN-LOOP) | CIRC+Z3+DEF | ✅ discharged |
| PO8 | Termination of the scan (total correctness of the loop). | (SCAN-LOOP) | measure `size(fb)` | ⚠️ recommendation only (partial-correctness default); trivially holds — `SECRET_KEY_FALLBACKS` is a finite `list`. |
| PO9 | Convergence/idempotence: after one `UPGRADE`, subsequent `get_user` calls on the same cookie take `KEEP` (no repeated `cycle_key`), and removing fallbacks does not re-invalidate. | (GETUSER) composed twice | Z3 | ✅ discharged |
| PO10 | `get_session_auth_fallback_hash()` yields exactly `H3(SALT,PWD,fb_i)` for each `fb_i ∈ SECRET_KEY_FALLBACKS` (the abstraction-to-code link that makes PO2 bite on real cookies). | (HASH-EQ)-style | DEF (`resolve`) | ✅ discharged |

---

## Detail on the non-trivial obligations

### PO1 (HASH-EQ) — backward compatibility
`_get_session_auth_hash(secret=None)` passes `secret=None` to `salted_hmac`,
which sets `secret = settings.SECRET_KEY`. The pre-fix `get_session_auth_hash`
omitted `secret`, i.e. also `None`. Both ⇒ `H3(SALT, PWD, resolve(eps))`, and
`resolve(eps) ⇒ SK` (mini_auth.k). Two syntactically equal terms ⇒ equality by
`#Equals`/REFL after the map-extensionality `[simplification]` reduces the
cell equality to a scalar one. **Risk if violated:** every existing session
invalidated on deploy (the ticket's own symptom) — so this PO is the keystone.

### PO2 / PO7 — the search loop and the keep-predicate
`(SCAN-LOOP)` is discharged by guarded coinduction:
- **guard step** `notEmpty(fb)` (a genuine `=>⁺`) earns the circularity;
- **case split** (`#Or`): `fb = .List` (exit) gives `inList(H, .List) = false`,
  so `found' = F` ✓; `fb = ListItem(X) Rest` runs one body
  (`found := F or (X==H)`, `fb := Rest`), then **invokes `(SCAN-LOOP)` on the
  shifted state** giving `found' = (F or (X==H)) or inList(H, Rest)`. The cons
  equation `inList(H, ListItem(X) Rest) = (X==H) or inList(H, Rest)` plus
  `or`-associativity (Z3) closes it to `F or inList(H, ListItem(X) Rest)` ✓.
`(GETUSER)` then uses `(SCAN-LOOP)` as a lemma at entry `{found:=false}`, giving
`found = inList(H, FB0)` on the scanned branch, and the surrounding `if`s
produce the three-way postcondition. The keep-predicate `H ≠ eps ∧ (H = HC ∨
inList(H, FB0))` is pure Boolean/Z3 from the branch conditions.

### PO4 — definedness (the subtle one)
Treat `session_auth_hash` as a variable with a definite-assignment lattice. It
is assigned on the `else` branch of `if not session_hash`. The only later use is
line 218, dominated by `if session_hash and any(...)`. On the path where the
assignment was skipped, `session_hash` is falsy, so `session_hash and …` is
`False` and line 218 is not reached. Hence every use is dominated by an
assignment ⇒ no `UnboundLocalError`. This is a control-flow/dominance fact, not
arithmetic; it is **why the conjunct order matters** (see FINDINGS F2).

### PO5 / PO6 — degenerate reductions (backward compatibility + empty hash)
Both are obtained by substitution into the proven `(GETUSER)` postcondition:
`FB := []` makes `inList(H, [])` ⇒ `false`, dropping the `UPGRADE` disjunct, so
keep ⟺ `H ≠ eps ∧ H = HC` (pre-fix). `H := eps` forces the first `if`
false-branch (`verified := false`), then the inner `if (h != eps)` false-branch
skips the scan entirely, so `found = false` ⇒ `FLUSH`, matching the code's
`session_hash and any(...)` short-circuit (the generator is never called).

### PO8 — termination (recommendation only)
Default is partial correctness. Total correctness would add the measure
`size(fb)`, strictly decreasing (one `tail` per iteration) and bounded below by
`0`. It holds trivially because `SECRET_KEY_FALLBACKS` is a finite Python
`list`; flagged as a recommendation per FVK, not required for the fix.

### PO9 — convergence (the hint's concern, made an obligation)
Compose `(GETUSER)` with itself. Run 1 on a fallback-only cookie ⇒ `UPGRADE`,
`stored := HC`. Run 2 has `H := HC` ⇒ first `if` yields `verified := (HC == HC)
= true` ⇒ `KEEP`, no scan, no `cycle_key`. Therefore exactly one key-cycle per
session during rotation, and once `stored = HC` the later removal of fallbacks
leaves the cookie valid. Discharges intent I3.
