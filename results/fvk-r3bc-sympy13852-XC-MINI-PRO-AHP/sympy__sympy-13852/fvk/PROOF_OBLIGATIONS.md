# PROOF_OBLIGATIONS.md — `polylog` fix

The obligations the V2 code must discharge, each as a K reachability claim in
[`polylog-spec.k`](polylog-spec.k) over [`mini-sympy.k`](mini-sympy.k), traced to
the intent ledger in [`SPEC.md`](SPEC.md). **Constructed, not machine-checked.**

Legend: **PO** = proof obligation; provenance keys `L#`/`I#` refer to SPEC.md.

---

### PO-1 (EVAL-HALF) — Core placement obligation
**Claim:** `mkPolylog(2, oneHalf) => li2Half`, i.e. constructing
`polylog(2, Rational(1,2))` reduces — on the construction/`eval` path, with no
opt-in transform — to `-log(2)**2/2 + pi**2/12`.
**Provenance:** L1 (value), L2 (placement = bare/construction path), I1, I2.
**Why it is on `eval`, not `expand_func`:** the value is shown for the *bare*
object; the methodology names this case and forbids landing a bare-form
obligation on an opt-in path while the default path returns the old value.
**Status:** discharged by rule `eval-half`. See PROOF.md §A.

### PO-2 (EVAL-HALF-COROLLARY) — No symbolic leak
**Claim:** the construction of `polylog(2, 1/2)` never yields a symbolic
`plog(2, oneHalf)` (`li2Half ≠ plog(2, oneHalf)`).
**Provenance:** L2/L8 (reject "stays unevaluated" as an invariant), I2.
**Status:** discharged — `eval-half` fires before the `eval-frame` `[owise]`
rule, so `plog(2, oneHalf)` is unreachable from construction. See PROOF.md §A.

### PO-3 (EVAL-Z1 / ZM1 / Z0) — Legacy special-z preserved
**Claim:** `mkPolylog(S,1) => zetaE(S)`; `mkPolylog(S,-1) => Neg(detaE(S))`;
`mkPolylog(S,0) => 0`.
**Provenance:** L5, I5 (docs + public test — legacy *with* independent intent).
**Status:** discharged by `eval-z1/zm1/z0`. See PROOF.md §B.

### PO-4 (EVAL-SYM-FRAME) — No spurious evaluation
**Claim:** `mkPolylog(S, Z:Id) => plog(S, Z)` (symbolic `z`, any `s`).
**Provenance:** L7, I7 (`td(polylog(b,z),z)` needs a live symbolic polylog).
**Risk it guards:** that PO-1 might over-fire onto symbolic `z`.
**Status:** discharged by `eval-frame` `[owise]` (no specific rule matches a
symbolic `Z`). See PROOF.md §B.

### PO-5 (EXPAND-S1) — Core branch-cut obligation
**Claim:** `expandFunc(plog(1, Z)) => Neg(logE(Sub(1, Z)))`, i.e.
`expand_func(polylog(1, z)) = -log(1 - z)`, with **no `exp_polar`**.
**Provenance:** L3, I3.
**Status:** discharged by rule `expand-s1`. See PROOF.md §C.

### PO-6 (Derivative consistency, I4) — semantic side check
**Claim (English / arithmetic):** `expand_func(diff(polylog(1,z) -
expand_func(polylog(1,z)), z)) = 0`.
**Provenance:** L4, I4.
**Status:** discharged by hand (PROOF.md §C): both sides give `1/(1-z)`. This is
an arithmetic VC about derivatives, outside the rewrite model; checked directly.

### PO-7 (EXPAND-S0 / EXPAND-SYM-FRAME) — Legacy expand preserved, no leak
**Claim:** `expandFunc(plog(0, Z)) => subU(base, Z)` (= `z/(1-z)`); and
`expandFunc(plog(S:Id, Z)) => plog(S, Z)` (symbolic order unchanged, and in
particular no `exp_polar` appears anywhere).
**Provenance:** L6 (s<=0 reductions), I3/I6.
**Status:** discharged by `expand-nonpos`+`loop-base`, and `expand-frame`. See
PROOF.md §D.

### PO-8 (LOOP) — the `for _ in range(-s)` circularity
**Claim:** for all `N >= 0`, `runTheta(N, ACC) => thetaPow(N, ACC)` (the loop
terminates and applies `theta` exactly `N = -s` times).
**Provenance:** L6, I6; default-domain `range(-s)`.
**Scope honesty:** this branch is **unchanged** by the fix; the circularity
certifies it is correctly gated (integer `s <= 0`) and total on `N >= 0`. It is
a termination + iteration-count result, not a deep arithmetic identity (theta has
no simpler closed form). See PROOF.md §E.

---

## Coverage / completeness check (does the proof span the whole intent?)

| Intent | Covered by | Covered? |
|--------|-----------|----------|
| I1 value `Li_2(1/2)` | PO-1 | yes |
| I2 placement on construction path | PO-1, PO-2 | yes (the V1→V2 fix) |
| I3 `-log(1-z)`, no exp_polar | PO-5, PO-7 | yes |
| I4 derivative consistency | PO-6 | yes |
| I5 special-z preserved | PO-3 | yes |
| I6 `s<=0` reductions | PO-7, PO-8 | yes |
| I7 no spurious eval | PO-4 | yes |
| **I8 family of `Li_2` special values** | — | **partial → Finding F3** |

I8 is the only intent not fully discharged: only `Li_2(1/2)` is implemented
(the member with direct prompt evidence). Other table members are routed to
Finding F3 rather than invented. Per verify.md Step 1, this uncovered slice is
**un-audited, not proven correct**, and is recorded as an open Finding — it does
not block the reported fix but is named, not silently dropped.
