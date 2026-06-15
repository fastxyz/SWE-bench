# sympy__sympy-13852 — ROUND 2 (hardened-FVK) failure analysis

**Instance:** `sympy__sympy-13852` (SymPy, symbolic mathematics)
**Run:** `fvk-improved-4cases-XC-MINI-PRO-AHP` (FVK submodule hardened to `275cd44`,
"docs: harden audit posture against rejecting a named correct fix")
**Round-1 outcome:** VERDICT **STATED** — the agent named the correct fix and made
**no behavioral edit** (read the issue's pre-fix display as a binding
"stays-unevaluated" invariant).
**Round-2 outcome:** the hardening made the agent **ACT** — it produced a real
46-line patch and *explicitly rejected* the round-1 symptom argument — **but it
still FAILS** the hidden FTP test (`fvk resolved=False`, FTP 0/1, failing test
`test_polylog_values`). Baseline behaves identically (zero flip).
**Failure class: WRONG-LOCATION (placement), compounded by PARTIAL (coverage).**
The fix is in `_eval_expand_func` not `polylog.eval`, and covers 1 of 6 z-values.

---

## 1. Root cause (gold) — restated crisply

The bug is a **math-correctness** defect in `class polylog`,
`sympy/functions/special/zeta_functions.py`. The gold patch (upstream `1c752d37e6`;
`evidence/oracle_patch_excerpt.diff`) has two parts, only the first of which the
graded test measures:

**(A) Missing special-value auto-evaluation — the graded defect.** Gold adds the
dilogarithm closed forms **into `polylog.eval`** — the `@classmethod` that runs at
**construction** time — covering **six** `z`-values for `s == 2` (`1/2`, `2`, and
four golden-ratio/Landen arguments), plus `s == 0 -> z/(1-z)` and
`s == -1 -> z/(1-z)**2` (imports `I`, `sqrt`). Because the forms live in `eval`,
`polylog(2, z)` collapses to its bare value the moment it is built.

**(B) Spurious `exp_polar(-I*pi)` branch factor** in `_eval_expand_func`'s `s==1`
branch: `-log(1 + exp_polar(-I*pi)*z)` -> `-log(1 - z)`. Real, but the graded test
does not assert on it as the failure axis (it is asserted in the *expansion* test,
which the fvk patch happens to satisfy).

**The bare-form requirement is the crux.** The hidden test
`test_polylog_values` (`evidence/failing_ftp_test.txt`) asserts:

```python
assert polylog(2, 2)      == pi**2/4 - I*pi*log(2)        # bare ==, no .expand()
assert polylog(2, S.Half) == pi**2/12 - log(2)**2/2       # bare ==
for z in [S.Half, 2, (sqrt(5)-1)/2, -(sqrt(5)-1)/2, -(sqrt(5)+1)/2, (3-sqrt(5))/2]:
    assert Abs(polylog(2, z).evalf() - polylog(2, z, evaluate=False).evalf()) < 1e-15
```

So the value **must auto-evaluate at construction** (placement = `eval`), and
**all six** `s==2` arguments must be covered. The gold fix is `eval`-placement +
6-arg coverage + bare auto-eval; the `exp_polar` removal is the orthogonal half.

**Public-data reachability: YES (strong).** The issue gives the exact desired value
("The answer should be `-log(2)**2/2 + pi**2/12`") and the closed forms are standard
public math.

---

## 2. What the NEW fvk arm did — V1 and final patch, vs gold

**New V1 (`solutions/solution_baseline.patch`)** edited *only* `_eval_expand_func`:
fixed `s==1 -> -log(1-z)` (B, correct), trimmed `exp_polar, I`, and added a nested
`if z == S.Half: / if s == 2: return -log(2)**2/2 + pi**2/12` — **one** value, in
the **wrong** method.

**Final fvk (`solutions/solution_fvk.patch`) = CONFIRMED V1.** The only edit was a
readability flatten of the guard to `if s == 2 and z == S.Half:` (identical truth
table). `fvk_notes.md`: *"**V1 stands.** ... No correctness edit was justified."*
The exp_polar removal (B) matches gold; everything in (A) is wrong.

**Precise difference from gold — three axes (`evidence/new_fvk_patch.diff`):**

