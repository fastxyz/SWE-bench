# PROOF.md — constructed correctness proof (NOT machine-checked)

Claims: `(CONCAT)` (loop circularity) and `(GUM)` (function contract) in `marks-spec.k`,
over `mini-python.k`. Proof technique: reachability logic + the Circularity rule
(guarded coinduction), exactly the sum-example recipe with **list concatenation** in
place of integer addition.

---

## 1. What is proved

> For the V2 `get_unpacked_marks`, when `obj` is a class, the returned mark list equals
> `mark_lists[0] ++ mark_lists[1] ++ … ++ mark_lists[n-1]`, where `mark_lists[k]` is the
> own `pytestmark` of the k-th class of `obj.__mro__` (forward, most-derived first).
> Hence **every** class in the MRO contributes its marks (completeness — the bug fix),
> in **MRO order** (the maintainer-confirmed order, L4/L5).

## 2. (CONCAT) loop circularity — proof

Goal: from `⟨ while i<len(ml): mark_list=mark_list+ml[i]; i=i+1 ⟩` with
`store = (ml↦ML, mark_list↦ACC, i↦I)` and `0 ≤ I ≤ size(ML)`, reach `mark_list = ACC ++
concatFrom(ML,I)`, `i = size(ML)`.

1. **Guard step (earns the hypothesis).** `seqstrict` heats `i < len(ml)`: `i ↦ I`,
   `len(ML) ↦ size(ML)`, then `I < size(ML)` reduces to a Bool. This is the genuine
   `=>⁺` step, so (CONCAT) becomes available as a coinduction hypothesis (guardedness;
   PO-C1).
2. **Case split** (`#Or`, Case Analysis) on `I < size(ML)`:
   - **Body-taken (`I < size(ML)`).** Run the body:
     `mark_list = mark_list + ml[i]` → `ml[i]` reads `ML[I]`, `+` concatenates →
     `mark_list ↦ ACC ++ ML[I]`; then `i = i + 1` → `i ↦ I+1`. The state is the loop
     again with `ACC' = ACC ++ ML[I]`, `I' = I+1`. **Invoke (CONCAT)** on it (legal:
     guardedness paid in step 1; precondition `0 ≤ I+1 ≤ size(ML)` from `0 ≤ I <
     size(ML)`, PO-C3, Z3). Hypothesis gives `mark_list = (ACC ++ ML[I]) ++
     concatFrom(ML, I+1)`. By the `concatFrom` unfold `concatFrom(ML,I) = ML[I] ++
     concatFrom(ML,I+1)` and associativity of `++` (PO-C2), this equals `ACC ++
     concatFrom(ML, I)`. ✔
   - **Exit (`I = size(ML)`).** Guard false; loop terminates. `concatFrom(ML, size(ML))
     = .List` (base rule), and `ACC ++ .List = ACC` (PO-C4). Post-state `mark_list = ACC
     = ACC ++ concatFrom(ML, I)`, `i = size(ML)`. ✔
   Both branches reach the claimed post-state ⇒ (CONCAT) holds (partial correctness).

## 3. (GUM) function contract — proof

By Transitivity (PO-G1): `def` files the function; `call get_unpacked_marks(ML)` binds
`marklists ↦ ML` in a fresh frame (saving the caller frame on `<stack>`); the body inits
`mark_list ↦ .List`, `i ↦ 0`. The loop is discharged by **(CONCAT) as a lemma** at entry
`{ACC := .List, I := 0}` (precondition `0 ≤ 0 ≤ size(ML)`, Z3), giving `mark_list = .List
++ concatFrom(ML, 0) = concatFrom(ML, 0)` (left-identity, PO-G2). `return mark_list` pops
the frame and sets `<out> = concatFrom(ML, 0)`. ∎

