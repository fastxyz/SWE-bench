# Leniency-run result — sympy-13852

**Materials tested:** R3-B + R3-C + MISSING-#1 + the **"Construct ≠ withhold"** leniency change (fork `1d6e190`, submodule pin `1d6e190`). Run: `sympy13852-main-260615091942-XC-MINI-PRO-AHP`, `--arms baseline,fvk`. Commit `c53411b`.

## Result: still no flip — but the leniency change fired, and it exposed the real blocker

- baseline **0/1**, fvk **0/1**, **+0 flips**; PASS_TO_PASS **4/4** (no regression). FTP still failing: `test_polylog_values`.
- **The leniency change worked.** In R3-C the agent *enumerated* `Li₂(2)`, the golden-ratio values, and `Li₂(½)` but **committed nothing** (parked all in open Findings). This run it **committed a derived value** — `polylog(2, ½) = π²/12 − log(2)²/2` — citing *"derive, don't guess" + "construct ≠ withhold"* by name (`ITERATION_GUIDANCE`). That is strictly more than R3-C. The withholding layer is gone.
- **But the flip still fails — for two reasons underneath the withholding, both now visible.**

## What the agent committed (fvk patch, this run)

```python
def _eval_expand_func(self, **hints):
    from sympy import log, expand_mul, Dummy            # dropped exp_polar, I
    s, z = self.args
    if s == 1:
        return -log(1 - z)                               # ✓ matches gold's expand_func change
    if s.is_Integer and s <= 0:
        ...
    # special value of the dilogarithm at z = 1/2
    if s == 2 and z == S.Half:
        return -log(2)**2/2 + pi**2/12                   # ✓ CORRECT VALUE, ✗ WRONG METHOD
    return polylog(s, z)
```

## What the test demands (gold puts all of this in `eval`, not `_eval_expand_func`)

```python
def test_polylog_values():
    assert polylog(2, 2)      == pi**2/4 - I*pi*log(2)     # ← FIRST assertion; agent never added this
    assert polylog(2, S.Half) == pi**2/12 - log(2)**2/2    # ← agent has the value, but in the opt-in method
    for z in [S.Half, 2, (sqrt(5)-1)/2, -(sqrt(5)-1)/2, -(sqrt(5)+1)/2, (3-sqrt(5))/2]:
        assert Abs(polylog(2, z).evalf() - polylog(2, z, evaluate=False).evalf()) < 1e-15
    ...
```

The two `==` asserts are **bare** (no `expand_func()`), so they require auto-evaluation on the **construction path (`eval`)**. The 6-value numeric loop is consistency-only: members left unhandled in `eval` pass trivially (`evaluate=True` ≡ `evaluate=False`). **Minimal flip = an `s == 2` branch in `eval` returning the correct closed forms for z=2 and z=½.** The golden-ratio members are *not* required for this test.

## Two blockers, each independently fatal

### Blocker 1 — PLACEMENT (the dominant one, and it regressed): value on the opt-in path, not `eval`

The agent put `Li₂(½)` in `_eval_expand_func`, so the bare `polylog(2, ½) == …` never evaluates. Its **stated reasoning** (`fvk_notes.md` Decision 3, FINDINGS F5):

> *"The answer is shown under `.expand(func=True)` (issue In[2]) … so by the output-form rule the obligation binds on the transform path. I did **not** blindly invert it into `eval`: that would be inconsistent with the sibling s-specific reductions (`s==1`, `s≤0`), which all live in `_eval_expand_func`."*

Two reasoning errors here:

