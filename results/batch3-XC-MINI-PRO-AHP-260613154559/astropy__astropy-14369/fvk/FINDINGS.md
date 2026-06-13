# FINDINGS.md — plain-language findings (CDS #14369, V1 audit)

Format: `input → observed vs expected`. Findings are non-blocking advice; they do
not by themselves edit code. Each is tagged with a classification and a disposition.

---

## F-1 — V0 right-associative division (the reported bug). **FIXED in V1.**

- **input:** `u.Unit('10+3J/m/s/kpc2', format='cds')`
  - **observed (V0):** `1e+3 J s / (kpc2 m)` — `s` moved to the numerator.
  - **expected:** `1000 J / (kpc2 m s)`.
- **input:** `u.Unit('10-7J/s/kpc2', format='cds')`
  - **observed (V0):** `1e-7 J kpc2 / s` — `kpc2` moved to the numerator.
  - **expected:** `1e-7 J / (kpc2 s)`.
- **root cause:** `division_of_units : unit_expression DIVISION combined_units` is
  **right-recursive**, so `a/b/c` parsed as `a/(b/c) = a·c/b`. Division is not
  associative; the grouping flips alternate operands into the numerator.
- **classification:** code bug (associativity).
- **disposition:** **fixed** by V1's left-recursive grammar; proven by
  **(DIVCHAIN)** and refuted for V0 by **(BUG-V0)** (see [PROOF.md](PROOF.md)).
  Maps to obligation **PO-1**.

## F-2 — Hidden infrastructure bug: a grammar edit alone is a NO-OP. **HANDLED in V1.**

- **input:** edit the grammar in `cds.py` *only* (leave `cds_parsetab.py` as is).
  - **observed:** the parser still behaves as V0. The cached table is reused.
  - **expected:** the parser reflects the edited grammar.
- **root cause:** `parsing.yacc(...)` calls PLY with `optimize=True`. At
  `astropy/extern/ply/yacc.py:3294`, `if optimize or (read_signature == signature):`
  short-circuits on `optimize`, so PLY loads `cds_parsetab.py` **without comparing
  the grammar signature**. The generated table — not `cds.py` — is the source of
  truth at run time.
- **why this is a classic FVK finding:** the "obvious" one-line grammar fix would
  silently not take effect; the only visible symptom is that nothing changed. The
  spec forced us to ask "is the artifact we proved the artifact that runs?" (PO-REGEN).
- **classification:** needed build/realization step (not a math bug).
- **disposition:** V1 invalidates the cache via `_tabversion = '0.0'`
  (≠ `__tabversion__ = '3.10'`), so `read_table` raises `VersionError`, caught at
  `:3302`, triggering a rebuild from the live grammar (and a rewrite of the table
  when the dir is writable; `IOError` on write is caught at `:3487`). This is the
  in-place equivalent of the module docstring's "remove the file, then rebuild".
  Maps to obligation **PO-4 (PO-REGEN)**.

## F-3 — V1 rejects a *bare* division-then-product. **ACCEPTED (out of clean domain).**

- **input:** `u.Unit('J/m.s', format='cds')` (and `a/b.c`, `a.b/c.d`, `/a.b`).
  - **observed (V1):** `ValueError` (parse error).
  - **observed (V0):** `J / (m s)` — V0 read everything after `/` as denominator.
  - **expected (per a clean spec):** *undefined* — the string is ambiguous CDS.
- **analysis:** fixing the `/`-chain associativity (F-1) requires left-associative
  division; with the product rule left right-recursive, the bare form `…/…·…`
  has no production and is rejected. The three plausible readings disagree:
  V0 `J/(m·s)`, full-left-assoc `(J/m)·s = J·s/m`, denominator-mode `J/(m·s)`.
  Because the readings genuinely conflict, no clean total spec exists for this shape.
- **safety argument:** the CDS standard (catstd-3.2) does **not** sanction a bare
  product in a `/`-denominator — it mandates parentheses `J/(m.s)` or signed
  exponents `J.m-1.s-1`, *both of which V1 still parses correctly*. Silently
  choosing one interpretation is exactly the silently-wrong-units failure mode this
  whole issue is about; **raising is the safe response to an ambiguous input.**