| Axis | Gold | New fvk patch |
|---|---|---|
| **Placement** | `polylog.eval` (construction) | `_eval_expand_func` (only under `expand_func`) |
| **Coverage** | 6 `z`-values for `s==2` (+`s=0,-1`) | **1** value (`z == S.Half`) |
| **Form** | bare auto-eval: `polylog(2, z) == value` | object stays unevaluated; value only via `.expand(func=True)` |

The fvk arm's own contract certifies the narrowness as correct
(`fvk/SPEC.md`/`polylog-expand-spec.k` claim `(PLF s=2,z!=1/2) polylog(2,z) -> polylog(2,z)`)
and even asserts the *negative* of the gold behavior in `SPEC_AUDIT.md`: placement A
"stays a `polylog` object" on bare `==`, recorded as acceptable.

---

## 3. Diagnosis (the heart) — why it fails the FTP, and exactly where the new guidance fell short

**Exact failing assertion** (`evidence/failing_ftp_test.txt`, fvk
`test_output.txt:531-534`):

```
File ".../test_zeta_functions.py", line 140, in test_polylog_values
    assert polylog(2, 2) == pi**2/4 - I*pi*log(2)
AssertionError
```

It fails on the **first** assertion because (i) the patch never added `z == 2`
(coverage), and (ii) even where it added a value, it lives in `_eval_expand_func`,
so `polylog(2, 2)` (and `polylog(2, S.Half)`) remain unevaluated objects under bare
`==` (placement/form). Placement is the dominant cause; coverage compounds it.

