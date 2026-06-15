# PROOF_OBLIGATIONS.md

Verification conditions for the claims in `marks-spec.k`. Tiers: **Z3** (linear /
structural), **`[simplification]`** (list-recursive closed form), **`[ESCALATION
BOUNDARY]`** (inductive list/multiset facts beyond the bundled arithmetic tier).

---

## A. (CONCAT) — loop circularity

State: `<store> ml |-> ML, mark_list |-> ACC, i |-> I </store>`, side condition
`0 ≤ I ≤ size(ML)`. Guarded coinduction: evaluate the guard `i < len(ml)` (one genuine
`=>⁺` step) then case-split.

- **PO-C1 (guardedness).** The guard evaluation `I < size(ML)` is ≥ 1 real step before
  the circularity hypothesis is reused. *Discharge:* structural (the `<`/`len` rules
  fire). ✔
- **PO-C2 (body-taken branch, `I < size(ML)`).** After `mark_list = mark_list + ml[i]`
  (⇒ `ACC ++ ML[I]`) and `i = i + 1` (⇒ `I+1`), invoking (CONCAT) on the shifted state
  must yield `ACC concatFrom(ML, I)`. VC:
  `(ACC ++ ML[I]) ++ concatFrom(ML, I+1)  ≡  ACC ++ concatFrom(ML, I)`.
  *Discharge:* `concatFrom` unfold lemma `concatFrom(ML,I) = ML[I] ++ concatFrom(ML,I+1)`
  for `0 ≤ I < size(ML)` (a `[simplification]` rule in VERIFICATION) + associativity of
  list concatenation. The unfold is **Z3/simplification**; associativity of `++` is a
  **builtin LIST** property (K's `List` is associative). ✔
- **PO-C3 (re-establish precondition).** The recursive instance needs `0 ≤ I+1 ≤ size(ML)`
  from `0 ≤ I < size(ML)`. *Discharge:* **Z3** (linear). ✔
- **PO-C4 (exit branch, `I = size(ML)`).** Guard false ⇒ loop ends with `mark_list = ACC`,
  `i = size(ML)`. Need `ACC ++ concatFrom(ML, size(ML)) ≡ ACC`. *Discharge:* base rule
  `concatFrom(ML, I) = .List` for `I ≥ size(ML)`, and `ACC ++ .List = ACC` (**builtin
  LIST** identity). ✔
- **PO-C5 (counter at exit).** `i = size(ML)` matches the post-state. **Z3.** ✔

## B. (GUM) — function contract

- **PO-G1 (compose via Transitivity).** `def` files `get_unpacked_marks`; `call`
  binds `marklists |-> ML` in a fresh frame; init sets `mark_list |-> .List`, `i |-> 0`;
  the loop is discharged by **(CONCAT) used as a lemma** at entry `{ACC := .List, I := 0}`
  (precondition `0 ≤ 0 ≤ size(ML)` by **Z3**); `return mark_list` pops the frame and
  sets `<out>` to `mark_list = .List ++ concatFrom(ML, 0)`. ✔
- **PO-G2 (init closed form).** `.List ++ concatFrom(ML, 0) ≡ concatFrom(ML, 0)`.
  *Discharge:* **builtin LIST** left-identity. ✔
- **PO-G3 (completeness corollary).** For every `k` with `0 ≤ k < size(ML)`, `ML[k]` is a
  contiguous sublist of `concatFrom(ML, 0)`. *Discharge:* induction on `concatFrom`'s
  unfolding (each step prepends exactly `ML[I]`). The closed-form *equality* is
  simplification-discharged (PO-C2); the universally-quantified **sublist/membership**
  statement is an **inductive list predicate** → `[ESCALATION BOUNDARY]` for the bundled
  tier (route to LICS-2013 / list-induction; do **not** `[trusted]`). The structural
  content is, however, *manifest* from the closed form `ML[0]++…++ML[n-1]`. ✔ (structurally),
  ⚠ (machine-checking the ∀k predicate is escalated).

## C. Order obligation (the V1→V2 driver)

- **PO-O1.** `concatFrom(ML, 0) = ML[0] ++ … ++ ML[n-1]` with `ML` in forward MRO order ⇒
  index 0 (most-derived) first. For `Test3(Test1,Test2)`: `ML = [[], [mark1], [mark4], []]`
  ⇒ result `[mark1, mark4]` (intent L4). *Two-column check vs the alternative* (V1
  `reversed`): reversed ⇒ `ML' = [[], [mark4], [mark1], []]` ⇒ `[mark4, mark1]` ≠ L4.
  Forward satisfies L4/L5; reversed satisfies only the SUSPECT L7. ⇒ **forward required.**
  *Discharge:* evaluation of `concatFrom` on the concrete 4-element list (**Z3 /
  simplification**); the intent comparison is in SPEC_AUDIT. ✔

## D. Out-of-K obligations (data-flow, argued in PROOF.md, not in `mini-python.k`)

- **PO-D1 (I-NODUP / diamond).** Because `store_mark` writes each mark only to the
  decorated class's own `__dict__` (`consider_mro=False`), and the read walks `__mro__`
  reading each class's **own** `__dict__["pytestmark"]`, a shared base's mark is read
  exactly once regardless of how many paths reach it. *Discharge:* data-flow argument
  (PROOF.md §4) + the visible test `test_mark_decorator_baseclasses_merged`. Not an
  arithmetic VC.
- **PO-D2 (normalize / non-list).** `normalize_mark_list` and the `isinstance(item, list)`
  guard are identity on the verified domain (entries already `list[Mark]`); off-domain
  entries (a bare `MarkDecorator`, a single mark) are wrapped, never dropped. *Finding
  F2/F4.* Not modeled.

---

## Discharge summary

| VC | Tier | Status |
|----|------|--------|
| PO-C1, C3, C5, G1, O1 | Z3 / structural | constructed ✔ |
| PO-C2, C4, G2 | builtin LIST assoc/identity + `concatFrom` `[simplification]` | constructed ✔ |
| PO-G3 (∀k sublist) | inductive list predicate | **[ESCALATION BOUNDARY]** — structurally manifest, not machine-checked |
| PO-D1, D2 | data-flow / Findings | argued in PROOF.md, not a K VC |

All labeled **constructed, not machine-checked** (MVP runs no `kprove`). The lone escalated
VC (PO-G3 universal) is the *completeness predicate*; its closed-form witness
`ML[0]++…++ML[n-1]` is concrete, so the property is evident even though the ∀-quantified
form needs list induction to discharge formally.
