# FINDINGS.md — `nthroot_mod` (sympy__sympy-18199)

Plain-language findings, each as `input → observed vs expected`. Findings from
`/formalize` (writing the spec) first, then proof-derived findings from `/verify`.
Severity: **[BUG]** real defect · **[POSITIVE]** code already does the right thing ·
**[OUT-OF-SCOPE]** real but unrelated to issue #18199, reported not fixed · **[NOTE]** info.

---

## F1 — [BUG, FIXED BY V1] The root `x = 0` was missing / the call crashed when `a % p == 0`

The defect named by the issue (ledger L1–L3). For prime `p`, when `a % p == 0` the equation
`x**n ≡ a (mod p)` has the single root `0`, but the pre-fix code never accounts for it.
Formalizing made the failure **taxonomy** precise — the pre-fix behavior depends on which
solving path the input lands in (recall the final `pa` of the gcd loop is
`gcd(n, p-1)`, since that loop is the Euclidean algorithm on the *exponents*, independent
of `a`):

| input (`a` with `a%p==0`) | path taken (pre-fix) | observed (pre-fix) | expected |
|---|---|---|---|
| `nthroot_mod(11, 5, 11)` | `(p-1)%n==0` → `_nthroot_mod1(0,5,11)` | **`ValueError: Log does not exist`** (`discrete_log(11,0,h)`, line 1060) | `0` / `[0]` |
| `nthroot_mod(13, 9, 13)` | gcd path, `gcd(9,12)=3>2` → `_nthroot_mod1(0,3,13)` | **`ValueError: Log does not exist`** | `0` / `[0]` |
| `nthroot_mod(17*17, 5, 17)` | gcd path, `gcd(5,16)=1` | `0` *(accidentally correct)* | `0` / `[0]` |

- observed: a real input (`11,5,11` or `13,9,13`) **raises** instead of returning the root;
  the issue's own example (`289,5,17`) only "works" by luck of `gcd(n,p-1)=1`.
- expected (ledger L1,L2,L4): `0` (all_roots=False) / `[0]` (all_roots=True), the complete
  root set.
- **Resolution (V1, residue_ntheory.py:779–781):** short-circuit `a % p == 0` to `[0]`/`0`
  *before* either solver path. Verified by `CLAIM-ZERO` + `PO-ROOT`, `PO-ONLY` (see
  `PROOF_OBLIGATIONS.md`). Robust across **all** sub-cases above, not just the lucky one.

## F2 — [POSITIVE] The branch's two preconditions are *enforced upstream*

Writing `CLAIM-ZERO` forced two preconditions: `isPrime(P)` and `N ≥ 1`. Both are guaranteed
by guards that run *before* the new branch — a classic "guard enforces the precondition the
spec needs" positive finding:

- `isPrime(P)`: line 776 (`if not isprime(p): raise`) executes before line 779. Composite `p`
  can never reach the branch → Euclid's lemma (which is *false* for composite `p`,
  e.g. `2**2 ≡ 0 (mod 4)`, `x=2≠0`) is never relied upon out of domain. *(input `nthroot_mod(0,3,4)`
  → raises `NotImplementedError`, preserved, see F6.)*
- `N ≥ 1`: `is_nthpow_residue` rejects `n < 0` (`ValueError`, line 634); `n == 0` returns via
  the `n==0` branch (line 637) giving `a==1`, which is `False` when `a%p==0` (`a` a multiple of
  prime `p` is never `1`) → `nthroot_mod` returns `None` before the branch; `n == 2` returns via
  `sqrt_mod` (line 771) before the branch. Hence every input reaching the branch has
  `n ∈ {1,3,4,5,…}`, all `≥ 1`. Confirms `PO-PRIME`, `PO-NGE1`.

## F3 — [POSITIVE/NOTE] `n == 2` is consistent with the new branch

