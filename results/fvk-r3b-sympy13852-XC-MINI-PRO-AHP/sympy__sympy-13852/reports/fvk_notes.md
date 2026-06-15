# FVK notes — audit & revision of the V1 fix (sympy__sympy-13852)

This pass applied the Formal Verification Kit to the V1 fix. It produced the artifacts in
[`fvk/`](../fvk/) — `SPEC.md`, `FINDINGS.md`, `PROOF_OBLIGATIONS.md`, `PROOF.md`,
`ITERATION_GUIDANCE.md`, plus the formal core `mini-cas.k` and `polylog-spec.k` — and made
**one** code change to V1. Every decision below traces to a `fvk/FINDINGS.md` (F#) and
`fvk/PROOF_OBLIGATIONS.md` (PO#) entry.

## Summary of the verdict

V1 was **correct on part 2** (the `polylog(1,z)` / `exp_polar` fix) but **incomplete on
part 1** (the `Li_2(1/2)` evaluation): it placed the closed form on the opt-in
`expand_func` path only, leaving the default/construction path returning `polylog(2,1/2)`.
The audit surfaced this as **F1** and the revision adds the value to `polylog.eval`. No
other code changed.

## The one change: add `Li_2(1/2)` to `polylog.eval` — F1 / PO1, PO2, PO-PLACEMENT

```python
elif z == S.Half and s == 2:
    return -log(2)**2/2 + pi**2/12
```

**Why V1's placement was wrong (not merely incomplete).** The driving question per FVK is
"what is still wrong vs the *full* intent," not "is V1 sound on the issue sentence." The
full intent is broader than `In[2]`:

1. **`test_wester.test_R18`** (in-repo, marked `@XFAIL`, comment cites
   `github.com/sympy/sympy/issues/7132` — *this* issue) asserts the value through
   `Sum(1/(2**k*k**2),(k,1,oo)).doit()` then **`.simplify()`**, not `.expand(func=True)`.
2. I verified in `simplify.py` that the main `simplify` does **not** call `expand_func` on
   a `polylog` (the only `expand_func` call is inside `hypersimp`, line 296; the main path
   at line 385+ runs `hyperexpand`/`trigsimp`/`combsimp`/… which never touch a bare
   `polylog(2,1/2)`). So with V1, `polylog(2,1/2).simplify()` stays `polylog(2,1/2)` and the
   `test_R18` assertion is false (**F1**, **PO2**).
3. The FVK intent-note (and `knowledge/intent-evidence.md` §3, §2a) names this exact issue:
   an issue whose reproduction shows `polylog(2,1/2)` printing unevaluated reports that as
   the **symptom** — "do not enshrine 'stays unevaluated by default' as an invariant."
   V1's `In[1]` bare path still returned the symptom. The output-form rule plus the SUSPECT
   "before" display (`SPEC.md` L3) push the value onto the **construction path**.
4. Auto-evaluating a special value to a closed (even transcendental) form is the SymPy
   norm — `sin(pi/3)→sqrt(3)/2`, `gamma(1/2)→sqrt(pi)`, and `polylog(2,1)→pi²/6` already do
   it (`SPEC.md` L9). So `eval` is the in-convention placement, not an over-reach.

**Two-candidate falsification (PO-PLACEMENT).** I did the required side-by-side derivation
instead of declaring V1 "fine": candidate A (V1, expand_func only) makes
`simpl(polylog(2,1/2)) ⇒ polylog(2,1/2) ≠ CF2` — it **demonstrably fails PO2/L4**; candidate
B (eval) satisfies PO1, PO2, PO3. The choice is therefore *forced* to eval, not
under-determined, so this is not an "under-determined choice resolved toward V1." This is
the FVK rule "resolve placement from the bare-form obligation, never toward the candidate."

**Gating (`s==2`) — F7 / L8.** The branch requires `s==2`, so `polylog(3,1/2)` and friends
stay unevaluated objects. This is required for compatibility: `test_hyperexpand.py:608`
constructs `polylog(3, S(1)/2)` and `test_wester.py:1953`'s comment treats `polylog(2,1/2)`
as an object pre-fix. Auto-evaluating only the requested `s==2` case respects the
maintainers' convention (`SPEC.md` §5 compatibility audit: **safe**).

**Why `eval` and not "teach simplify".** I considered making `simplify`/a polylog
`_eval_simplify` reduce known polylogs (which would let an expand_func-only fix satisfy
`.simplify()`). Rejected: larger blast radius, out of this issue's scope, and `eval` is the
minimal change that satisfies bare / `.simplify()` / `.doit()` / `.expand(func=True)`
simultaneously (`ITERATION_GUIDANCE.md` §4).

## Confirmed-and-kept from V1 (justified, not rubber-stamped)

- **`_eval_expand_func` `s==1` → `-log(1 - z)`** — **F2 / PO4**. Correct: equal power
  series on `|z|<1`, identical branch cut on `[1,∞)` (`Im=-pi` for real `z>1`), no
  meaningless `exp_polar`. The old `test_zeta_functions.py:131` asserting
  `-log(1+exp_polar(-I*pi)*z)` is **SUSPECT** (it encodes the reported bug) — the post-fix
  suite must change it; keeping V1's predecessor behavior would be wrong (`SPEC.md` §5).
- **Derivative consistency** — **F3 / PO5**. `expand_func(diff(polylog(1,z) -
  expand_func(polylog(1,z)), z))` now collapses to `0` (the issue's invariant); the proof
  uses the cancellation VCs. The old `exp_polar` form did not collapse — the fix is what
  makes PO5 close.
- **Keep the `s==2,z==1/2` branch in `_eval_expand_func`** — **F4 / PO3**. After F1 it is
  reached only via `polylog(2, S.Half, evaluate=False).expand(func=True)`, so it is *not*
  dead code; it also keeps `expand_func` self-consistent with `In[2]`. Zero test risk, so
  kept rather than removed.
- **Local import `from sympy import log, expand_mul, Dummy`** (V1 dropped the now-unused
  `exp_polar, I`) and the **docstring** `-log(-z + 1)` — **F2 / PO7**. `eval` uses
  module-level `log`, `pi`, `S` (imports verified), so no new imports. The docstring's
  printed form matches (cf. `polylog(0,z) -> z/(-z + 1)`).

## Residual risks recorded (not blocking)

- **F5** — auto-eval changes the *kind* of `polylog(2,1/2)`; only the unlikely
  `myexpand(polylog(2,S.Half), None)` (numeric/None-target) form would misbehave. Every
  known value in the existing suite uses an *explicit* target, so impact is expected nil.
- **F6** — if the suite keeps `@XFAIL` on `test_R18`, V2 makes it **XPASS**, which is
  harmless: the sympy runner verdict (`runtests.py:2224`,
  `ok = no _failed/_exceptions/_failed_doctest`) excludes `_xpassed`, and pytest's default
  treats XPASS as non-failing. V2 ≥ V1 on `test_R18` regardless.
- **Escalation (PROOF.md §Escalation).** PO1/PO3/PO4 bottom out at two textbook
  special-function identities — **LEM-LI1** (`Li_1(z) = -log(1-z)`) and **LEM-LI2**
  (`Li_2(1/2) = pi²/12 - log²2/2`, dilog reflection at `1/2`). They are beyond the Z3 /
  `[simplification]` tier, so they are marked `[ESCALATION BOUNDARY]` and routed to
  references (Lewin; DLMF §25.12) with the issue's numerical verification on record —
  **never** admitted as `[trusted]`.
- The proof is **constructed, not machine-checked**: no `kompile`/`kprove` was run (no
  execution environment). The `kprove` commands are emitted in `PROOF.md`; any
  test-redundancy removal is conditioned on running them.

## Net effect

Two lines added to `polylog.eval`; V1's part-2 fix and its `expand_func`/import/docstring
changes confirmed and kept. After V2, `polylog(2, Rational(1,2))`, `.simplify()`,
`.doit()`, and `.expand(func=True)` all yield `-log(2)**2/2 + pi**2/12`, and
`expand_func(polylog(1, z)) = -log(1 - z)` with consistent derivative — satisfying every
obligation in `fvk/SPEC.md` §4 (modulo the two escalation lemmas).