**Completeness corollary (PO-G3).** `concatFrom(ML, 0) = ML[0] ++ ML[1] ++ … ++
ML[n-1]`. Each `ML[k]` is a contiguous sublist ⇒ no class's marks are dropped. The
closed form is a concrete witness; the ∀k sublist *predicate* is an inductive list fact
marked `[ESCALATION BOUNDARY]` (route to list induction), but the structural content is
manifest from the closed form.

**Order corollary (PO-O1).** Index 0 (most-derived) contributes first. Concrete check —
`Test3(Test1, Test2)`, `ML = [[], [mark1], [mark4], []]`:
`concatFrom(ML,0) = [] ++ [mark1] ++ [mark4] ++ [] = [mark1, mark4]` = intent L4. ✔
The V1 `reversed` alternative computes over `[[], [mark4], [mark1], []]` ⇒ `[mark4,
mark1]` ≠ L4. **This two-column derivation is why V2 replaces `reversed(obj.__mro__)`
with `obj.__mro__`.**

## 4. Out-of-K argument — no-duplication in diamonds (PO-D1)

Not expressible as an arithmetic VC; established by data flow:

- `store_mark(obj, mark)` writes `obj.pytestmark = [*get_unpacked_marks(obj,
  consider_mro=False), mark]`. With `consider_mro=False`, the read side touches only
  `obj.__dict__.get("pytestmark", [])` — the class's **own** namespace. So a mark applied
  to class `K` lands **only** in `K.__dict__["pytestmark"]`, never copied into subclasses'
  `__dict__`.
- The read side (`consider_mro=True`) iterates `obj.__mro__` and reads each class's
  **own** `__dict__["pytestmark"]`. A class appears **once** in an MRO (C3 linearization),
  so each `K.__dict__["pytestmark"]` is read once ⇒ each mark appears once, regardless of
  how many inheritance paths reach `K`. This discharges the diamond concern L6 *without*
  any value-based de-duplication (which could wrongly drop intentionally-repeated marks).
- Cross-check (visible test) `test_mark_decorator_baseclasses_merged`: `object←Base(@a)
  ←Base2(@b)←Test1(@c)` ⇒ `{a,b,c}`; the diamond-free linear chain yields no duplicate,
  matching the set assertion. ✔

## 5. Plain-language payoffs

- **Benefit 2 (bug found).** Writing the completeness obligation I-COMPLETE made the
  original bug precise: the legacy `getattr(cls, "pytestmark")` returns only the **first**
  MRO entry that defines `pytestmark`, i.e. `concatFrom` truncated to one index — every
  other base's marks dropped. The clean spec is `concatFrom(ML, 0)` over the **whole**
  MRO; anything less is the bug. Formalizing the **order** further surfaced that the V1
  patch, while fixing completeness, used `reversed` and therefore violated the
  maintainer-confirmed `[mark1, mark4]` order — fixed in V2.
- **Benefit 1 (tests).** See ITERATION_GUIDANCE §Tests: the set-based
  `assert_markers` cases are subsumed by (GUM) completeness *once machine-checked*; keep
  them until `kprove` returns `#Top` and keep all order/closest/non-class tests.

## 6. Residual risk / trusted base

- **Constructed, not machine-checked** — no `kprove` run in this MVP. Run:
  ```sh
  kompile mini-python.k --backend haskell
  kast    --backend haskell marks-spec.k
  kprove  marks-spec.k          # expected: #Top
  ```
- **Partial correctness** — termination of the `while` (it decreases `size(ML) - i`,
  bounded ≥ 0) is *recommended* not proved (default scope).
- **Fragment adequacy** — `mini-python.k` models the flattening loop and list concat;
  the MRO-comprehension and `normalize_mark_list` are argued at the source level (§4,
  Findings F2/D2), not in K. PO-G3's universal sublist predicate is escalated, not
  machine-closed.
- **Trusted:** K reachability metatheory, Z3, the `concatFrom` `[simplification]` lemmas,
  and the faithfulness of the fragment to CPython's `__mro__` / `__dict__` semantics.
