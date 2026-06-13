# PROOF — V1 fix (constructed, NOT machine-checked)

Symbolic execution of `resolve` (the V1 body, `fvk/mini_combined.k`) against the
claims in `fvk/mini_combined-spec.k`. The fragment is **deterministic** (no
nondeterminism, no loops in the new code), so `[all-path]` ≡ `[one-path]` and
every claim is a finite straight-line reduction. No coinductive circularity is
needed (contrast the `sum` loop example): the only loop in the call graph (the
base method's) is bounded at arity 2 — see PO6/PO7.

Notation: `→` is one `=>` step (Axiom + framing); `⟶*` chains them
(Transitivity). Cells not shown are framed unchanged.

---

## PO1 — claim `FIX-TEMPORAL` : `isTemporal(T)`, `conn=SUB`, `lhs=rhs=T` ⟹ `out=DurationField`

Start `<k> resolve </k> <conn> SUB </conn> <lhs> T </lhs> <rhs> T </rhs> <out> .K </out>`
with side condition `isTemporal(T)` (so `T ∈ {DateField,DateTimeField,TimeField}`,
hence `T ≠ none`, `T ≠ mixed`).

1. `resolve →` the nested-`if` body.
2. **outer guard** `connector eq SUB`: `connector → SUB`; `SUB eq SUB → (SUB ==K SUB) → true`. `if true then … → ` then-branch.
3. **middle guard** `notNone(lhsField) and notNone(rhsField)`:
   `lhsField → T`, `notNone(T) → true` (rule `notNone(F)⇒true requires F≠none`, and `isTemporal(T) ⟹ T≠none`); likewise `rhsField → T → true`. `true and true → true`. ⟶ then-branch.
4. **inner guard** `temporalSet(itype(lhsField)) and (itype(lhsField) eq itype(rhsField))`:
   `itype(lhsField) → itype(T) → T` (rule fires: `T≠none ∧ T≠mixed`);
   `temporalSet(T) → isTemporal(T) → true` (premise);
   `itype(rhsField) → T`; `T eq T → (T ==K T) → true`;
   `true and true → true`. ⟶ then-branch.
5. `return DurationField → .K` with `<out> .K ⇒ DurationField`.

`<k>` is `.K`, `<out> = DurationField`. **∎** Matches the claimed post-state.

> Bug delivered: by the helper rule `baseVal(F,F) ⇒ F`, the *pre-fix* result here
> was `baseVal(T,T) = T` (e.g. `DateTimeField`); V1 yields `DurationField`. The
> change is exactly the `datetime−datetime ↦ duration` promotion of F1.

---

## PO2 + PO3 — claim `DEFER` : `¬isTempSub(C,L,R)` ⟹ `out = baseVal(L,R)`

Start `<k> resolve </k> <conn> C </conn> <lhs> L </lhs> <rhs> R </rhs> <out> .K </out>`,
side condition `¬isTempSub(C,L,R)`, i.e.
`¬(C=SUB ∧ L≠none ∧ R≠none ∧ isTemporal(L) ∧ L=R)`.

`resolve →` body. We must reach `return base` on **every** branch the side
condition allows. Case-split (Case Analysis on the three guards):

- **Branch a — outer guard false** (`C ≠ SUB`, i.e. `C = ADD`):
  `connector → C`; `C eq SUB → (C ==K SUB) → false`; `if false → ` else-branch
  `return base`. (Covers **PO2**.)
- **Branch b — outer true, middle false** (`C=SUB`, and `L=none ∨ R=none`):
  step 2 gives `true`; in step 3, `notNone(none) → false`, so
  `notNone(lhsField) and notNone(rhsField)` evaluates to `false` (whichever side is
  `none`); else-branch `return base`.
- **Branch c — outer+middle true, inner false** (`C=SUB`, `L≠none`, `R≠none`, and
  `¬(isTemporal(L) ∧ L=R)`):
  steps 2-3 give `true`; in step 4, `itype(lhsField) → L`, `itype(rhsField) → R`
  (both defined since `≠none,≠mixed`), guard `temporalSet(L) and (L eq R) →
  isTemporal(L) andBool (L ==K R) → false` (by the branch hypothesis);
  else-branch `return base`.

The three branch hypotheses are exactly the DNF of `¬isTempSub` (outer-false ∨
some-source-none ∨ both-non-none-but-not-(temporal∧equal)), so they are
**exhaustive** under the side condition.

In every branch: `return base`; `base → baseVal(L,R)` (rule reads `<lhs>,<rhs>`);
`return baseVal(L,R) → .K` with `<out> ⇒ baseVal(L,R)` (`baseVal(L,R)` has sort
`Field`, hence a `KResult`, so the `return` rule fires whether or not it further
reduces via `baseVal(F,F)⇒F`). **∎**

This proves the fix returns the **unchanged** base result on the entire
complement of the temporal-subtraction set ⟹ **regression-freedom**.

---

## PO4 — `CONSISTENCY` : `isTempSub(C,L,R) = asSqlTempSub(C,L,R)` for all `C,L,R`

Pure first-order equality over the finite domain `Conn(2) × Field(6) × Field(6)`.
Expand both functions:

```
isTempSub(C,L,R)    = (C=SUB) ∧ (L≠none) ∧ (R≠none) ∧ isTemporal(L) ∧ (L=R)
asSqlTempSub(C,L,R) = (C=SUB) ∧ nnTemporal(L)        ∧ (L=R)
                    = (C=SUB) ∧ (L≠none) ∧ isTemporal(L) ∧ (L=R)   [nnTemporal(L) = (L≠none)∧isTemporal(L)]
```

The two differ only by the conjunct `(R≠none)`, present in `isTempSub`, absent in
`asSqlTempSub`. **Claim:** `(L≠none) ∧ (L=R) ⟹ (R≠none)`. Proof: from `L=R` and
`L≠none`, `R = L ≠ none`. Hence adding/removing `(R≠none)` under the other
conjuncts changes nothing, and the two predicates are equal. Z3 closes the finite
residual instantly; the `[simplification]` rule
`isTempSub(C,L,R) ⇒ asSqlTempSub(C,L,R)` in the spec records it. **∎**

Consequence: the `_resolve_output_field` (V1) and `as_sql` (unchanged) dispatch
decisions are identical on every expression — no type/SQL mismatch is possible.

---

## PO5 — exception behaviour preserved (no new raise, none suppressed)

By the `DEFER` proof, on every non-temporal input the fix evaluates
`super()._resolve_output_field()` and returns its result **verbatim** — so any
`FieldError` the base raises (mixed types) is raised identically, and any field it
returns is returned identically.

The only inputs the fix handles *without* delegating are the temporal-subtraction
set (PO1), where it returns `DurationField` — a value, never an exception, and
exactly the intended promotion.

The single subtlety (F3): when `C=SUB` and an operand *itself* re-raises
`FieldError`, the fix raises from `get_source_fields()` *before* `super()`. But the
base method's first action is the same `get_source_fields()` call, so it raises the
**identical** error. Formally this input sits outside the modelled value domain
(its source has no `Field`/`none` abstraction — it raises); we discharge it by the
observation that the raising sub-step is shared, byte-for-byte, between fix and
base. **∎**

---

## PO6 / PO7 — termination and unpack totality

- **PO7 (arity 2).** `CombinedExpression.get_source_expressions()` returns
  `[self.lhs, self.rhs]` (length 2, lines 439-440), and no subclass overrides it,
  so `get_source_fields()` (a `map` over it) has length 2. The unpack
  `lhs_field, rhs_field = self.get_source_fields()` is therefore total — never a
  `ValueError`. **∎**
- **PO6 (termination).** The new code is straight-line `if/return`. The only loop
  anywhere is the base method's nested generator loop over the (length-2) source
  list; it runs ≤ 1 inner `isinstance` check and returns. Bounded ⟹ halts. No
  decreasing measure / variant is required. **∎**

---

## §6 — Test-redundancy (Benefit 1) — *recommendation only*

The verified contract is a **unit-level, type-inference** property. The relevant
existing tests (`tests/expressions/tests.py`: `test_date_subtraction`,
`test_datetime_subtraction`, `test_time_subtraction`, the `*_subquery_*` and
`test_datetime_subtraction_microseconds`, etc.) assert **end-to-end DB behaviour**
— SQL generation via `subtract_temporals`, microsecond ↔ `timedelta` conversion,
and row values — which lies **outside** this spec's domain (SPEC.md "What is not
specified"). They are therefore **NOT subsumed** by the proof.

- **Remove:** none.
- **Keep (all):** every temporal-subtraction test — they cover the SQL/DB layer
  (OB-SQL) the proof does not, and the typed-`None` / subquery / microsecond
  boundary cases (F5). Integration + value-conversion tests are always kept.
- **CI time saved:** 0 (by design — a unit type-inference proof cannot retire
  integration tests).

Honesty gate: the proof is **constructed, not machine-checked**; even a subsuming
unit proof would gate removal on `kprove` returning `#Top`. Here nothing is
recommended for removal regardless.

---

## §7 — Reproduce the machine check (would upgrade *constructed* → *checked*)

```sh
kompile fvk/mini_combined.k --backend haskell        # compile the fragment semantics
kast    --backend haskell fvk/mini_combined-spec.k   # (optional) parse-check the claims
kprove  fvk/mini_combined-spec.k                     # discharge FIX-TEMPORAL, DEFER; expect #Top
```

**Trusted base / residual risk.** (1) Adequacy of the mini-X abstraction —
fields ↦ `get_internal_type()` strings, base method ↦ black-box `baseVal` — argued
in SPEC.md; (2) the reachability metatheory and `kprove`/Z3 oracle; (3) the
**constructed, not machine-checked** caveat above; (4) partial-vs-total is **moot**
(termination proved, PO6); (5) out-of-scope OB-SQL / OB-ISINSTANCE remain covered
by integration tests, not by this proof.
