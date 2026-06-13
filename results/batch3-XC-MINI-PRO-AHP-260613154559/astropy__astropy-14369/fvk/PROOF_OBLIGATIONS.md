# PROOF_OBLIGATIONS.md — what must hold for the V1 fix to be correct

Each obligation lists its statement, how it is discharged, and its status. Status
legend: **PROVED** (constructed K proof), **TRACE** (code-trace / enumeration
argument), **DISCHARGED-BY-HOST** (delegated to a host-library property).
All K results are *constructed, not machine-checked*.

| ID | Obligation | Method | Status |
|----|------------|--------|--------|
| PO-1 | `/`-chain reduces to `u0/(u1·…·un)` | K claim (DIVCHAIN) | PROVED |
| PO-2 | leading `/u1/…/un` reduces to `1/(u1·…·un)` | K claim (LEADDIV) | PROVED |
| PO-2-AXIOMS | unit type is an abelian group (assoc/id/inv-distrib) | host property | DISCHARGED-BY-HOST |
| PO-3 | product semantics unchanged from V0 | code diff inspection | TRACE |
| PO-4 (PO-REGEN) | the edited grammar is the one run at run time | PLY code-trace | TRACE |
| PO-5 (PO-NO-CONFLICT) | V1 grammar is LALR(1)-deterministic | FOLLOW-set analysis | TRACE |
| PO-6 | existing `test_cds_grammar` cases still parse equal | enumeration | TRACE |
| PO-7 | `to_string` output still round-trips | writer-form analysis | TRACE |
| PO-8 | `test_cds_grammar_fail` cases still raise | enumeration | TRACE |

---

## PO-1 — Division chain (the fix). **PROVED (DIVCHAIN).**

For all `A`, `L`, `I`: `expo(pdiv(A,L),I) = expo(A,I) - sumExpo(L,I)`, i.e.
`u0/u1/.../un = u0/(u1·…·un)`. Induction on `L`; base `L=ε` and step
`pdiv(A,X:Xs)⇒pdiv(div(A,X),Xs)` with the circularity on the shifted state. Every
VC is linear integer arithmetic. Full derivation: [PROOF.md](PROOF.md) §2.

**Domain note.** The contract covers pure `/`-chains and (because the product rule's
RHS is `combined_units`) any `product · … / …` shape. A *bare* `…/…·…` is outside
the domain and rejected (F-3); that exclusion is consistent with the CDS standard.

## PO-2 — Leading division. **PROVED (LEADDIV).**

`pdiv(one,L) = 1/(u1·…·un)`. Instance of PO-1 at `A = one`; `expo(one,I)=0`.

## PO-2-AXIOMS — Abelian-group laws. **DISCHARGED-BY-HOST.**

(DIVCHAIN) assumes `mul` associative with identity `one`, and
`inv(mul(a,b)) = mul(inv(a),inv(b))`. astropy `Unit` satisfies these
(`CompositeUnit` multiplication is associative/commutative; `u**-1` is the inverse;
`(a*b)**-1 == a**-1 * b**-1`). The proof never invents the property — it is a real
law of the value type. See [FINDINGS.md](FINDINGS.md) F-4.

## PO-3 — Product semantics unchanged. **TRACE.**

The V1 diff touches only `p_division_of_units`'s docstring. `p_product_of_units`
(`unit_expression PRODUCT combined_units | unit_expression`, action `p[1]*p[3]`) is
byte-for-byte identical to V0. Therefore every product-only and product-then-division
parse is unchanged. The single behaviour change is the F-3 parse error; everything
else is either fixed (PO-1/PO-2) or identical.

## PO-4 / PO-REGEN — The edited grammar is actually run. **TRACE.**

Without regeneration the fix is inert (F-2). Trace through
`astropy/extern/ply/yacc.py`:

1. `parsing.yacc()` calls `yacc.yacc(..., optimize=True, write_tables=True)`.
2. `read_table('astropy.units.format.cds_parsetab')` imports the module and checks
   `parsetab._tabversion != __tabversion__` (`:1987`). V1 set `_tabversion='0.0'`,
   and `__tabversion__='3.10'` (`:70`) → **`VersionError` raised before any stale
   table is loaded** (`:1990` is never reached).
