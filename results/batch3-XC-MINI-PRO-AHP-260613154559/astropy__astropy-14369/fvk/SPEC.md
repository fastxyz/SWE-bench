# SPEC.md — formal specification of the CDS division-chain fix

*Target:* astropy `5.1`, issue **astropy/astropy#14369** — "Incorrect units read
from MRT (CDS format) files". V1 fix applied in
`astropy/units/format/cds.py` (grammar) and
`astropy/units/format/cds_parsetab.py` (forced table regeneration).

*Status:* **constructed, not machine-checked** (FVK MVP does not run `kompile`/`kprove`).

---

## 1. What is being formalized

The bug lives in the PLY/yacc grammar of the CDS unit-format parser. The unit of
work is the reduction of a **division chain**

```
u0 / u1 / u2 / ... / un          (n >= 1)
```

into an astropy `Unit`. Two things must be specified:

1. **Semantics (the math).** What `Unit` value the grammar's reduction *actions*
   compute for such a chain — and that the V1 grammar computes the *intended*
   value while the V0 grammar did not.
2. **Realization (the infrastructure).** That the edited grammar is actually the
   one used at run time, given PLY's cached parser table and `optimize=True`.

Both are in scope; (2) is unusual but essential — without it the grammar edit is a
no-op (see [FINDINGS.md](FINDINGS.md) F-2).

## 2. Intent (from the issue + the CDS standard)

The CDS/MRT standard writes SI units without spaces; a surface brightness
`erg/AA/s/kpc^2` is written `10+3J/m/s/kpc2`. The reporter's expectation:

> The units in the resulting Table should be the same as in the input MRT file.

So a `/`-chain accumulates a single denominator:

```
u0/u1/.../un   ==   u0 / (u1 · u2 · … · un)          (INTENDED)
```

Concretely:

| input string         | intended Unit                 | V0 (buggy) produced            |
|----------------------|-------------------------------|--------------------------------|
| `10+3J/m/s/kpc2`     | `1000 J / (kpc2 m s)`         | `1e+3 J s / (kpc2 m)`  ✗       |
| `10-7J/s/kpc2`       | `1e-7 J / (kpc2 s)`           | `1e-7 J kpc2 / s`      ✗       |

This is left-associative division (`((u0/u1)/u2)/…`), which equals
`u0/(u1·…·un)` because units form an **abelian group** under multiplication. It
also matches the sibling OGIP parser (`erg /pixel /s /GHz == erg/(pixel·s·GHz)`).

## 3. Model (mini-CDS) and fidelity

`fvk/mini-cds.k` is the minimal K fragment. An astropy unit is
`scale × (free abelian group on base-unit symbols)`. Division is
`a / b ≡ mul(a, inv(b))` — exactly the Python action `p[0] = p[1] / p[3]` on `Unit`
objects. A unit is observed through `expo(U, i)` = the integer exponent of base
generator `i`. `expo` is a homomorphism into `(ℤ, +)`, so every group identity we
need collapses to **linear integer arithmetic**.

The grammar's two reduction strategies are modeled as folds over the operand list:

| model    | grammar rule it mirrors                              | fold  |
|----------|------------------------------------------------------|-------|
| `pdiv`   | V1 `division_of_units : division_of_units DIVISION unit_expression` | LEFT  |
| `pdivR`  | V0 `division_of_units : unit_expression DIVISION combined_units`    | RIGHT |

**Model fidelity / what is deliberately omitted.**

- *Scale factor* (the `10+3` prefix). Parsed separately by `p_factor` and combined
  once at `p_main` via `Unit(p[1] * p[2])`; it is an independent positive-rational
  abelian coordinate, untouched by division associativity. Omitting it loses no
  generality — the proof replays coordinate-wise.
- *Commutativity of `mul`.* Not even required for (DIVCHAIN): re-associating the
  left-nested fold to `mul(A, inv(prod L))` needs only **associativity**,
  **identity**, and **inv-distributes-over-mul**. (Commutativity *is* a real
  property of the unit group and is what makes the printed order in the table
  irrelevant, but the contract does not lean on it.)
- *The lexer, factor grammar, parentheses, brackets/dex, dimensionless.* Unchanged
  by the fix; out of scope for the division-chain contract (their preservation is
  obligations PO-6…PO-8 in [PROOF_OBLIGATIONS.md](PROOF_OBLIGATIONS.md), discharged
  by enumeration rather than by the K model).

## 4. The formal claims (see `fvk/mini-cds-spec.k`)

**(DIVCHAIN)** — the contract the V1 fix must meet. For all `A`, `L`, `I`:

```
expo(pdiv(A, L), I)  =>  expo(A, I) -Int sumExpo(L, I)        [all-path]
```

i.e. `pdiv(u0,[u1,…,un]) = u0 / (u1·…·un)`, observed exponent-by-exponent.
**No `requires`** — it holds for every input. A clean, total, precondition-free
spec is itself the signal that the in-domain division logic has no missing case.

**(LEADDIV)** — leading slash `/u1/…/un = 1/(u1·…·un)` is `(DIVCHAIN)` at `A = one`.

**(BUG-V0)** — refutation witness. For a 2-operand chain the V0 right fold computes

```
expo(pdivR(A, X1:X2:·), I)  =>  (expo(A,I) -Int expo(X1,I)) +Int expo(X2,I)
```

which differs from `(DIVCHAIN)` by `2·expo(X2,I)` — wrong whenever `X2` is a real
base unit (`expo = 1`). This is the bug, formalized.

## 5. Plain-English spec note (for a developer who never opens the `.k`)

- **`pdiv` / V1 division** — "Reading `u0/u1/.../un` divides `u0` by the product of
  *all* of `u1…un`." Proven for every chain length and every unit. This is what the
  table reader now does.
- **`pdivR` / V0 division** — "Reading `u0/u1/.../un` divided by `u1`, then *multiplied*
  back by `u2`, divided by `u3`, …" — the alternating sign that scrambled `SBCONT`
  and `SBLINE`. Proven *different* from the intended value.
- **Domain.** The clean contract covers `/`-chains, `·`-chains, parenthesized
  sub-units, and any `…·…/…` (product followed by division). The one shape **outside**
  the clean domain is a *bare* division-then-product `u0/u1·u2` (no parentheses),
  which the CDS standard does not sanction (it mandates parentheses or signed
  exponents for a compound denominator). V1 rejects it with a parse error rather
  than silently guess — see [FINDINGS.md](FINDINGS.md) F-3/F-5.

## 6. Infrastructure precondition (must hold for §4 to matter)

**PO-REGEN.** *The grammar object actually executed at run time is the one written
in `cds.py`.* PLY builds the parser with `optimize=True`
(`astropy/utils/parsing.py`), which makes it **reuse the cached
`cds_parsetab.py` verbatim and skip the grammar-signature check**
(`astropy/extern/ply/yacc.py:3294`). The fix therefore also invalidates the cache
(`_tabversion = '0.0' ≠ __tabversion__ = '3.10'`) so `read_table` raises
`VersionError`, which `yacc()` catches (`:3302`) and rebuilds from the live grammar.
Proof obligation discharged by code-trace in [PROOF.md](PROOF.md) §4.

**PO-NO-CONFLICT.** *The V1 grammar is LALR(1)-deterministic*, so regeneration
yields one well-defined parse per input (no silent shift/reduce resolution changing
meaning). Discharged by FOLLOW-set analysis in [PROOF.md](PROOF.md) §5.
