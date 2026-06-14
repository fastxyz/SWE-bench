# Evidence excerpts — fvk/FINDINGS.md  (sympy__sympy-13852)
Source: results/batch5-XC-MINI-PRO-AHP-260614105258/sympy__sympy-13852/fvk/FINDINGS.md
Quoted verbatim with FINDINGS.md line numbers.

## HEADLINE — clean spec asserted as POSITIVE evidence of correctness (TELL e + f)
- FINDINGS.md:6-7 "Findings are non-blocking advice; none of them, on audit,
  requires a behavioral code change beyond what V1 already did."
- FINDINGS.md:9-12 "**Headline:** writing the spec for the dispatch was **clean** —
  disjoint, exhaustive branches with a single uniform postcondition ... Per the FVK
  "spec-difficulty = bug signal" rule, a *clean* spec is positive evidence the code
  is correct."
  >>> TELL (e)+(f): the FVK arm uses the EASE of writing the (mis-scoped) spec as
  affirmative proof V1 is correct. The spec was only clean because it was scoped to
  the wrong method and to the single value the issue happened to name.

## F1 — exp_polar / polylog(1,z) = -log(1-z)  (CERTIFIES V1 s==1 as correct)
- FINDINGS.md:18 "### F1 — `exp_polar(-I*pi)` in `expand_func(polylog(1, z))`
  (RESOLVED by V1) — ties L3, L5"
- FINDINGS.md:19-20 "- input: `expand_func(polylog(1, z))`" / "pre-V1 observed:
  `-log(z*exp_polar(-I*pi) + 1)`"
- FINDINGS.md:24 "expected: `-log(1 - z)`"
- FINDINGS.md:26-30 "V1 fix: `return -log(1 - z)`. **Audit verdict: correct.** See
  VC-Li1 (PROOF.md): the identity holds *including branch cuts* ... per the issue's
  thousands-of-points test and SymPy's own `hyperexpand` ..."
  >>> This is the whole second half of the issue. It is real, but IRRELEVANT to the
  graded gold test (test_polylog_values), which never touches the s==1 branch.

## F2 — polylog(2, 1/2) special value (CERTIFIES V1's single value, in wrong method)
- FINDINGS.md:32 "### F2 — `polylog(2, 1/2)` had no closed-form evaluation
  (RESOLVED by V1) — ties L1, L2"
- FINDINGS.md:33-35 "- input: `polylog(2, Rational(1,2)).expand(func=True)`" /
  "pre-V1 observed: `polylog(2, 1/2)` (unevaluated)" / "expected: `-log(2)**2/2 + pi**2/12`"
- FINDINGS.md:36-38 "V1 fix: `if s == 2 and z == S.Half: return -log(2)**2/2 +
  pi**2/12`. **Audit verdict: correct.** Standard dilogarithm value Li_2(1/2) ..."
  >>> TELL (e), the decisive one: F2 certifies the value only via `.expand(func=True)`.
  The gold test asserts BARE `polylog(2, S.Half) == pi**2/12 - log(2)**2/2` (no
  expand) -> only achievable in polylog.eval. The audit never questions the method.

## F3 — disjoint/exhaustive guards => "new branch can't shadow" (POSITIVE)
- FINDINGS.md:44 "### F3 — branch guards are disjoint and exhaustive (no regression)
  — ties L6, L7, L8"
- FINDINGS.md:47-52 "the new `s==2 ∧ z==½` rule **cannot** shadow or steal an input
  from any pre-existing branch. `expand(symS, *)`, `expand(2, z≠½)`, `expand(0/-1/-5,
  *)` all behave exactly as before V1."
  >>> Reinforces that s==2, z!=1/2 must stay unchanged — i.e. certifies the missing
  golden-ratio/z=2 cases as intended.

## F4 — derivative consistency restored (POSITIVE)
- FINDINGS.md:54 "### F4 — derivative-consistency restored (L4) — positive"
- FINDINGS.md:55-59 input `expand_func(diff(polylog(1, z) + log(1 - z), z))` -> "0.
  **Restored by V1**, as a direct corollary of F1 (VC-Frame)."

## F8 — explicitly argues AGAINST broadening the special-value table (TELL d)
- FINDINGS.md:92 "### F8 — V1 is intentionally narrow (only `Li_2(1/2)`) — ties L1"
- FINDINGS.md:93-97 "The issue asks for exactly one new special value. Other
  dilogarithm values (e.g. golden-ratio arguments) are not requested and are not
  added. This is not a missing-case bug *relative to intent*: the spec's only `s==2`
  obligation is `z==1/2`. A broader special-value table is an enhancement, routed to
  ITERATION_GUIDANCE.md, not a correctness gap."
  >>> TELL (d), the strongest: the FVK arm NAMES the exact correct fix ("golden-ratio
  arguments", "a broader special-value table") and then argues AGAINST adding it,
  reclassifying the precise gold requirement as out-of-scope "scope creep." The gold
  test_polylog_values needs exactly z in {1/2, 2, and four golden-ratio args}.

## F7 — float 0.5 collapses (benign, but shows model thinks only about z==1/2)
- FINDINGS.md:82-90 "### F7 — `Float(0.5)` input also collapses to the exact value
  ... Decision: **no guard added.**"

## F9 — visible test still pins OLD exp_polar form (mis-reads the test situation)
- FINDINGS.md:99-109 "### F9 — the in-repo (visible) test still pins the OLD
  `exp_polar` form ... `test_zeta_functions.py:131` reads `assert
  myexpand(polylog(1, z), -log(1 + exp_polar(-I*pi)*z))`. ... Classification:
  **intended behavioral change** ... the graded suite is the post-issue version,
  which expects `-log(1 - z)`."
  >>> The agent inferred the hidden suite from the s==1/exp_polar line on 131. The
  ACTUAL hidden change is a NEW function test_polylog_values asserting bare-eval
  dilog values at six points — which the agent never imagined.

## PF1 — escalation boundary on the two analytic identities (TELL b)
- FINDINGS.md:115-127 "### PF1 — the two correctness VCs are special-function
  identities (escalation tier) ... Marked `[ESCALATION BOUNDARY]` in PROOF.md and
  discharged honestly by (a) citing the standard identities, (b) numerical
  witnesses, (c) SymPy-internal corroboration ... They are **not** admitted as
  `[trusted]`."

## PF2 — "no precondition had to be invented" used as POSITIVE signal (TELL inverse)
- FINDINGS.md:129-134 "### PF2 — no soundness side condition had to be invented for
  the dispatch ... The absence of a forced precondition is corroborating evidence
  ... that the changed branches are not hiding an undefined case."

## Spec-difficulty signal — declared NONE (TELL f)
- FINDINGS.md:138-145 "## Spec-difficulty signal ... **None for the audited change.**
  A clean, disjoint, exhaustive case spec with a single uniform postcondition was
  writable on the first pass. By the kit's own heuristic, that is positive evidence
  the V1 dispatch is correct."
  >>> The "no spec difficulty" conclusion is an artifact of mis-scoping to
  _eval_expand_func + the one named value, not of the code being correct.
