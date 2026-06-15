# Round 3-B result — sympy-13852

**Materials tested:** R3-B (fork `e3dc60d`, submodule bump `83c31d7`) — an under-determined placement/value choice resolves to the issue's desired *output form*, never a confirm-V1 tie-break; a value shown **bare** must hold on the construction path (`eval`). Run: `fvk-r3b-sympy13852-XC-MINI-PRO-AHP`, `--arms baseline,fvk`.

## Result: no flip — but the targeted behavior changed

- baseline **0/1**, fvk **0/1**, **+0 flips**; PASS_TO_PASS **4/4** (no regression).
- **R3-B worked at its target.** The fvk arm now places the dilog value in `polylog.eval` (the construction path) — `elif z == S.Half and s == 2: return -log(2)**2/2 + pi**2/12` — instead of round-2's opt-in `_eval_expand_func`. The round-2 failure mode (tie-break onto the opt-in path to confirm V1) is **fixed**, and it is a verifiable behavior change (the fvk patch now differs from V1 and touches `eval`).
- **Why it still fails.** `test_polylog_values` asserts the *whole family* of six `s==2` dilogarithm values, and its **first** line is `polylog(2, 2) == pi**2/4 - I*pi*log(2)`. The agent added only `polylog(2, 1/2)` — the single value the issue hints at — so the test fails on line 1.

## Failure class shifted: WRONG-LOCATION (round 2) → PARTIAL coverage (round 3-B)

The remaining gap is **coverage of the full special-value family**. `Li₂(2)` and the four golden-ratio / Landen arguments are classic dilogarithm special values, but they are **not in the issue text**, and the fvk arm has no execution or lookup. Closing this needs **R3-C** (fix-the-whole-family: when fixing a special-value table, enumerate the known special-value *set* from math knowledge, not just the hinted example) **and** the model actually recalling those closed forms.

**Closable by materials: contingent.** R3-C would prompt the enumeration; whether the flip lands then depends on the model knowing the exact values — a derivability/knowledge limit, not a localization one. This is the no-exec ceiling the round-2 SYNTHESIS flagged, now pinned to a specific cause (value coverage, not placement).
