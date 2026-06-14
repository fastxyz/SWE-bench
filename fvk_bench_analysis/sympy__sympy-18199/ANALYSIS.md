# sympy__sympy-18199 — FVK artifact audit

**Batch:** `batch5-XC-MINI-PRO-AHP-260614105258` · **Arm result:** FAIL (FAIL_TO_PASS 0/1; sole graded test `test_solve_modular`). baseline == control == fvk (zero flips).
**VERDICT (one line):** **MISSING — but reachable.** The graded failure is a *missing composite-modulus* case; FVK not only omits it, it **certifies the buggy `NotImplementedError` as the spec to preserve** (tell #7 + #9). The half FVK localizes perfectly (prime `a%p==0` zero-root) is *not* the graded axis.

---

## 1. Root cause

The gold patch (`evidence/oracle_patch.diff`) changes `sympy/ntheory/residue_ntheory.py` `nthroot_mod(a, n, p, all_roots=False)` and makes **two distinct fixes**:

1. **Composite modulus support (the graded one).** It deletes
   `if not isprime(p): raise NotImplementedError("Not implemented for composite p")` and instead routes composite `p` to a brand-new helper `_nthroot_mod_composite(a, n, m)` (factor `m`, find/lift roots per prime power, recombine via CRT; new import `from sympy.utilities.iterables import cartes`).
2. **Zero root for prime `p`.** It adds `if a % p == 0: return [0]` before the `is_nthpow_residue` short-circuit, so the previously-missing root `x=0` (when `a ≡ 0 mod p`) is returned.

**What the sole graded FAIL_TO_PASS test asserts.** `test_solve_modular` (in `sympy/solvers/tests/test_solveset.py`) flips two assertions from `ConditionSet` (unsolved) to real solution sets, and both are **composite moduli**:
```python
assert solveset(Mod(x**3, 8) - 1, x, S.Integers) == ImageSet(Lambda(n, 8*n + 1), S.Integers)          # 8 = 2**3
assert solveset(Mod(x**4, 9) - 4, x, S.Integers) == Union(ImageSet(Lambda(n, 9*n + 4), S.Integers),
                                                          ImageSet(Lambda(n, 9*n + 5), S.Integers))     # 9 = 3**2
```
The comment itself changes from `# Not Implemented for m without primitive root` to `# Implemented …`. These reach `nthroot_mod` with a **composite** modulus, so they pass *only* if fix (1) is present. The zero-root fix (2) is irrelevant to them. (The `test_residue` test adds zero-root and composite assertions too, but it is **not** the authoritative FAIL_TO_PASS — `eval/fvk.report.json` lists only `test_solve_modular`.)

**Bug TYPE:** missing-case / missing-feature (composite modulus formerly `NotImplementedError`), plus a co-shipped missing-root (prime `a%p==0`). The graded failure is the *composite-modulus* missing case.

**Public-data reachability.** Split:
- The *zero-root* half is fully spelled out by the problem statement (`a % p == 0 ⟹ x=0`; example `nthroot_mod(17*17,5,17)`). Trivially reachable — and FVK got it.
- The *composite-modulus* half — the part the graded test measures — is **NOT in the problem statement** (which is exclusively about the prime zero-root case). It is, however, reachable from **public code**: the line `raise NotImplementedError("Not implemented for composite p")` is a standing "feature not yet added" admission, and the caller `_solve_modular` in `solveset.py` turns that into the `ConditionSet` the public/derivable tests show as wrong. So the cause is reachable from public data, just not from the issue text. (See §3 honesty check.)

---

## 2. What the fvk arm did (V1 vs final + key artifacts)

**V1 = final.** `solution_baseline.patch` and `solution_fvk.patch` are **byte-identical** (md5 `528d474404f1adc012afc8c827f949e5`). FVK produced **no new code**; it confirmed V1. V1 is *only* fix (2) — the prime zero-root branch — and leaves the composite `NotImplementedError` in place:
```python
if a % p == 0:
    # ``x**n = 0 (mod p)`` has the single root ``x = 0`` for prime ``p``
    return [0] if all_roots else 0
```

**Artifacts.** Markdown-only (`SPEC.md`, `FINDINGS.md`, `PROOF_OBLIGATIONS.md`, `PROOF.md`, `ITERATION_GUIDANCE.md`); **no `.k` files** (K embedded in SPEC.md) — expected for this instance. They form a tight, internally-honest audit of the zero-root branch:
- **SPEC.md** scopes the verified object to "the **new branch**" (`a%p==0`) and assumes the rest (`SPEC.md:12-16`). Intent ledger L1–L3 captures the zero-root cause precisely.
- **FINDINGS.md F1 [BUG, FIXED BY V1]** gives an exact pre-fix failure taxonomy (incl. real crashes `nthroot_mod(11,5,11)` → `ValueError: Log does not exist`) and the resolution.
- **PROOF.md / PROOF_OBLIGATIONS.md** discharge `roots(A,N,P)={0}` via Euclid's lemma and conclude **"V1 is correct and stands"** (`PROOF_OBLIGATIONS.md:123`), correctly restricting the completeness claim to **prime** `p`.

So on its self-chosen domain the audit is *right*. The defect is the **domain choice**.

---

## 3. Artifact audit — VERDICT

### VERDICT: MISSING (inverted) — reachable. Counts toward headroom: **NO**.

The root cause of the **graded failure** is *composite-modulus support*. No artifact contains it. Worse than silent omission: every artifact that mentions the composite axis **certifies the buggy behavior** (`NotImplementedError` on composite `p`) **as the intended contract to preserve.** This is primer tell #7 (scope-induced false negative) compounded by tell #9 (false-positive certification): the spec's frame condition equals the buggy output, so the artifacts point *away* from the fix.

**Exact excerpts (the spot pointed at is the composite branch the gold patch rewrites):**

- Intent ledger treats the bug as a contract to keep — `fvk/SPEC.md:29`:
  > `| L6 | code (line 776) | `if not isprime(p): raise NotImplementedError` | Domain is **prime `p`** only; composite `p` raises (must be **preserved**). | frame / preserve |`

- Human-readable spec enshrines it — `fvk/SPEC.md:209-210`:
  > "returns the solutions of `x**n ≡ a (mod p)` in `[0, p)` (`p` prime; **composite `p` raises `NotImplementedError`**; `None` when there is no solution)."

- A finding marks the bug **[POSITIVE]** — `fvk/FINDINGS.md:75-79` (F6):
  > "**Composite-`p` contract preserved** … `nthroot_mod(0, 5, 12)` → still `NotImplementedError` … The fix does not silently start "supporting" a case the function never supported."

- A claim is *constructed to prove* composite must raise — `fvk/SPEC.md:165-172` (CLAIM-PRIME-GUARD): `<out> _ => raised </out> requires … notBool isPrime(P)`.

- Closure that the answer is complete — `fvk/ITERATION_GUIDANCE.md:16`:
  > "**UltimatePowers question:** none — intent (issue L1–L3) is fully met."

**Why this is MISSING, not BURIED:** the composite axis was excluded *before any obligation was written*. There is no `requires` that quietly admits the composite case is unhandled, no undischarged PO sitting on it, no escalation boundary on it — it is framed as a *frame/preserve* success. Per PLAN §4 + primer tell #7, "clean/total on its (self-chosen) domain" is false reassurance, not a present signal. The one genuine BURIED-style hook would have been an obligation showing `nthroot_mod` returns the wrong/absent set for composite `p`; the artifacts assert the opposite.

**Confirmed absence (what was searched):** all five `fvk/*.md`, `reports/fvk_notes.md`, both patches, and `transcripts/fvk.jsonl.gz` were searched for `composite`, `_nthroot_mod_composite`, `crt`, `factorint`, `Mod(x**3,8)`, `Mod(x**4,9)`, `primitive root`, `ConditionSet`, and `_solve_modular`. The composite *fix* (helper/CRT/factoring) appears **nowhere**; "composite" appears only as the thing being **preserved** (SPEC L6, F6, CLAIM-PRIME-GUARD). `_solve_modular` appears only in the transcript as a caller the agent read and judged "integrates cleanly," never as needing change.

**Reachability / headroom.** The graded cause is reachable from **public code** (the `NotImplementedError("Not implemented for composite p")` line is a visible feature gap; the `ConditionSet` it yields is the wrong public behavior). It is *not* reachable from the *issue text* alone. Under PLAN §4's "derivable from the public data the fvk arm had" (issue **and** code), it is **reachable** — but per PLAN §4's headroom accounting, **MISSING-but-reachable does NOT count toward headroom.** Headroom measures whether the cause is *present and surfaceable* in the artifacts; here it is absent and in fact *inverted* (certified as a contract to preserve), exactly like the other tell-#9 cases `django-16263` and `pydata-xarray-6992` (both MISSING, both not counted). It is a real FVK **gap** — the "broad/contingent" potential, requiring better localization — not narrow headroom. *(Orchestrator correction: the lead's first draft mis-scored this as "counts: YES"; corrected here and in the §3 header for rubric consistency and parity with the parallel tell-#9 cases.)* This matches the study calibration (every failure is an intent-fidelity/localization failure reachable from public data): here FVK anchored 100% on the issue's stated scope (prime zero-root) and never audited the function's *other* visible failure mode.

> Note on the zero-root half: that cause **is STATED** (SPEC.md L1–L3, FINDINGS F1). But it is the cause of a *non-graded* assertion. The graded test (`test_solve_modular`) is purely composite-modulus, for which the cause is MISSING. The verdict is judged on the graded F2P per the prompt.

---

## 4. How FVK could surface it (prose, general, no-exec)

The failure is a **scope/intent-fidelity** gap, exactly the recurring shape in this study — and it is fixable within the no-exec paradigm:

1. **Audit the whole function's behavior space, not just the diff.** FVK scoped `SPEC.md` to "the new branch." A function-level spec would have to give `nthroot_mod`'s postcondition for *composite* `p` too — and the only honest options are (a) "raises (documented gap)" or (b) "returns roots." Writing (a) as a *spec claim* forces the question: *is raising the intended contract, or an unimplemented case?* The standing `raise NotImplementedError(...)` string is itself the kit's own "if a clean spec is hard, suspect a bug" signal — a `NotImplementedError` is a self-declared incompleteness, and a spec should flag it as a **latent unhandled case**, not a `frame/preserve` invariant.

2. **Treat `NotImplementedError`/`ConditionSet` as divergence candidates, not contracts.** A simple rule: an artifact must never mark "feature raises NotImplementedError" as **[POSITIVE]** without checking the issue/tests for intent to *implement* it. Here `_solve_modular`'s `ConditionSet("can't solve")` output, which the agent read, is the downstream symptom; cross-referencing the caller's "unsolved" fallback against the docstring intent ("Find the solutions to `x**n = a mod p`", SPEC L4 — note: *no* prime restriction in the docstring) exposes that composite `p` is in-intent but unimplemented.

3. **Cross-check the spec domain against the docstring/full intent, not just the issue sentence.** The docstring says "solutions to `x**n = a mod p`" with no primality clause; the spec narrowed the domain to prime `p` purely from the implementation guard. A domain drawn from *code* rather than *intent* is the tell-#7 trap; comparing the two would have surfaced the excluded case as a divergence.

(The zero-root half needed no further surfacing — FVK had it. The actionable lesson is purely about not letting "confirm V1 / issue scope" collapse the spec onto the code's existing domain.)