3. The `optimize` short-circuit at `:3294` is never reached because step 2 threw;
   `VersionError` is caught at `:3302` (warning only).
4. Control falls through to the build path (`:3307+`): PLY constructs the LALR
   tables **from the live `cds.py` grammar**, binds the `p_*` actions, returns the
   parser, and (best-effort) rewrites `cds_parsetab.py` with `_tabversion='3.10'`
   and the new tables; a write `IOError` is caught at `:3487` and the in-memory
   parser is used regardless.

So on *every* environment — writable or read-only — the parser in force reflects the
edited grammar. (On a writable FS the stale file self-heals on first build; on a
read-only FS it rebuilds in memory each process.) The file is consumed only by PLY
(`pyproject.toml` merely lint-excludes `*_parsetab.py`), so no other reader sees the
sentinel version. **Discharged.**

## PO-5 / PO-NO-CONFLICT — Deterministic parse. **TRACE.**

V1 grammar fragment:

```
combined_units    : product_of_units | division_of_units
product_of_units  : unit_expression PRODUCT combined_units | unit_expression
division_of_units : DIVISION unit_expression
                  | unit_expression DIVISION unit_expression
                  | division_of_units DIVISION unit_expression
```

FOLLOW sets: `FOLLOW(combined_units)=FOLLOW(product_of_units)={$, ], )}`;
`FOLLOW(division_of_units)={$, ], ), DIVISION}`.

- After a `unit_expression`, the items are `product_of_units→unit_expression .`
  (reduce on `{$,],)}`), `product_of_units→unit_expression . PRODUCT …` (shift
  PRODUCT), `division_of_units→unit_expression . DIVISION …` (shift DIVISION).
  PRODUCT,DIVISION ∉ FOLLOW(product_of_units), so **no shift/reduce conflict**.
- After a `division_of_units`, only `combined_units→division_of_units .` (reduce on
  `{$,],)}`) and `division_of_units→division_of_units . DIVISION …` (shift DIVISION)
  — disjoint lookaheads, **no conflict**.
- The operand `unit_expression` of `… DIVISION unit_expression` sits in a state
  containing only that completed item, so it reduces deterministically; a following
  PRODUCT has no action → the F-3 parse error (a *deterministic* rejection, not a
  conflict).

Hence LALR(1) builds one unambiguous table; regeneration cannot silently pick a
different meaning. **Discharged.** (This is a code-trace argument, not a K proof;
machine confirmation = `kompile`/`kprove` of the real grammar would report zero
conflicts.)

## PO-6 — Existing grammar tests still hold. **TRACE (enumeration).**

`test_cds_grammar` cases re-checked against V1 (none contains a `/`-chain or a bare
`/`-then-`·`):

`0.1nm`✓ `mW/m2`✓ `mW/(m2)`✓ `km/s`✓ `km.s-1`✓ `10pix/nm`✓ `1.5x10+11m`✓ `m2`✓
`10+21m`✓ `2.54cm`✓ `20%`✓ `10+9`✓ `2x10-9`✓ `---`✓ `°/s`✓ `Å/s`✓ `\h`✓
`[cm/s2]`✓ `[K]`✓ `[-]`✓ (single-division and product forms only; all reduce
identically under V1).

## PO-7 — Writer round-trip. **TRACE.**

`CDS.to_string` / `_format_unit_list` join bases with `.` and append `int(power)`
(signed). Output is always product form (`J.m-1.s-1.kpc-2`), never a `/`-chain, so it
re-parses through the untouched product rule. `TestRoundtripCDS.check_roundtrip`,
`check_roundtrip_decompose`, and the `io/ascii` MRT write→read tests are unaffected.

## PO-8 — Failure cases still fail. **TRACE (enumeration).**

`test_cds_grammar_fail` re-checked: `0.1 nm`/`km / s`/`km s-1` (whitespace guard in
`parse`), `solMass(3/2)`/`pix/(0.1nm)` (float inside parens), `pix0.1nm`,
`km*s`/`km**2` (no `*` token), `5x8+3m` (non-base-10 factor), the `---`/`-` shape
errors, `mag(s-1)`/`dB(mW)`/`dex(cm s-2)` (no `UNIT(` production), `[--]` — all still
raise. The V1 division rule adds no production that would accept any of these.
