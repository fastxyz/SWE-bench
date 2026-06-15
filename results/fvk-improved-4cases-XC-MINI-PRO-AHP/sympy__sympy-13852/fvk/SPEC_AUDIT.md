# SPEC_AUDIT — formal English vs. intent

Claim-by-claim comparison of `FORMAL_SPEC_ENGLISH.md` against `INTENT_SPEC.md`.
Verdicts: **pass** (entailed by public intent / named default), **fail**
(candidate/legacy-derived, over/under-specific, or contradicts intent),
**ambiguous** (insufficient public evidence; must not justify `V2 == V1`).

| Formal claim | Intent obligation | Verdict | Note |
|---|---|---|---|
| (PL1) `polylog(1,z) → -log(1-z)`, no exp_polar | I2, I4 | **pass** | Exactly the issue's requested identity; no winding factor. |
| (PL2) `polylog(2,1/2) → -log(2)²/2 + π²/12` | I1 | **pass** | Exactly the issue's stated answer. |
| (PL0) `polylog(0,z) → z/(1-z)` | I5 | **pass** | Named public reduction; unchanged by fix. |
| (PLF s=3) `polylog(3,z) → polylog(3,z)` | I5 | **pass** | Fallback; no closed form claimed. |
| (PLF s=2,z≠½) `polylog(2,z) → polylog(2,z)` | I1 scope | **pass** | Confirms the dilog branch is z=1/2-specific, not a generic polylog(2,·) rule. |
| (PLDERIV left) `d/dz(-log(1-z)) = 1/(1-z)` | I3 | **pass** | Half of the derivative-consistency identity. |
| (PLDERIV right) `polylog(0,z)/z = 1/(1-z)` | I3 | **pass** | Other half; equal normal form ⇒ derivative preserved. |

No claim is marked fail or ambiguous. No claim over-preserves a legacy behavior:
in particular **no claim asserts "polylog(2,1/2) stays unevaluated"** (that would be
S1, a SUSPECT symptom display, not an obligation).

## Design decision D1 — `_eval_expand_func` vs. `eval` (auto-evaluation)

This is the one genuinely under-determined design point, and the FVK materials flag
it for this exact issue ("do not enshrine 'stays unevaluated by default' as an
invariant"). Treated as a **named change to falsify**, not dropped on scope grounds.

**Named alternative B:** put the `Li_2(1/2)` value in `polylog.eval` so that
`polylog(2, S.Half)` auto-evaluates to the closed form (changing the issue's `In[1]`
too), instead of only under `expand_func` (candidate V2, "alternative A").

**Side-by-side derivation against the public obligations:**

| Obligation | A: value in `_eval_expand_func` (V2) | B: value in `eval` (auto) |
|---|---|---|
| I1 `expand_func(polylog(2,1/2)) == answer` | ✅ direct | ✅ (arg pre-evaluates; `expand_func(answer)=answer`) |
| `polylog(2,1/2) == answer` (auto, if tested) | ❌ stays a `polylog` object | ✅ |
| `myexpand(polylog(2,S.Half), answer)` (public-test style) | ✅ | ✅ |
| Consistency with class design | ✅ matches `s=1`,`s≤0` reductions (all in `_eval_expand_func`); `eval` only does universal `z∈{0,1,-1}` | ➖ introduces a first `(s,z)`-pair special case into `eval` |
| Public-test *pattern* (universal-`z` → `==`; specific-`(s,z)` → `myexpand`) | ✅ `(2,1/2)` is specific ⇒ `myexpand`/`expand_func` group | ➖ would be the only specific value tested by `==` |
| Risk of unwanted auto-transform of user expressions | ✅ none | ➖ `polylog(2,z).subs(z,1/2)` silently becomes logs |

**Verdict: A (V2) is the better-justified choice — but NOT because it preserves the
unevaluated symptom.** It is chosen on *positive* grounds: (1) the public-test
structure in `test_polylog_expansion` tests every **specific-`(s,z)`** reduction
(`s=1`, `s=0`, `s=-1`, `s=-5`) through `myexpand`/`expand_func` and reserves bare
`==` for **universal-`z`** reductions (`z∈{0,1,-1}`); `(2, 1/2)` is specific, so the
expand-func path matches the established intent encoding. (2) The `polylog` class
uniformly routes non-universal closed forms through `_eval_expand_func`. Both A and B
satisfy the explicit issue mechanism `.expand(func=True)`; B is not *forced* by intent
and carries an auto-evaluation side effect the issue never requests. Because both
satisfy the mandated obligation, the difference is **under-determined**, recorded as
Finding F4, and resolved toward A by the named convention D-dom2 + the public-test
pattern. This audit explicitly does **not** rest the choice on S1.

## Adequacy gate result

- `INTENT_SPEC.md`, `FORMAL_SPEC_ENGLISH.md`, this file, `PUBLIC_COMPATIBILITY_AUDIT.md`
  exist and are non-empty.
- Read as the only spec, `FORMAL_SPEC_ENGLISH.md` says exactly what `INTENT_SPEC.md`
  requires — no weaker, no stronger on the derivative/frame conditions.
- No required behavior is fail/ambiguous; no unhandled public callsite (see
  compatibility audit). **Adequacy gate: PASS.** The proof in `PROOF.md` therefore
  bears on the right contract.