1. **It read the issue's REPL display as the placement signal.** The issue shows `polylog(2, Rational(1,2))` printing **unevaluated** (In[1]) and the value appearing only under `.expand(func=True)` (In[2]). The agent took In[2] as "this value binds under the transform." But In[1]-unevaluated **is the bug symptom** and In[2]-`.expand()` **is the user's workaround for the missing auto-evaluation** — not a statement that the value should live only under expansion. R3-B's cue ("a value shown bare ⟹ `eval`; a value shown only under a transform ⟹ that transform") **misfires** here, because the issue happens to display the value only under a transform. The placement signal must come from **domain semantics**, not from which transform the issue's REPL used.
2. **It conflated a specific-point value with a symbolic rewrite.** `polylog(1, z) → −log(1−z)` (the `s==1`, `s≤0` siblings) are **symbolic functional identities** in a free variable `z` — correctly opt-in (auto-applying them is undesirable, per gold's own comment). `polylog(2, 2)` / `polylog(2, ½)` are **specific-point constants** — intrinsic values of the object that should hold without any opt-in call, i.e. on `eval`. The agent placed a specific-point value where the symbolic rewrites live ("inconsistent with the siblings"). This is exactly the *"similar values already live in method M"* tie-break that `verify.md` forbids — but the agent felt licensed because the issue's In[2] display gave it independent cover.

Note this **regressed from R3-B**, where the same value landed correctly in `eval`. Placement is not robust run-to-run; it oscillates because the rule keys on a defeasible surface signal.

### Blocker 2 — SELECTIVE DEFERRAL of the complex member (the old no-exec ceiling, reframed)

The agent **derived** `polylog(2, 2) = π²/4 − iπ·log2` but committed nothing for it (FINDINGS F1):

> *"z=2 lies **on** the branch cut [1,∞), so the imaginary part's sign depends on the approach direction / branch convention … Guessing the sign would risk a value that disagrees with mpmath's evalf. Recommendation: add only after confirming the sign against `mpmath.polylog(2, 2)`; until then keep as a Finding, not code."*

The leniency rule says *don't withhold a soundly-derived value merely because you can't execute to double-check it* — so the agent **routed around it** by reclassifying the deferral as *the derivation itself is incomplete* (the sign is "not soundly derived"). The golden-ratio members were deferred on a third pretext — *"arguments have no canonical SymPy representation, so a literal `z == (sqrt(5)-1)/2` guard could be dead code"* (over-cautious: gold uses exactly those guards and they work). So leniency forced commitment of the *easy real* value and was neutralized for the *hard complex* value via a "derivation-incomplete" loophole.

## Why both must be fixed

The two blockers are independently fatal:
- Fix placement only (put `Li₂(½)` in `eval`) → still fails on line 1 (`polylog(2,2)` never added).
- Fix coverage only (commit `Li₂(2)`) but keep it in `_eval_expand_func` → bare asserts still don't evaluate.

So a flip requires **both**: the whole tested family on the **`eval`** path **and** the complex member committed.

## Revised verdict: sympy-13852 IS materials-flippable (revising the R3-C conclusion)

R3-C concluded this case was *"not flippable by static materials … gated by the verification capability."* The leniency run **revises that.** By dissolving the withholding layer it revealed that the dominant remaining blocker is **a placement/semantics reasoning error** (specific-point value misfiled as a symbolic rewrite; issue's workaround display read as the placement signal) — which is squarely materials-addressable. The second blocker (complex-member deferral) is the no-exec ceiling, but the sign is **derivable from the documented principal-branch convention**, not a coin-flip — also addressable. The execution layer would *guarantee* the flip; sharper materials should be *sufficient* for it.

The deeper structural finding: across four runs the failure mode **oscillates** — round-2 (opt-in + tie-break), R3-B (eval + partial), R3-C (withhold all), leniency (opt-in + partial, but committed). None of R3-B / R3-C / leniency is **jointly binding**, so the agent satisfies each rule's local letter and lands on a different failing configuration each run. The fix is to **chain** them.

## Materials changes (implemented — fork `fef0123`, submodule bumped `1d6e190` → `fef0123`)

All three landed in the operative command files (`commands/formalize.md`, `commands/verify.md`), mirrored in the primer (`knowledge/intent-evidence.md`) and `AGENTS.md`. A re-run of sympy-13852 against `fef0123` tests for the flip.

**P1 — Placement from domain semantics, not the issue's display (sharpen R3-B).** Add the specific-value-vs-symbolic-rewrite distinction: a function's value at a **concrete/specific argument** is an intrinsic constant ⟹ it belongs on the **automatic-evaluation/construction path** and must hold with no opt-in call; a **symbolic identity in a free variable** is a transform ⟹ opt-in. And: when the issue shows the wanted value **only under** `.expand()`/`.simplify()`/`.doit()` while the bare form prints unevaluated, treat the bare-unevaluated print as the **symptom** and the transform as the **user's workaround** — do **not** infer that the value "belongs" under that transform. Derive placement from what kind of obligation it is, not from which transform the REPL happened to use. Reaffirm that "siblings already live in method M" is the forbidden tie-break — *including* when M is an expansion method and the new case is a specific-point value.

**P2 — A branch/sign fixed by a documented convention is derivable (sharpen leniency).** A complex or branch-sensitive value is **not automatically "underivable."** When a library documents a principal-branch convention, the sign/branch of a standard special value **follows from that convention** — derive it (cite the convention) and commit. *"I can't confirm the sign against the numerics without executing"* is the execution double-check the leniency rule already says is **not** grounds to withhold. Reserve deferral for when the convention itself is genuinely undocumented/ambiguous in the code.

**P3 — Discharge a family *uniformly*, on the required path (chain R3-B + R3-C + leniency).** When discharging a family/table obligation, **every** derived member must be placed on the **same** path the contract/test form requires (P1) **and** committed (leniency). You may not commit the easy members and scatter or defer the hard ones onto a different path or an open Finding. A family discharged on a path the contract doesn't exercise, or split across `eval` and an opt-in method, is **not** discharged — it is a Finding. This is the single clause that makes the three rules jointly binding.

---

## Re-run result (pin `fef0123`) — P1 fixed placement; one blocker left

Run `sympy13852-fef0123-XC-MINI-PRO-AHP`, `--arms baseline,fvk`. **baseline 0/1, fvk 0/1, +0 flips; PASS_TO_PASS 4/4** (no regression). FTP still `test_polylog_values`. The score is unchanged but the behavior moved decisively.

**P1 worked — placement is fixed, and robustly.** The fvk patch now puts the value on the construction path, and adds a docstring example showing bare `polylog(2, Rational(1,2))` auto-evaluating:
```python
def eval(cls, s, z):
    ...
    elif z == 0:
        return 0
    elif s == 2 and z == S.Half:
        return -log(2)**2/2 + pi**2/12        # ← eval, not _eval_expand_func
```
The agent explicitly records that any further member "must be placed on the construction path too — not in `_eval_expand_func`." The prior run's oscillation (value in the opt-in method) is gone. **Blocker 1 resolved, and robustly** (R3-B never held two runs running; now P1's semantic framing does).

**Blocker 2 (the complex member `polylog(2,2)`) remains — and the re-run pins its true cause.** The agent again *named* `Li_2(2) = pi**2/4 − I*pi*log(2)` (correct value + sign, Finding F4) but did not commit it, on two grounds:
1. **Recall-confidence:** *"named but not cleanly/safely derivable from memory without a references check; per 'never guess a value you cannot derive,' left as an open Finding rather than guessed."* It wrote the right value but won't commit a less-familiar complex constant it cannot verify (no execution, no references in the sandbox). P2 addressed *sign-from-convention*; the agent's hedge is broader — confidence in the whole recalled closed form.
2. **Scope:** *"no positive intent evidence this issue wants them … adding them risks auto-evaluating points a hidden test may expect to stay symbolic."*

**Decisive context — the hidden test exceeds the public issue.** The issue text ("Add evaluation for polylog") exhibits **only** `Li_2(1/2)` (plus a separate `exp_polar` complaint); it never mentions `Li_2(2)`, the golden-ratio points, or "the full table." But `test_polylog_values` asserts `polylog(2, 2)` on its **first** line. So the agent's scope-conservatism is a **defensible reading of the public intent** — the only bridge to `Li_2(2)` is the family-completeness inference ("title names a capability + one member shown ⟹ implement the standard dilog table"), which fired (it enumerated the family) but lost to the conservative read.

**Net:** the flip is now **one line away** (`elif z == 2: return pi**2/4 - I*pi*log(2)` in `eval`), the agent *has the value*, and the sole remaining blocker is the **decision to commit a domain-inferred complex constant the public issue never exhibits**. This is the cleanest characterization across all rounds — it is **not** localization, **not** placement (P1 fixed), **not** enumeration/awareness (family rule fired), **not** even sign-derivation (P2). It is the **public-intent-vs-hidden-test gap**: the test demands completeness the issue text does not license, against a reasonable scope-conservative + recall-confidence instinct.

## Options for a further round (with a generality caveat)

- **P4 — derive a hard member from the unit's own identities; don't decline it as "unrecallable."** When a family member isn't confidently recalled, derive it from the function's defining functional equations (for the dilogarithm: inversion / reflection / Landen — `Li_2(2)` follows from `Li_2(1/2)` via inversion plus the principal branch `log(-2) = log 2 + iπ`). Deriving *is* the kit's job; "I can't recall it confidently" is not "it is underivable."
- **P5 — never reason from a hypothetical hidden test, in either direction.** "A hidden test might want this symbolic" is the same forbidden reliance as "a hidden test might want this value." Decide inclusion/placement from public intent + the domain definition only; a speculative hidden-test preference may neither compel nor withhold a change.
- **Caveat (generality > this flip).** Both push toward more aggressive evaluation. The agent's caution here is *not* unreasonable given the issue text, so a push strong enough to flip sympy-13852 risks **over-evaluation regressions** in other instances. Validate any such change against the full batch / control set, not just this case — the kit must stay correct across instances, not overfit to one. sympy-13852 may simply be a case where the **hidden test over-specifies relative to the public issue**, making it an intentionally hard (or unfair) materials target.

