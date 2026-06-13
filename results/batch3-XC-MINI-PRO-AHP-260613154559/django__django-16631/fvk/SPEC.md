# SPEC — django__django-16631 (FVK formalization of the V1 fix)

**Status:** constructed, not machine-checked (no `kompile`/`kprove` run — no
execution environment). The Findings (FINDINGS.md) and the
input → observed vs expected reasoning are independent of machine-checking and
hold today.

K artifacts produced alongside this note:
- `fvk/mini_auth.k` — the mini-X fragment semantics.
- `fvk/mini_auth-spec.k` — the reachability claims `(HASH-EQ)`, `(SCAN-LOOP)`,
  `(GETUSER)`.

---

## 1. Intent (from PROBLEM.md + public hints)

`SECRET_KEY_FALLBACKS` must keep **sessions** valid across a `SECRET_KEY`
rotation, exactly as it already does for password-reset tokens. Concretely:

- **I1 — Fallback acceptance.** A user whose session cookie carries an
  `_auth_user_hash` that was computed with a key now sitting in
  `SECRET_KEY_FALLBACKS` (typically the *previous* `SECRET_KEY`) must **stay
  logged in**, not be flushed to `AnonymousUser`.
- **I2 — No-op when nothing matches.** If the stored hash matches neither the
  current key nor any fallback (or is absent), behavior must be unchanged from
  before: flush the session and return `AnonymousUser`.
- **I3 — Upgrade-on-fallback (the hint).** When a fallback hash validates a
  session, the cookie should be **upgraded** to the current-key hash, so that
  removing the fallback later does **not** invalidate the session a second time.
- **I4 — Backward compatibility.** Cookies minted *before* the fix (current-key
  hashes) must continue to validate unchanged.
- **I5 — Security parity.** Comparisons stay constant-time per candidate
  (`constant_time_compare`), mirroring `PasswordResetTokenGenerator.check_token`.

The "as-built V0" (pre-fix) behavior is the bug: it keeps a user iff the stored
hash equals the **current-key** hash only — so rotation logs everyone out.

## 2. Units formalized (functions and loops in the changed code)

| Unit | Location (V1) | Kind |
|---|---|---|
| `_get_session_auth_hash(secret=None)` / `get_session_auth_hash()` | `base_user.py:135,145` | pure function |
| `get_session_auth_fallback_hash()` | `base_user.py:141` | generator (a loop over `SECRET_KEY_FALLBACKS`) |
| `get_user()` verification block | `__init__.py:200-221` | function fragment containing the `any(...)` search loop |

The `any(... for ... in get_session_auth_fallback_hash())` expression is the
**loop** to formalize; the `get_user` block is the **function contract**.

## 3. The mini-X semantics (`mini_auth.k`)

A minimal imperative fragment: a `<store>` map, a symbolic `<secret>` cell
(`SECRET_KEY`), assignment, `if/else`, one `while`, short-circuit `and`/`or`,
value/boolean equality (modeling `constant_time_compare` on hex digests), list
helpers (`head`/`tail`/`notEmpty`), and two opaque symbols:

- `H3(salt, pwd, secret)` — the opaque result of
  `salted_hmac(salt, pwd, secret=…).hexdigest()`; a K **constructor**, hence
  injective ⇒ "different secret ⇒ different hash".
- `resolve(secret)` — `salted_hmac`'s `if secret is None: secret = SECRET_KEY`
  defaulting. `eps` in secret position is that `None`; `resolve(eps) = SK`.

`eps` doubles as the empty/absent stored hash (Python `None`/`""`, i.e. the
`if not session_hash:` case). `inList(H, FB)` is a **spec-only abstraction**
(membership of `H` in the fallback-hash list) defined by the two equations a
single scan step produces.

## 4. The claims (`mini_auth-spec.k`)

### (HASH-EQ) — backward compatibility / refactor faithfulness  → I4
Both the V1 path (`_get_session_auth_hash()` → `salted_hmac(salt, pwd,
secret=None)`) and the pre-fix path (`salted_hmac(salt, pwd)`, `secret`
omitted) reduce, via `resolve(eps) = SK`, to the *same* term `H3(SALT,PWD,SK)`.
**Plain English:** the refactor does not change a single existing session hash,
so no currently-valid cookie is invalidated by deploying the fix.

### (SCAN-LOOP) — the fallback search, as a loop circularity  → I1
Generalized over accumulator `found = F` and the remaining list `fb = FB`:
running the scan leaves `found = F or inList(H, FB)` and `fb = .List`.
The closed form (the role the classical invariant plays) is
`F or inList(H, FB)`. With the real entry state `F = false`, the result is
exactly `inList(H, FB)` — "does any fallback-key hash equal the stored hash".
No counter side condition is required: the `List` recurses structurally to
`.List`; finiteness is given by the sort.

### (GETUSER) — the verification contract  → I1, I2, I3
For stored hash `H`, current-key hash `HC`, and fallback-hash list `FB`:

| precondition | outcome | resulting cookie `stored` |
|---|---|---|
| `H ≠ eps ∧ H = HC` | `KEEP` | `HC` (unchanged) |
| `H ≠ eps ∧ H ≠ HC ∧ inList(H, FB)` | `UPGRADE` | `HC` (rewritten; key cycled) |
| `H = eps ∨ (H ≠ HC ∧ ¬inList(H, FB))` | `FLUSH` | `eps` (session flushed, user `None`) |

**Headline property:** the user is kept (`KEEP ∨ UPGRADE`) **iff**
`H ≠ eps ∧ H ∈ {HC} ∪ FB`; and a fallback validation **upgrades** the cookie to
`HC`. Substituting `FB = []` collapses this to the pre-fix contract "kept iff
`H ≠ eps ∧ H = HC`" — the backward-compatible reduction (I2/I4).

## 5. Linking the abstraction back to the code

`get_session_auth_fallback_hash()` yields `H3(SALT, PWD, resolve(fb_i)) =
H3(SALT, PWD, fb_i)` for each `fb_i ∈ SECRET_KEY_FALLBACKS`. So `FB =
[H3(SALT,PWD,fb_i)]`. A pre-rotation cookie holds `H3(SALT,PWD, old_key)` where
`old_key` is now a fallback ⇒ that exact term is in `FB` ⇒ `inList(H, FB)` is
true ⇒ `(GETUSER)` yields `UPGRADE`. This is precisely intent **I1+I3** and is
why the fix resolves the reported logout-on-rotation.

## 6. Trusted base / abstraction boundary

- `salted_hmac`/`constant_time_compare`/HMAC are modeled abstractly: `H3` is an
  injective constructor and equality is exact. We verify the **control/data flow
  of the fix**, not HMAC cryptography or the timing side-channel (addressed as a
  Finding, not proved).
- `inList`'s two defining equations are spec vocabulary (definitional), the
  analogue of the sum example trusting its arithmetic `[simplification]` lemmas.
- Partial correctness (default): correctness *if* the scan terminates;
  termination is a recommendation (PROOF_OBLIGATIONS PO8) — trivially true since
  `SECRET_KEY_FALLBACKS` is a finite list.
- Adequacy of the mini-X fragment, the reachability metatheory, and the
  SMT/`[simplification]` oracle are trusted; nothing is `[trusted]`-faked.