`n == 2` is delegated to `sqrt_mod` (line 771) *before* the guard chain. For `a % p == 0`,
`sqrt_mod_iter` (lines 323–326) routes to `_sqrt_mod1(0, p, 1)`, which yields exactly `[0]`.
- input `nthroot_mod(0, 2, 7, True)` → `[0]`; `nthroot_mod(0, 2, 7)` → `0`.
- Same answer as `CLAIM-ZERO` would give → the whole function is **uniform** on `a ≡ 0`
  across all `n`. No change needed; this justifies *not* moving the new guard above the
  `n==2` line (doing so would also wrongly bypass the composite-`p` raise — see F6).

## F4 — [OUT-OF-SCOPE, pre-existing] `n == 1` does not reduce `a` modulo `p`

- input `nthroot_mod(20, 1, 7)` → observed `20`; expected `6` (`20 ≡ 6 mod 7`); the root is
  mathematically correct as a representative but is **not** in canonical `[0, p)` like every
  other branch returns. Cause: the `(p-1)%n==0` path calls `_nthroot_mod1(a,1,p)` →
  `_nthroot_mod2` → returns `s = a` unreduced.
- **Unrelated to #18199** (only triggers for `a % p != 0`, the *complement* of the fix).
  Not fixed: out of scope, and the change must stay minimal. The fix's own `a%p==0`,`n==1`
  sub-case *is* correct (`nthroot_mod(7,1,7)` → `0`, since the new branch fires first).

## F5 — [OUT-OF-SCOPE, pre-existing] `n == 0` raises `ZeroDivisionError`

- input `nthroot_mod(1, 0, 7)` → observed `ZeroDivisionError` at `(p - 1) % n` (line 783);
  expected: outside the documented domain ("n : positive integer"). For `a % p == 0`, `n==0`
  is already short-circuited to `None` by `is_nthpow_residue` (F2), so the fix never meets it.
- **Unrelated to #18199**; not fixed (out-of-domain input; minimal-change discipline).

## F6 — [POSITIVE] Composite-`p` contract preserved

- input `nthroot_mod(0, 5, 12)` → still `NotImplementedError` (line 777), because the new
  guard sits *after* the `isprime` check. The fix does not silently start "supporting" a
  case the function never supported. Confirms frame obligation `PO-FRAME-COMPOSITE`.

---

## Proof-derived findings (from `/verify`)

## PF1 — [POSITIVE] The single VC discharges cleanly; the spec is *clean*

`CLAIM-ZERO`'s only nontrivial VC is `roots(A,N,P) = {0}`. It splits into two elementary,
universally-true facts (`PO-ROOT`, `PO-ONLY`) with **no awkward case split and no invented
side condition** beyond the two preconditions that are already enforced (F2). A clean spec
that proves with no residue is positive evidence the fix is right (benefit-2 in reverse).

## PF2 — [NOTE / ESCALATION BOUNDARY] `roots = {0}` rests on Euclid's lemma

`PO-ONLY` (`P prime ∧ N≥1 ∧ P|X^N ⟹ X≡0 mod P`) is Euclid's lemma — trivial mathematics,
but a *machine* proof in K needs an inductive primality theory (induction on `N`). Marked
`[ESCALATION BOUNDARY]` for the toolchain; discharged **by hand** in `PROOF.md`. Honesty
gate: not admitted as `[trusted]`, and the kit is not claimed to have machine-checked it.

## PF3 — [NOTE] Return-type consistency holds

`CLAIM-ZERO` returns `0:Int` (all_roots=False) and `ListItem(0)` i.e. `[0]:List` (True),
matching the shapes returned by every other branch (`a:Int` / sorted `List`). No type
inconsistency. Confirms `PO-SHAPE`.

## PF4 — [NOTE] Test impact

Existing suite is unaffected (`PO-REGRESSION`): the exhaustive loop uses `range(1, p-1)`
(never `a ≡ 0`), and every explicit case at `test_residue.py:166–174` has `a % p != 0` or is
the `n==2`/composite path. A test that pins `a ≡ 0` (e.g. `nthroot_mod(17*17,5,17,True)==[0]`)
is *newly satisfied* by V1; see `ITERATION_GUIDANCE.md` for the recommended additions.
