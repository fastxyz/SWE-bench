# FVK PROOF OBLIGATIONS — JSONField `has_key` path builders

Each obligation is a verification condition (VC) generated while constructing the
proof of the claims in `fvk/json_path-spec.k`. Status legend: **[Z3]** linear/
string-structural fact for the SMT tier; **[SIMP]** discharged by a
`[simplification]` lemma; **[IND]** list induction via the claim-as-circularity;
**[STRUCT]** discharged by reading the source structure (mini-X adequacy).
All are **constructed, not machine-checked**.

---

## Claim FINALKEY — `compile_json_path_final_key(K) ⇒ segObject(K) ∧ isObjectToken`

| ID | Obligation | Discharge |
|----|------------|-----------|
| O1 | `compile_json_path_final_key(K)` reduces to `"." +String dumps(str(K))`, and for `K:String`, `str(K)=K`, so `= "." +String dumps(K) = segObject(K)` | [STRUCT] direct from the V2 body `".%s" % json.dumps(str(key_transform))` |
| O2 | `isObjectToken("." +String dumps(K)) = true` for every `K:String` | [SIMP] rule `isObjectToken("." +String dumps(_)) => true` — `dumps` of a string is a quoted token |
| O3 | the result has **no** `parsesAsInt`/array branch — numeric `K` is NOT special-cased | [STRUCT] `compile_json_path_final_key` contains no `try int(...)`; the only int branch lives in `compile_json_path` (the navigation builder), not here |

**Precondition obligation O1-pre:** `K` must be a string for O1's `str(K)=K`
collapse and O2. For non-string scalars this is **established by V2's `str()`
coercion** (`str(int)`/`str(float)` is a digit/decimal string). Pre-V2 this VC was
**open** → Finding F-int.

## Claim SEG-VS-OBJECT — numeric key: `seg(K) ≠ segObject(K)`

| ID | Obligation | Discharge |
|----|------------|-----------|
| O4 | under `parsesAsInt(K)`: `seg(K) = "[" +String K +String "]"` and `segObject(K) = "." +String dumps(K)` are distinct strings (different leading char `[` vs `.`) | [Z3] string-structural: `findString("[" …, ".\"",0) ≠ 0` |
| O5 | under `notBool parsesAsInt(K)`: `seg(K) = segObject(K)` (the fix is a **no-op** on non-numeric keys) | [Z3] both equal `"." +String dumps(K)` |

O4 formalizes the *bug* (old numeric final key = array token) and the *fix*
(object token). O5 bounds the change: nothing moves for non-numeric keys.

## Claim HOMO — `cjp(A ++ B) = cjp(A) +String cjp(B)` (the loop invariant)

Proof by induction on `A` (K treats the claim as its own circularity):

| ID | Obligation | Discharge |
|----|------------|-----------|
| O6 | **base** `A = .List`: `cjp(.List ++ B) = cjp(B)` and `cjp(.List) +String cjp(B) = "" +String cjp(B) = cjp(B)` | [SIMP] L2 (left identity `"" +String x => x`) |
| O7 | **step** `A = ListItem(K) A'`: `cjp(ListItem(K) A' ++ B) = seg(K) +String cjp(A' ++ B)` and, by the circularity hypothesis on `A'`, `= seg(K) +String (cjp(A') +String cjp(B))`; reassociate to `(seg(K) +String cjp(A')) +String cjp(B) = cjp(ListItem(K) A') +String cjp(B)` | [IND] hypothesis + [SIMP] L1 (associativity) |
| O8 | **guardedness**: the circularity is used only after the genuine `cjp(ListItem(K) …) => seg(K) +String cjp(…)` rewrite (≥1 step) | [STRUCT] the recursive `cjp` rule is the guard step |

## Claim PRESERVE — `buildPathArr(LJP,NAV,FINAL) = LJP +String cjp(NAV ++ [FINAL])`

| ID | Obligation | Discharge |
|----|------------|-----------|
| O9 | `buildPathArr(LJP,NAV,FINAL) = LJP +String cjp(NAV) +String seg(FINAL)` (def) | [STRUCT] from `buildPathArr` rule + `HasKeyOrArrayIndex.compile_json_path_final_key(K)=compile_json_path([K],False)=seg(K)` |
| O10 | `cjp(NAV) +String seg(FINAL) = cjp(NAV) +String cjp(ListItem(FINAL))` since `cjp(ListItem(FINAL)) = seg(FINAL) +String cjp(.List) = seg(FINAL)` | [SIMP] L2 + cjp base rule |
| O11 | `cjp(NAV) +String cjp(ListItem(FINAL)) = cjp(NAV ++ ListItem(FINAL))` | [IND] HOMO (O6–O8) at `B = ListItem(FINAL)` |
| O12 | compose O9–O11 with L1 to get `LJP +String cjp(NAV ++ [FINAL])` | [SIMP] L1 |

**Consequence:** `HasKeyOrArrayIndex.as_sql` ≡ original `HasKey.as_sql` on all
inputs → the isnull/exact callers are unchanged (Finding F-preserve).

## Claim ASSQL-OBJECT — one rhs-loop iteration (has_key family)

| ID | Obligation | Discharge |
|----|------------|-----------|
| O13 | `buildPathObj(LJP,NAV,FINAL) = LJP +String cjp(NAV) +String segObject(FINAL)` | [STRUCT] `buildPathObj` rule + C1 |
| O14 | `isObjectToken(segObject(FINAL)) = true` for all `FINAL` | [SIMP] = O2 |
| O15 | **loop precondition** `rhs_key_transforms` non-empty at `*nav, final = …` | [STRUCT] both producers yield length ≥ 1 (Finding F-nonempty) — VC **closed**, no guard needed |
| O16 | rhs-loop body does not mutate `rhs`, `lhs_json_path`, or earlier `rhs_params`; iterations are independent ⇒ `rhs_params = [buildPathObj(LJP, nav(k), final(k)) for k in rhs]` | [IND] trivial map circularity over `rhs` |

## Cross-cutting / framing obligations

| ID | Obligation | Discharge |
|----|------------|-----------|
| O17 | param/placeholder count unchanged from pre-fix: the loop still appends exactly one path string per rhs key; the `logical_operator.join` and `tuple(lhs_params)+tuple(rhs_params)` return are untouched | [STRUCT] the edit changed only the *content* of each `rhs_params` entry, not the count or the join/return |
| O18 | `as_postgresql` path independence: it never calls `cjp`/`compile_json_path_final_key` | [STRUCT] separate method using `?`/`?&`/`?|` operators |

## Open / escalated obligations

- **None blocking.** O1-pre was the only open VC pre-V2; V2's `str()` closes it on
  the scalar domain. `has_key=None` (F-none) is **out of domain**, intentionally
  not discharged.
- Backend adequacy of the quoted token `$."1111"` is an **assumption** (same form
  the existing non-numeric `has_key` tests rely on), not a discharged VC.
