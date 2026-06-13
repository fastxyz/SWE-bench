# PROOF — constructed, not machine-checked

Discharges the obligations in [`PROOF_OBLIGATIONS.md`](PROOF_OBLIGATIONS.md) for the
contracts in [`SPEC.md`](SPEC.md), against the fragment
[`schema_index.k`](schema_index.k) / claims
[`schema_index-spec.k`](schema_index-spec.k).

> **Honesty gate.** The K toolchain is **not** run in this environment. Every result
> below is **constructed, not machine-checked**. The only verification conditions are
> finite **set-cardinality** facts (no loops over unbounded integers, no division),
> so the proof is short and Z3-discharge­able once `cnames` is unfolded. To
> machine-check:
> ```sh
> kompile schema_index.k --backend haskell
> kast    --backend haskell schema_index-spec.k
> kprove  schema_index-spec.k          # expected: #Top
> ```

---

## 1. OB-FILTER — the scan loop (circularity)

Claim `(FILTER)`: `⟨filter, cons=CS, result=R⟩ ⇒ ⟨checkDelete, cons=.Cons,
result = R ∪ cnames(CS,COLS,KW,EXCL)⟩`.

By guarded coinduction on `CS` (the kit's Circularity rule):

- **Base** `CS=.Cons`: the rule `filter ⇒ checkDelete` fires; `result` unchanged;
  `cnames(.Cons,…)=.Set`, so `R ∪ .Set = R`. ✓ (zero-step exit; matches the post.)
- **Step** `CS = C ; REST`: one genuine `=>⁺` step consumes the head `C`
  (guardedness paid). Case-split on `matches(C,COLS,KW,EXCL)` (`#Or`):
  - *match*: `result := R SetItem(nameOf(C))`; invoke the circularity on the
    shifted state `⟨cons=REST, result=R∪{nameOf(C)}⟩`, reaching
    `R∪{nameOf(C)}∪cnames(REST,…)`. By the matching `cnames` rule this equals
    `R∪cnames(C;REST,…)`. ✓
  - *no match*: `result` unchanged; circularity gives `R∪cnames(REST,…)`, and the
    non-matching `cnames` rule gives `cnames(C;REST,…)=cnames(REST,…)`. ✓

Both branches land on the claimed post-state. ∎

This reduces every `size(result)` goal below to `size(cnames(CS,COLS,KW,EXCL))`.

---

## 2. The matching predicate, unfolded

From `schema_index.k`, for a constraint over the target columns
(`CC ==K COLS`, `NAME ∉ EXCL`):

```
matches(con(_, (a,b), U, IX), (a,b), idxFilter,   EXCL) = IX ∧ (U == false)
matches(con(_, (a,b), U, IX), (a,b), idxFilterV0, EXCL) = IX
matches(con(_, (a,b), U, IX), (a,b), uniqFilter,  EXCL) = U
```

Apply to the two scenario constraints `c_uniq=(unique=True,index=IU)` and
`c_idx=(unique=False,index=True)`:

| constraint | `idxFilter` (V1) | `idxFilterV0` (pre-fix) | `uniqFilter` |
|---|---|---|---|
| `c_uniq` (U=T, IX=IU) | `IU ∧ ¬T = False` | `IU` | `True` |
| `c_idx`  (U=F, IX=T)  | `T ∧ ¬F = True`  | `True` | `False` |

This single table discharges OB1–OB4, OB7, OB8 by reading off columns.

---

## 3. DEL-IDX (OB1, OB2) — V1 index deletion is exactly-one, every backend

From the `idxFilter` column: `c_uniq → False`, `c_idx → True`, **independently of
`IU`**. So
`cnames(CS,(a,b),idxFilter,EXCL) = {name_idx}` ⇒ `size == 1`.

- **OB1** (≥1): `name_idx ∈` the set. ✓
- **OB2** (≤1): `c_uniq` excluded because `U==True` makes `U==false` false; no
  other same-column constraint exists in-domain. ✓

`(DEL-IDX)`: the guard `size==1` fires the `deleted(R)` rule with
`R = {name_idx}`. The `filter ⇒ checkDelete ⇒ deleted(SetItem("t_idx"))` path of
the claim holds for symbolic `IU`. ∎

**Plain language:** with the fix, deleting the `index_together` always finds the one
non-unique `_idx` index and drops exactly it — on MySQL, SQLite, and PostgreSQL
alike — whether or not a `unique_together` sits on the same columns.

---

## 4. DEL-UNIQ (OB3, OB4) — the unchanged path is already exactly-one

From the `uniqFilter` column: `c_uniq → True`, `c_idx → False`, independently of
`IU`. So `cnames(CS,(a,b),uniqFilter,EXCL) = {name_uniq}` ⇒ `size == 1`.

`(DEL-UNIQ)` reaches `deleted(SetItem("t_uniq"))`. ∎

**Why `alter_unique_together` needs no edit:** a non-unique index never satisfies
`unique=True`, so the unique filter was never ambiguous. The asymmetry is the whole
story (Finding F1): *a unique constraint can masquerade as an index (`index=True`),
but an index never masquerades as unique (`unique` stays `False`)* — so only the
index-deletion direction could over-match, and only it needed the extra guard.

---

## 5. OB5 — no-regression (monotonicity of the added guard)

For every `C` over the target columns,
`matches(C,·,idxFilter,·) = IX∧¬U` and `matches(C,·,idxFilterV0,·) = IX`, so
`matches(C,idxFilter) → matches(C,idxFilterV0)`. Hence
`cnames(·,idxFilter,·) ⊆ cnames(·,idxFilterV0,·)`: the V1 set is a **subset** of the
old one. Concretely it removes exactly the `unique=True` rows. Therefore:

- if the old set was `{name_idx}` (PostgreSQL, or no unique_together), V1 keeps it
  → size still 1, **no behavior change**;
- if the old set was `{name_uniq, name_idx}` (MySQL/SQLite crash), V1 → `{name_idx}`
  → size 1, **crash fixed**.

V1's match set is never larger than V0's, so the fix cannot create a *new*
"too many constraints" failure. ∎

---

## 6. OB7 (crash reproduced & fixed) and OB8 (latent hazard closed)

- **OB7 / `(DEL-IDX-V0)`:** pre-fix filter, `IU=True`. The `idxFilterV0` column gives
  `c_uniq → True`, `c_idx → True` ⇒ `cnames = {name_uniq, name_idx}`, `size==2` ⇒
  `valueError(2)`. This is *exactly* the reported "Found wrong number (2) of
  constraints". §3 shows V1 collapses it to size 1. ∎
- **OB8 / `(DEL-IDX-DRIFT)`:** only `c_uniq` present, `IU=True`. Pre-fix:
  `cnames={name_uniq}`, size 1 ⇒ would `DROP INDEX name_uniq` (silently deleting the
  unique constraint — a wrong, data-affecting deletion). V1: `idxFilter` gives
  `c_uniq → False` ⇒ `cnames={}`, size 0 ⇒ `valueError(0)` — a safe loud failure.
  V1 is strictly safer here, never worse. ∎

---

## 7. OB6 — preconditions actually hold (not just assumed)

`index_together` ⇒ one non-unique `_idx` index per tuple (de-duped by the set
`news.difference(olds)`); `unique_together` ⇒ one unique constraint per tuple; any
`Meta.indexes`/`Meta.constraints` collision is name-excluded. With OB2/OB4 this
yields `size==1` for both filters in the real scenario. So PRE-IDX and PRE-UNIQ are
discharged at the Django level, not merely posited. ∎

---

## 8. What is proved, and residual risk

**Proved (constructed):** with the V1 fix, `_delete_composed_index` resolves to
**exactly one** constraint and drops the intended one in the entire in-domain
scenario of the bug — index deletion finds only the non-unique `_idx` (DEL-IDX,
every backend), unique deletion finds only the unique constraint (DEL-UNIQ). The
pre-fix crash is reproduced (DEL-IDX-V0) and shown removed; a latent wrong-deletion
is shown closed (DEL-IDX-DRIFT). The fix is monotone — it can only shrink the match
set, so it introduces no new failure (OB5).

**Conclusion: V1 is CONFIRMED.** The audit found no correctness defect in the V1
change and a positive secondary improvement (OB8). No source edit is warranted by
the obligations.

**Residual risk (honest):**
1. Out-of-domain edges F5 (unique_together on PK columns) and F8 (a second
   independent non-unique composite index on identical columns) — pre-existing,
   not reachable from the issue, not touched by V1; see [`FINDINGS.md`](FINDINGS.md)
   and [`ITERATION_GUIDANCE.md`](ITERATION_GUIDANCE.md).
2. Issue point 2 (no-op index *re-creation* on declaration move) — out of scope for
   the schema editor; an autodetector concern (F6).
3. Trusted base: mini-fragment adequacy, the introspection facts read from source
   (SPEC §2), K metatheory, and **constructed, not machine-checked**.

---

## 9. Test-redundancy note (benefit 1 — recommendation only)

The project's hidden test suite is **fixed and not modifiable here**, so this is
advisory only and **conditioned on machine-checking** the claims above:

- A unit test that asserts "removing an `index_together` while a `unique_together`
  exists on the same fields does **not** raise and drops the index" is **subsumed**
  by `(DEL-IDX)` once `kprove` returns `#Top` — it is a single in-domain point of a
  contract proved for all `IU`.
- **Keep** (not subsumed): the symmetric removal test (`(DEL-UNIQ)` is a *different*
  contract), any out-of-domain tests for F5/F8, and end-to-end migration/autodetector
  tests (they exercise wiring and operation ordering, not this unit).

Per the honesty gate: **recommend, never delete**; keep all tests until the emitted
`kprove` commands actually return `#Top`.
