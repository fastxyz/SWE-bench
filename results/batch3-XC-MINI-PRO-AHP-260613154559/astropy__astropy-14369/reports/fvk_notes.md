# FVK audit notes — astropy/astropy#14369

This applies the Formal Verification Kit methodology to the V1 fix and records every
decision, tracing each to a specific entry in [`fvk/FINDINGS.md`](../fvk/FINDINGS.md)
and [`fvk/PROOF_OBLIGATIONS.md`](../fvk/PROOF_OBLIGATIONS.md).

## Outcome in one line

**V1 stands, unchanged.** The audit proves the fix correct on its specified domain
and shows the one residual behaviour change is out-of-domain and safe. No source file
was modified in this pass.

## What the FVK pass produced

- `fvk/mini-cds.k`, `fvk/mini-cds-spec.k` — a minimal K model of the grammar's
  division reduction. A unit is its exponent vector (free abelian group); the V1
  left-recursive rule is a LEFT fold `pdiv`, the V0 rule a RIGHT fold `pdivR`; the
  homomorphism `expo` turns the contract into linear integer arithmetic.
- `fvk/SPEC.md`, `fvk/FINDINGS.md`, `fvk/PROOF_OBLIGATIONS.md`, `fvk/PROOF.md`,
  `fvk/ITERATION_GUIDANCE.md` — the spec, findings, obligation ledger, constructed
  proof, and next-iteration guidance.

## Decision log (each traced to the artifacts)

### Decision 1 — Keep the V1 grammar change in `cds.py`. **Confirmed correct.**

`p_division_of_units` is left-recursive (`division_of_units DIVISION unit_expression`),
making division left-associative.

- Traces to **F-1** (the reported bug: V0's right-recursion parsed `a/b/c` as
  `a/(b/c)`) and its fix.
- Discharged by **PO-1 / (DIVCHAIN)**: a precondition-free, linear, inductive proof
  that `pdiv(u0,[u1…un]) = u0/(u1·…·un)` for every chain and unit
  ([`fvk/PROOF.md`](../fvk/PROOF.md) §2). The mirror claim **(BUG-V0)** proves the old
  code computed a value differing by `2·expo(last)` — i.e. the exact `J kpc2 / s`
  scrambling in the issue ([`fvk/PROOF.md`](../fvk/PROOF.md) §4).
- A clean, total spec with only linear VCs is the FVK signal that the in-domain logic
  has no missing case (PD-1). → **no change.**

### Decision 2 — Keep the `_tabversion='0.0'` sentinel in `cds_parsetab.py`. **Essential.**

- Traces to **F-2**, the hidden-infrastructure finding: PLY builds the parser with
  `optimize=True`, so at `astropy/extern/ply/yacc.py:3294` it reuses the cached table
  and **ignores grammar edits**. The "obvious" one-line grammar fix would have been a
  silent no-op.
- Discharged by **PO-4 / PO-REGEN** ([`fvk/PROOF_OBLIGATIONS.md`](../fvk/PROOF_OBLIGATIONS.md)
  §PO-4): the sentinel makes `read_table` raise `VersionError` (caught at `:3302`),
  forcing a rebuild from the live grammar on both writable and read-only filesystems.
- This obligation is the one that "nearly slipped through" (PD-2) and is why the fix
  *must* span two files. The explanatory comment is kept so a future editor does not
  "tidy" the sentinel away. → **no change** (removing or simplifying it would
  re-open F-2).

### Decision 3 — Do **not** change product parsing. **Confirmed.**

- `p_product_of_units` is byte-for-byte the V0 rule.
- Traces to **F-6** (product chains unchanged) and **PO-3** (product semantics
  preserved): the only behaviour delta versus V0 is the F-3 parse error; every
  product / product-then-division parse is identical.
- Confirmed safe for the writer round-trip by **PO-7** (CDS `to_string` emits product
  form `J.m-1.s-1.kpc-2`, never `/`-chains) and for the suite by **PO-6** / **PO-8**
  (existing `test_cds_grammar` pass; `test_cds_grammar_fail` still fail). → **no change.**

### Decision 4 — Accept that a *bare* division-then-product (`J/m.s`) now raises.

This is the only behaviour change beyond the bug fix, and the one place a fix or
revision could be argued for. I keep V1.

- Traces to **F-3** and **F-5** (spec-difficulty signal). The string is ambiguous CDS:
  V0 read it `J/(m·s)`; a full-left-associative grammar would read it `J·s/m`; the
  standard defines neither. No clean total spec exists for the shape, so per the FVK
  rule the difficulty is surfaced — and it resolves to "reject", which V1 does.
- **Why not "fix" it by going fully left-associative?** That would *not* restore V0's
  value (it yields a third answer) — it only swaps a loud error for a silent guess on
  undefined input, the exact failure mode this issue is about. It also enlarges the
  diff and changes product fold direction. The path is documented in
  [`fvk/ITERATION_GUIDANCE.md`](../fvk/ITERATION_GUIDANCE.md) but gated on an explicit
  intent decision (UltimatePowers Q1).
- **Blast radius measured (F-3):** every parsed unit column in `cds.dat`, `cds2.dat`,
  `cdsFunctional*.dat`, and `cds/*/ReadMe` uses simple or parenthesized units — none a
  bare `/`-then-`·`. Zero existing tests affected; the standard-sanctioned forms
  `J/(m.s)` and `J.m-1.s-1` both still parse (PO-3). → **no change.**

### Decision 5 — Rely on the host unit type for the group laws. **Discharged, not assumed.**

- Traces to **F-4** / **PO-2-AXIOMS**: (DIVCHAIN) needs `mul` associative with
  identity and `inv` distributing over `mul`. astropy `CompositeUnit` satisfies these
  as real theorems (`(a*b)**-1 == a**-1 * b**-1`), so the proof's side condition is
  met by the value type rather than papered over. → **no change.**

### Decision 6 — Grammar determinism. **Confirmed.**

- Traces to **PO-5 / PO-NO-CONFLICT**: a FOLLOW-set analysis shows PRODUCT/DIVISION
  are not in `FOLLOW(product_of_units)`, so the V1 grammar is LALR(1) with no
  shift/reduce conflict; regeneration yields one unambiguous parse table. → **no change.**

## Residual risk (carried forward honestly)

- The K proofs are **constructed, not machine-checked** (FVK MVP). Run-commands to
  upgrade them are in [`fvk/PROOF.md`](../fvk/PROOF.md) §6. The Findings and the
  code-trace obligations (PO-4, PO-5) do not depend on the machine check.
- Test-redundancy is **recommendation-only and conditioned** on `kprove #Top`; nothing
  is deleted. Out-of-domain (F-3) and failure (PO-8) tests are explicitly kept.

## Bottom line

Every proof obligation is discharged (PROVED, TRACE, or DISCHARGED-BY-HOST) and every
finding is either fixed (F-1), handled (F-2), or a justified out-of-domain acceptance
(F-3/F-5) — so V1 is confirmed and left intact.
