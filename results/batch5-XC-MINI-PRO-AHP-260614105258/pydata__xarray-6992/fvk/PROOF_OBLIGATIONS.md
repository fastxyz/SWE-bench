# PROOF OBLIGATIONS — `reset_index` invariant preservation

Notation (from `SPEC.md` §3): `V = keys(self._variables)`, `C = self._coord_names`,
`D = set(drop_variables)`, `N = set(new_variables)`. The fixed tail computes
`Vk = (V − D) ∪ N` (`= keys(variables)`) and `Cn = (C − D) ∪ N` (`= coord_names`).

Status legend: **DISCHARGED** (closed by the constructed proof, modulo the
"constructed, not machine-checked" caveat) · **COROLLARY** · **ASSUMED**
(precondition / trusted base) · **OUT-OF-SCOPE**.

---

### PO-PRE — Input well-formedness (precondition)
`C ⊆ V`. **ASSUMED** — the class invariant on the input Dataset (FINDINGS F4/F6).
Used by PO1 case (ii). Not repaired by `reset_index`; preserved by it.

### PO1 — INV preservation (headline) — `Cn ⊆ Vk`
Prove `(C − D) ∪ N ⊆ (V − D) ∪ N` given `C ⊆ V`.
**Status: DISCHARGED.** Proof (PROOF §2): take `x ∈ (C−D)∪N`.
(i) `x ∈ N` ⇒ `x ∈ (V−D)∪N`. (ii) `x ∈ C−D` ⇒ `x ∈ C ⊆ V` and `x ∉ D` ⇒
`x ∈ V−D ⊆ (V−D)∪N`. ∎  VC closed by lemmas L1 (difference monotone) + L3 (union
monotone) + L2 (union superset) in `reset_index-spec.k`. Traces I1, I3.

### PO2 — Created coordinates stay coordinates — `N ⊆ Vk` and `N ⊆ Cn`
`N ⊆ (V−D)∪N` and `N ⊆ (C−D)∪N` hold **unconditionally** (union superset, L2),
**including when `N ∩ D ≠ ∅`**. **Status: DISCHARGED (V2).**
Under the V1 form `Cn=(N∪C)−D` this obligation **FAILS** for `x ∈ N∩D`
(`x` removed from `Cn` by `−D`) — see FINDINGS F3/F8. The V2 reordering
`(C−D)∪N` is what discharges PO2. Traces I5, F3.

### PO3 — Drop semantics — for `x ∈ D \ N`: `x ∉ Vk` and `x ∉ Cn`
`x ∈ D, x ∉ N` ⇒ `x ∉ (V−D)` and `x ∉ (C−D)`, and `x ∉ N`, so `x ∉ Vk` and
`x ∉ Cn`. **Status: DISCHARGED.** Matches docstring `drop=True` semantics and
`test_dataarray::test_reset_index` case 5 (`D={x}, N=∅ ⇒ Cn=C∖{x}`). Traces I6, I7.

### PO4 — Frame condition for `drop=False` — behaviour unchanged
When `drop=False`, `D = ∅`, hence `Vk = V ∪ N`, `Cn = C ∪ N`, identical to the
pre-fix expression `set(new_variables) | self._coord_names`. **Status:
DISCHARGED** (syntactic identity on `D=∅`). Guarantees every `drop=False` test
(`test_reset_index` cases 1–4, `test_reset_index_keep_attrs`, the `test_units`/
`test_sparse` paths) is unaffected. Traces I6.

### PO5 — `DataVariables.__len__ ≥ 0`
`Vk, Cn` finite and `Cn ⊆ Vk` (PO1) ⇒ `|Vk| − |Cn| ≥ 0`. **Status: COROLLARY of
PO1.** This is exactly `len(_variables) − len(_coord_names) ≥ 0`, eliminating the
reported `ValueError`. Traces I2, I4.

### PO6 — MVCE discharges — `reset_index("z", drop=True)` after `set_index(z=['a','b'])`
Instantiate PO1 at `C={z,a,b}`, `V={z,a,b}`, `D={z}`, `N={}`:
`Cn = ({z,a,b}∖{z})∪∅ = {a,b}`, `Vk = {a,b}`, `Cn ⊆ Vk` ✓, `__len__ = 0`.
**Status: DISCHARGED.** Trace I3 (PROOF §3).

### PO7 — `set_index` consistency
After V2, `reset_index` and `set_index` (line 4102) use the same idiom
`(C − D) | N`. `set_index` independently maintains INV (FINDINGS F6).
**Status: DISCHARGED** (shared form). Trace I5.

### PO8 — Adequacy of the loop abstraction
The `for name in dims_or_levels` loop is modelled by its outputs `(D, N)` rather
than stepped. **Status: ASSUMED (trusted base).** Justification (PROOF §4): the
loop writes only `drop_indexes`, `drop_variables`, `replaced_indexes`,
`new_indexes`, `new_variables`; it never reads or writes `coord_names`/`variables`,
which are computed *after* it. PO1–PO5 are independent of *how* `D, N` are formed
— they hold for arbitrary finite `D, N`. So abstracting the loop loses nothing for
the invariant. (A *semantic* spec of which names land in `D`/`N` is OUT-OF-SCOPE,
see PO9.)

### PO9 — Full semantic correctness of which names are kept/dropped/recreated
A complete contract for the *values* of `D, N` (e.g. "`drop=True` on a 3-level
multi-index dim+level should/shouldn't keep a reduced index") depends on multi-
index design intent that the issue does not pin down. **Status: OUT-OF-SCOPE** for
#6992. Captured as an UltimatePowers question in `ITERATION_GUIDANCE.md`. The
invariant (PO1) and P2 (PO2) hold for *whatever* `D, N` the existing logic emits,
so the fix is safe regardless of how PO9 is eventually resolved.

### PO10 — `dims` consistency after `_replace`
`reset_index` keeps `self._dims`. **Status: OUT-OF-SCOPE / pre-existing (F5);**
benign because every reachable output retains ≥1 variable per surviving dim. No
INV impact.

---

## Summary

| PO | property | status |
|---|---|---|
| PO-PRE | `C ⊆ V` (input INV) | ASSUMED (class invariant) |
| **PO1** | `coord_names ⊆ keys(variables)` | **DISCHARGED** |
| **PO2** | recreated coords stay coords (`N ∩ D` corner) | **DISCHARGED (V2 only)** |
| PO3 | drop=True removes named coords | DISCHARGED |
| PO4 | drop=False unchanged | DISCHARGED |
| PO5 | `__len__ ≥ 0` | COROLLARY of PO1 |
| PO6 | MVCE | DISCHARGED |
| PO7 | parity with `set_index` | DISCHARGED |
| PO8 | loop-abstraction adequacy | ASSUMED (justified) |
| PO9 | full keep/drop value semantics | OUT-OF-SCOPE |
| PO10 | `dims` recompute | OUT-OF-SCOPE (F5) |

The two obligations that *decide the fix* are **PO1** (the bug) and **PO2** (the
corner that motivates V2's `(C−D)∪N` over V1's `(N∪C)−D`).
