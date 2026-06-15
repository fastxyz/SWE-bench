# SPEC.md — get_unpacked_marks / MRO mark collection

Target: `repo/src/_pytest/mark/structures.py` — `get_unpacked_marks(obj, *, consider_mro=True)`
and its companion `store_mark(obj, mark)`.

Formal artifacts: `mini-python.k` (semantics fragment), `marks-spec.k` (claims `(CONCAT)`, `(GUM)`).

---

## 1. Public intent ledger

| # | Source | Quoted evidence | Semantic obligation | Status |
|---|--------|-----------------|---------------------|--------|
| L1 | prompt (title) | "Consider MRO when obtaining marks for classes" | When `obj` is a class, marks must be gathered by walking its **MRO**, not by a single attribute lookup. | encoded (GUM) |
| L2 | prompt | "inheriting from both of those baseclasses will lose the markers of one of those classes" … "I'd expect `foo` and `bar` to be markers for `test_dings`" | **Completeness**: the result must contain the marks of **every** class in the MRO; none dropped. | encoded (GUM completeness corollary) |
| L3 | hints (maintainer) | "the marks have to transfer with the mro, its a well used feature and its a bug that it doesn't extend to multiple inheritance" | Single-inheritance transfer (already working) must keep working; the fix **extends** it to multiple inheritance. Frame condition: *transfer/completeness*, not a specific legacy list order. | encoded (GUM); frame sliced narrowly per §4 |
| L4 | hints (maintainer, confirmed "Correct") | `class Test3(Test1, Test2)` … "the marks of `test_d` should be `[Mark(name="mark1"), Mark(name="mark4")]`" | **Order**: marks of `Test1` (first base) precede marks of `Test2` (second base) ⇒ **forward MRO order** (`Test3, Test1, Test2`). | encoded (GUM order); drove the V1→V2 change |
| L5 | prompt (reproducer / workaround) | metaclass property returns `own + chain.from_iterable(... for x in self.__mro__)` | The intended merge iterates `self.__mro__` **forward** (own/most-derived first, then bases left-to-right). | corroborates L4 (forward) |
| L6 | hints (Ronny) | "storing as normal attributes … has issues when combining same name marks from diamond structures, so it doesn't buy anything that isn't already solved" | Same-name marks from **diamonds** must not be duplicated by the merge; relying on plain attribute inheritance is rejected. | encoded structurally (read each class's own `__dict__`; see L9) |
| L7 | prompt (bluetech REPL) | `C.pytestmark` `Out: [Mark(name='a'), Mark(name='c')]` `(b is missing)` | **SUSPECT pre-fix display.** Reports the *bug* (`b` missing). Its incidental ordering (inherited `a` first, own `c` last) is **not** a spec for the post-fix order — do not enshrine it. | SUSPECT (§1 rule); rejected as order evidence |
| L8 | public test `test_mark.py::assert_markers` | `markers = {m.name for m in items[name].iter_markers()}; assert markers == set(expected)` | The project asserts merged class marks as **sets** of names ⇒ within-MRO **order is not a tested contract**; **membership/completeness is**. | bounds risk; order = ambiguous-but-forward-preferred |
| L9 | code (`store_mark`) | `obj.pytestmark = [*get_unpacked_marks(obj, consider_mro=False), mark]` | Each decorated class stores **only its own** marks in its `__dict__` ⇒ walking the MRO and reading each class's own `__dict__` collects every mark exactly once (no diamond duplication) — discharges L6. | encoded (companion fix) |

No hidden tests, evaluator output, or gold patch used. Order obligation L4 is **intent-derived** (explicit maintainer confirmation), corroborated by L5, and only *contradicted* by the SUSPECT pre-fix display L7.

---

## 2. INTENT_SPEC (intent-only, written before trusting candidate behavior)

For `get_unpacked_marks(cls)` where `cls` is a class:

- **I-COMPLETE** *(L1, L2, L3)* — the returned marks include **every** mark applied to **any** class in `cls.__mro__` (the class itself and every base, transitively). No base's marks are lost. (THE bug.)
- **I-ORDER** *(L4, L5)* — marks appear in **MRO order**: `cls`'s own marks first, then the marks of its bases in MRO order. For `class C(A, B)`: `C`, then `A`, then `B`. (Equivalently: forward iteration of `cls.__mro__`.)
- **I-NODUP** *(L6, L9)* — a mark applied once to one class appears **once**, even in diamond inheritance (a shared base's mark is not multiplied by the number of inheritance paths).
- **I-COMPAT** *(L3)* — single-inheritance/no-inheritance behavior that already worked (marks transfer to subclasses; a class's own marks are present in stored order) keeps working.
- **I-NONCLASS** *(code/domain)* — for non-class objects (functions, modules) behavior is unchanged: read the object's own `pytestmark` (normalized to a list). Default-domain: functions/modules have no MRO.

Observed-behavior-to-check-later (NOT expected values): the V1 candidate returned marks in **reversed** MRO order (`reversed(obj.__mro__)`); the legacy/pre-fix code returned only the first MRO entry's marks (L7, the bug).

---

## 3. FORMAL_SPEC_ENGLISH (paraphrase of each K claim)

- **(CONCAT)** — "Run the loop `while i < len(mark_lists): mark_list += mark_lists[i]; i += 1` starting from any `i = I` with `0 ≤ I ≤ len(mark_lists)` and any accumulator `mark_list = ACC`. It terminates with `mark_list = ACC ++ (mark_lists[I] ++ mark_lists[I+1] ++ … ++ mark_lists[n-1])` and `i = len(mark_lists)`." I.e. it concatenates **every** remaining per-class list, in order, skipping none.
- **(GUM)** — "`get_unpacked_marks(mark_lists)` returns `mark_lists[0] ++ mark_lists[1] ++ … ++ mark_lists[n-1]`," where `mark_lists` is the per-class mark lists in **forward MRO order**. Corollary (**completeness**): for every `k`, `mark_lists[k]` is a contiguous sublist of the result, so no class's marks are dropped. Corollary (**order**): index 0 (most-derived class) contributes first.
- **concatFrom(LL, I)** — the recursive closed form: empty when `I ≥ size(LL)`, else `LL[I] ++ concatFrom(LL, I+1)`.

---

## 4. SPEC_AUDIT (formal-English vs INTENT_SPEC)

| Intent | Formal claim | Verdict | Note |
|--------|--------------|---------|------|
| I-COMPLETE | (GUM) completeness corollary; (CONCAT) full `0..n` traversal | **pass** | Every `mark_lists[k]` is a sublist of the result. Directly negates the bug. |
| I-ORDER | (GUM) result `= mark_lists[0]++…++[n-1]`, input in forward MRO order | **pass** | Matches L4 `[mark1, mark4]` and L5. V1's reversed order would give `mark_lists[n-1]++…++[0]` ⇒ **fail** against L4 — this is why V2 changes `reversed(obj.__mro__)` → `obj.__mro__`. |
| I-NODUP | structural (store_mark `consider_mro=False`, read per-class `__dict__`) — L9 | **pass** | Not an arithmetic VC; established by the data-flow argument in PROOF.md §4. The bundled tier does not *machine-check* the multiset/diamond argument ⇒ also listed as an escalation note. |
| I-COMPAT | (GUM) at `n=1` (single class) reduces to that class's own stored marks, in stored order | **pass** | Single class: MRO is `[cls, object]`, `mark_lists = [own, []]`, result = `own`. Unchanged from legacy. |
| I-NONCLASS | not modeled (non-`type` branch unchanged) | **pass (by inspection)** | The `else` branch is byte-for-byte the original `getattr`-based logic. |
| within-MRO order *as a hard contract* | — | **ambiguous (L8)** | Public tests are set-based; order is not machine-asserted. V2 picks the intent-preferred order (L4/L5) but this is recorded as Finding F1, not a proven hard contract. |

No `fail` rows. The one `ambiguous` row (order as a *hard* contract) is handled by choosing the intent-preferred direction and recording F1; it does not bless `V2 == V1` (indeed it drove a change away from V1).

---

## 5. PUBLIC_COMPATIBILITY_AUDIT

| Changed symbol | Kind of change | Public? | Callsites / overrides | Status |
|---|---|---|---|---|
| `get_unpacked_marks` | added keyword-only `consider_mro=True`; return type `Iterable[Mark]`→`List[Mark]`; class branch walks MRO | **private** (`_pytest.mark.structures`) | `_pytest/python.py:314`, `:1717` (`.extend(...)`), `_pytest/mark/structures.py:416` (`store_mark`, `[*...]`) | OK — new param defaulted (old positional calls unaffected); `List` ⊑ `Iterable` (callers only iterate/`extend`/unpack); not re-exported in `pytest.__init__` or `_pytest.mark.__init__`. |
| `store_mark` | now calls `get_unpacked_marks(obj, consider_mro=False)` | **private** | only `MarkDecorator.__call__` / `_pytest.mark.structures` | OK — observable contract (a class's `__dict__["pytestmark"]` now holds only its own marks) is reconstructed at read time by (GUM); net result for every reader is unchanged-or-fixed. |

No public API signature, return-shape, or virtual-dispatch change. No subclass overrides `get_unpacked_marks`/`store_mark`. Producer/consumer protocol (`own_markers` lists, `keywords` dict, `iter_markers`) unchanged in shape; only the *contents* gain the previously-dropped base-class marks.

---

## 6. Residual ambiguity (carried to FINDINGS / ITERATION_GUIDANCE)

- **F1 (order as hard contract).** Public tests assert mark **sets** (L8), so merged-mark order is not machine-pinned. V2 uses forward MRO (L4/L5 intent). The only countervailing evidence (L7) is a SUSPECT pre-fix display. UltimatePowers question: *"Should the order of merged class marks be a guaranteed contract, and if so is it MRO order (most-derived first)?"*
- **F3 (same-name winner).** With forward MRO, for same-name marks on base vs derived, `get_closest_marker` returns the **derived** one (most-specific = "closest"); the `keywords` dict's last-wins picks the base. Neither is asserted by any public test. Consistent with the "closest" API name for `get_closest_marker`.
