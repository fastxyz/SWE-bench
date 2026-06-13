# ITERATION_GUIDANCE.md — decision and next-iteration feedback (CDS #14369)

## Decision: **V1 stands, unchanged.**

The audit confirms V1 correctly and completely fixes the reported bug on the spec's
domain. Justification traces to the artifacts:

- **(DIVCHAIN)/PO-1** — the `/`-chain now yields `u0/(u1·…·un)` for *every* chain and
  every unit (precondition-free, linear, inductive proof). The reported failures
  (F-1) are fixed and the V0 behaviour is provably wrong (BUG-V0).
- **PO-REGEN/PO-4** — the grammar edit actually takes effect at run time; the
  `optimize=True` no-op trap (F-2) is handled by the `_tabversion` sentinel.
- **PO-3 / PO-6 / PO-7 / PO-8** — product semantics, existing `test_cds_grammar`
  cases, writer round-trips, and the failure cases are all preserved.
- The single behaviour change beyond the fix (F-3, bare `/`-then-`·` now raises) is
  **out of the clean spec domain**, **standard-sanctioned to reject** (CDS mandates
  parentheses or signed exponents there), and **touches zero existing test data**
  (measured across all CDS/MRT data files). Erroring on an ambiguous input is the
  *safe* choice for a bug whose whole theme is silently-wrong units.

No source edit is warranted: changing anything further would expand scope beyond the
issue and, for the ambiguous F-3 shape, would have to *invent* a semantics the
standard leaves undefined.

## Per-finding next actions

| Finding | Classification | Next action |
|---------|----------------|-------------|
| F-1 | code bug | **Done** — fixed and proved. |
| F-2 | realization step | **Done** — `_tabversion` sentinel forces regen. Keep the explanatory comment so future editors don't "clean it up". |
| F-3 | underspecified intent | **Hold.** Only act if intent says bare `…/…·…` must parse (see below). |
| F-4 | discharged precondition | None — host type satisfies it. |
| F-5 | spec ambiguity | None — confirms the F-3 reject. |
| F-6 | positive confirmation | None. |

## UltimatePowers questions for the intent layer

1. **F-3 / bare division-then-product.** "Should `J/m.s` (a bare product inside a
   `/` denominator, no parentheses) be (a) a parse error [V1, safest], (b) read as
   `J/(m·s)` [V0's denominator-mode], or (c) read left-associatively as `J·s/m`
   [OGIP-style]? The CDS standard does not define it." Default until answered: **(a)**.
2. **Multi-slash policy.** "The generic parser *warns* that multiple slashes are
   discouraged by FITS. Should the CDS reader emit a similar advisory when it accepts
   `a/b/c/…`?" (Currently it accepts silently; out of scope for this fix.)

## If (and only if) intent later chooses F-3 option (c)

The path is to make the grammar **fully left-associative** for both operators
(mirroring the OGIP parser):

```
combined_units   : product_of_units | division_of_units
product_of_units : unit_expression
                 | product_of_units PRODUCT unit_expression
                 | division_of_units PRODUCT unit_expression
division_of_units : DIVISION unit_expression
                 | product_of_units DIVISION unit_expression
                 | division_of_units DIVISION unit_expression
```

This parses `a/b.c` as `(a/b)·c`, removes the F-3 asymmetry, and is conflict-free by
the same FOLLOW-set argument. **Cost:** larger diff, changes the *value* of the
ambiguous F-3 inputs (no canonical answer), and re-folds products left instead of
right (harmless — commutative). **Do not apply without an explicit intent decision**,
because it trades a loud error for a silent guess on undefined input — the opposite
of this issue's lesson. Re-run `(DIVCHAIN)` (unchanged) plus a new mixed-chain claim
if adopted.

## Tests to add / keep / drop

- **Add (intent-pinning):** parametrized `('10+3J/m/s/kpc2', 1e3·J/(m·s·kpc²))` and
  `('10-7J/s/kpc2', 1e-7·J/(s·kpc²))` in `test_cds_grammar` — the exact issue cases.
  (The hidden astropy suite is expected to contain equivalents.)
- **Add (regression guard for F-2):** a test that round-trips a freshly-built parser
  would catch a future re-introduction of the cached-table no-op; optional.
- **Keep:** `test_cds_grammar_fail`, the round-trip/integration MRT tests, and any
  test that pins the F-3 parse-error behaviour.
- **Drop:** nothing now — proof is constructed, not machine-checked (Honesty gate).

## Machine-check to close residual risk

```sh
kompile fvk/mini-cds.k --backend haskell
kprove  fvk/mini-cds-spec.k          # expect #Top for (DIVCHAIN),(LEADDIV),(BUG-V0)
# real-grammar conflict check:
rm astropy/units/format/cds_parsetab.py   # then build with PLY debug=1 → expect 0 conflicts
```
