# Round 3-C result — sympy-13852

**Materials tested:** R3-B + **R3-C** (family/table completeness), fork `ea75b7b`, submodule bump `dfe3d90`. Run: `fvk-r3bc-sympy13852-XC-MINI-PRO-AHP`, `--arms baseline,fvk`.

## Result: still no flip — but the ceiling is now pinned exactly

- baseline **0/1**, fvk **0/1**, **+0 flips**; PASS_TO_PASS **4/4** (no regression). FTP still failing: `test_polylog_values`.

## What R3-C did (it fired as designed)

- **Placement held (R3-B):** the value is in `polylog.eval` (construction path), not the opt-in `_eval_expand_func`.
- **R3-C surfaced the whole family:** the agent's Finding `F3` explicitly enumerates the missing members and even **states their correct closed forms** —
  `polylog(2, 2) = pi**2/4 - I*pi*log(2)` and the golden-ratio arguments `polylog(2, (sqrt(5)-1)/2)`, `(3-sqrt(5))/2`, etc.
- **But it deliberately did NOT commit them**, recording them as an *open Finding* and citing R3-C's own balance clause verbatim:
  > *"do not invent values; if a member's value is genuinely underivable from public/domain knowledge, record it as an open Finding … Li₂(2) is complex-valued and branch-sensitive … no execution to check signs … guessing risks a wrong value."*

## Diagnosis: the gap is no-execution VERIFICATION, not localization/awareness/knowledge

This is the cleanest characterization yet of why sympy-13852 resists materials:

- **Not localization** — R3-B put the value on the right (construction) path.
- **Not awareness** — R3-C made the agent enumerate the entire required family.
- **Not knowledge** — the agent *wrote down the correct value* (`polylog(2,2) = pi²/4 − iπ·log2`) in prose.
- **The blocker is verification:** the kit's honesty discipline (correctly) forbids committing an unverified, branch-sensitive complex value the agent cannot machine-check, and the fvk arm has **no execution**. So a value it knows stays out of the code.

The agent behaved *correctly* — refusing to guess is the integrity the kit is supposed to enforce. The missing rung is precisely the **execution / proof layer** that would let it verify the closed form and then commit it. sympy-13852 is therefore **not flippable by static materials**; it is gated by the verification capability the full product is designed to add.

## Where this leaves the 4 STATED cases

- **pytest-10356** — FLIPPED (the "forced ordering" was a falsifiable, false claim; formal discipline dissolved it).
- **sympy-13852** — bounded by no-exec value verification (this report).
- **sympy-16597** — bounded by a dual-engine/generated mirror + no-exec hidden-test value (round-2 analysis).
- **django-12325** — bounded partly by a domain-misread (a reasoning-quality limit), partly addressable by R3-A (untried).

Net: materials moved the agent from *rationalizing away the fix* → *engaging, localizing correctly, and surfacing the full requirement honestly*. The remaining misses are increasingly gated by the **verification layer**, not by prompt guidance — which is the strongest possible argument that the next rung (machine-checked proofs) is where the remaining value lives.