**Did the hardening change behavior? Yes — and partially in the right direction.**
Round-1's fatal step was reading `Out[1]: polylog(2,1/2)` as a binding invariant and
making **no edit**. The hardened `intent-evidence.md`/AGENTS.md "tests AND pre-fix
displays are defeasible" rule **worked**: the agent marked that display SUSPECT (S1)
and refused to use it as a no-op justification (`INTENT_SPEC.md:45-51`; transcript:
*"an issue showing `polylog(2, 1/2)` printing unevaluated is reporting that as the
symptom — I must not enshrine 'stays unevaluated' as an invariant"*). It then **acted**
(46-line patch) and fixed (B) correctly. The round-1 refusal is gone.

**Where it still fell short — a fabricated positive-evidence tie-breaker
(`evidence/wrong_decision_excerpts.md` section C).** The hardened verify.md "Forced
choices" rule requires: name the alternative, derive both side by side, and *"if both
candidates satisfy the public obligations the choice is **under-determined, not
forced** — record it as open, **never as CONFIRM** ... never predict a hidden test's
value."* The agent followed the letter exactly — it built the A-vs-B table
(`SPEC_AUDIT.md:34-41`), found both satisfy the *explicit* `.expand(func=True)`
obligation, and labelled the point "under-determined." **Then it resolved the
"open" point with a *second, constructed* argument and CONFIRMED V1.** From
`SPEC_AUDIT.md:43-54`:

> **Verdict: A (V2) is the better-justified choice — but NOT because it preserves
> the unevaluated symptom.** It is chosen on *positive* grounds: (1) the public-test
> structure in `test_polylog_expansion` tests every **specific-`(s,z)`** reduction ...
> through `myexpand`/`expand_func` and reserves bare `==` for **universal-`z`**
> reductions ... `(2, 1/2)` is specific, so the expand-func path matches the
> established intent encoding.

Two compounding errors live in that one table (`SPEC_AUDIT.md:34-41`):

1. **It foresaw the exact failure and bet against it.** A table row reads:
   *"`polylog(2,1/2) == answer` (auto, **if tested**) | A: stays a `polylog`
   object | B: ok"*. The hidden test asserts *precisely* that bare `==`. The agent
   treated "is the bare form tested?" as a hypothetical and resolved it toward
   "no" — the single thing the rule says never to do ("never predict a hidden
   test's value from such an argument").

2. **The tie-breaker generalises the wrong sibling.** It elevates the *legacy
   expansion* test's "specific-(s,z) -> expand_func / universal-z -> ==" shape into a
   binding "convention" (crystallised as `INTENT_SPEC.md:64-70` D-dom2,
   "`expand_func` is opt-in"), and lets that override the issue's **explicit desired
   output** — a closed-form *value*. This is the kit's own "implementation/test facts
   are not the desired semantics" failure, laundered as "positive grounds."

This is primer tell **#8 (STATED-but-reasoned-against)** mutated by the hardening:
round-1 rejected the correct fix on a *binding-display* argument; round-2, with that
route closed, rejected it on a *fresh constructed convention*. The agent even kept an
honest hedge it then overrode — `FINDINGS.md:50-54`: *"Should `polylog(2, 1/2)`
evaluate automatically (like `zeta(2)->pi**2/6`) ... ? **Either is defensible**"* —
naming the *correct* analogy (`zeta(2)` auto-evals in `eval`) before breaking the tie
the wrong way.

**Classification: WRONG-LOCATION (placement), compounded by PARTIAL (coverage).**
Not WRONG-VALUE (the one value it added is numerically correct) and not OVER-REACH
(it changed less than gold, not more). Not a section-vi formal blind spot: this is an
intent-fidelity/placement failure, fully inside the modelled fragment.

---

## 4. How FVK materials could close the gap (round-3 recommendation) — general, transferable, no-exec

The round-2 hardening solved the *first-order* failure (don't treat a pre-fix
display as binding; promote named changes). The residual is a **second-order leak in
the same rule**: "under-determined" has no honest exit, so it collapses back into
"confirm V1." Three concrete, transferable, no-exec material changes:

1. **Close the "under-determined" escape hatch — add a no-CONFIRM-on-tie-break
   clause to the "Forced choices" rule (`commands/verify.md`, mirror
   `knowledge/intent-evidence.md` section 4.7, `AGENTS.md`).** Today the rule forbids
   confirming on the *forcing* argument but is silent once the point is declared
   "under-determined." Add: *"Once a choice is under-determined, you may NOT then
   resolve it with a fresh secondary heuristic (a test-shape pattern, a coding
   convention, 'opt-in' lore) and CONFIRM V1 on that basis. A secondary tie-breaker
   is itself `implementation/convention-derived` and needs the same falsification
   (predict its output; check it against the issue's *explicit desired output*). If
   the issue states an explicit desired result, that result — not a convention about
   *where* results live — decides the obligation."* This is general: it stops any
   "both pass the literal obligation, so I'll keep V1 via convention X" move.

2. **Make WHERE-must-it-hold a first-class proof obligation derived from the
   desired-output FORM (`commands/formalize.md`, intent-ledger step).** When the
   issue's desired output is a closed-form *value* (not "X under operation Y"), the
   intent ledger should emit a *placement* obligation — *holds at construction vs.
   only under an explicit operation?* — and default it to **construction-time
   (`eval`)** whenever the desired form is shown bare, escalating to "opt-in" only on
   *explicit* public evidence that the bare form must stay inert. Here the issue
   shows the bare value as "the answer"; D-dom2's "expand_func is opt-in" was an
   inference about *plumbing*, not a stated requirement, and should not have outranked
   the value. The agent already located `polylog.eval` as the construction-time
   evaluator (PO7) — it needed an obligation pointing there, not a convention pointing
   away.

3. **When a tie-breaker rests on a SIBLING test's shape, require the sibling to be
   on the SAME behavior axis (`knowledge/intent-evidence.md` section 4).** The
   decisive heuristic generalised `test_polylog_expansion` (an *expansion* test) to
   govern an *evaluation* question. Add: *"A test-pattern used as positive evidence
   for a placement/behavior decision must exercise the *same* behavior being decided;
   a pattern from an orthogonal feature (expansion vs. construction-time evaluation)
   is `implementation-derived` and cannot outrank the issue's explicit desired
   output."*

**Headroom: PARTIAL.** The placement/coverage information was present and the agent
even named the correct analogy; a material change that (1) denies CONFIRM-via-fresh-
convention and (2) ties placement to the desired-output *form* would plausibly flip
this case — the agent would be pushed to the `eval` placement and, once the bare
`polylog(2, 2) == ...` form is the obligation, to broaden coverage. It is *partial*
not *high* because the six-value coverage still rests partly on recognising the
issue's *class* of values (dilogarithm special values) beyond the one literal `1/2`
example; a no-exec audit can be *pushed* toward that by an "enumerate the issue's
value class" ledger rule, but cannot *derive* the four golden-ratio constants from
the issue text alone — so a residual coverage gap may persist even with perfect
placement.