- **blast radius (measured):** every parsed unit column in the repo's CDS/MRT test
  data (`cds.dat`, `cds2.dat`, `cdsFunctional*.dat`, `cds/*/ReadMe`) uses simple or
  parenthesized units — *none* uses a bare `/`-then-`·`. Slashes there occur only in
  catalogue IDs, column labels (`M1/M2`, `[Fe/H]`), and value ranges. Zero existing
  tests are affected.
- **classification:** intentional domain restriction / underspecified intent.
- **disposition:** **kept as-is**; documented. UltimatePowers question in
  [ITERATION_GUIDANCE.md](ITERATION_GUIDANCE.md). Maps to obligations **PO-3** (this
  is the *only* behaviour change beyond F-1) and the domain note in PO-1.

## F-4 — Soundness side condition: the unit value type must be an abelian group.

- **statement:** `(DIVCHAIN)` — that the left fold equals `u0/(u1·…·un)` — relies on
  `mul` being **associative** with **identity** and `inv` distributing over `mul`
  (`inv(a·b)=inv(a)·inv(b)`). These are the analog of the `sum` example's
  `I ≤ N+1` side condition: properties the proof is *forced* to assume.
- **does it hold?** Yes. astropy `Unit`/`CompositeUnit` form a commutative group
  under `*` with `**-1` as inverse; `(a*b)**-1 == a**-1 * b**-1`. So the side
  condition is discharged by the host type, not assumed away.
- **classification:** discharged precondition (positive finding).
- **disposition:** recorded; no code action. Maps to obligation **PO-2-AXIOMS** in
  [PROOF.md](PROOF.md) §3.

## F-5 — Spec-difficulty signal points at the *input*, not the code.

- The only place a clean spec could not be written (F-3, bare `/`-then-`·`) is a
  place where the **input grammar is genuinely ambiguous**, not where the code is
  wrong. Per the FVK rule "spec-difficulty is a bug signal", we surface it — and the
  signal correctly resolves to "reject the ambiguous input", which V1 does.
- **classification:** spec-difficulty / ambiguity.
- **disposition:** no code action; this *confirms* the V1 design choice.

## F-6 — Positive confirmations (no change needed).

- **Leading division** `/u1/…/un = 1/(u1·…·un)`: holds — `(LEADDIV)` = `(DIVCHAIN)`
  at `A = one`. (PO-2.)
- **Product chains unchanged:** `product_of_units` is byte-for-byte the V0 rule, so
  `km.s-1`, `cm.s-2`, `J.m-1.s-1.kpc-2` parse exactly as before. (PO-3.)
- **`to_string` round-trip:** the CDS writer emits *product form with signed integer
  powers* (`J.m-1.s-1.kpc-2`), never `/`-chains, so it is parsed by the untouched
  product rule. `TestRoundtripCDS` and the `io/ascii` MRT write/read tests are
  unaffected. (PO-7.)
- **Failure cases still fail:** `km / s`, `km s-1`, `pix0.1nm`, `5x8+3m`, `[--]`, …
  still raise. (PO-8.)

---

## Proof-derived findings from `/verify`

- **PD-1.** `(DIVCHAIN)` discharges with **no precondition** and only **linear**
  VCs (via the `expo` homomorphism). A precondition-free, linear, inductive proof is
  the strongest possible "this logic is correct for all inputs" signal — it is why
  we can conclude the fix is complete *on its domain* rather than merely
  example-tested.
- **PD-2.** The proof obligation that nearly slipped through is **PO-REGEN**, not any
  arithmetic VC. The lesson for the next code-generation pass: *whenever a generated
  artifact (parse table, pyc, codegen output) shadows the edited source, the
  realization step is itself a proof obligation.*
- **PD-3.** No termination obligation arises: `pdiv`/`pdivR` recurse on a strictly
  shorter `UnitList`, and the real parser is driven by a finite token stream. (Total
  correctness here is immediate; noted, not separately proved.)

## Test-redundancy (benefit 1) — recommendation only, conditioned on machine-checking

If `kprove` returns `#Top` for `(DIVCHAIN)`, then any unit test that merely checks a
single in-domain `/`-chain input→output point (e.g. a parametrized
`('10+3J/m/s/kpc2', 1e3*J/(m*s*kpc**2))`) is **subsumed** by the contract. **Keep**:
the out-of-domain F-3 cases (they pin the parse-error behaviour), the
`test_cds_grammar_fail` set, the round-trip/integration MRT tests, and anything
about scale or factor parsing. **Do not delete anything now** — the proof is
constructed, not machine-checked, and the hidden astropy suite is fixed regardless.
