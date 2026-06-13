# FINDINGS — pytest-dev__pytest-10356

Plain-language findings from formalizing the V1 fix. Each is `input → observed vs
expected`. These do **not** depend on machine-checking (they are valid today). The
final section holds proof-derived findings from `/verify`.

Legend: **[FIXED]** the V1 change resolves it · **[CONFIRM]** the audit validates a V1
design choice · **[INTENT]** an intent-dependent behavior change to escalate ·
**[PRE-EXISTING]** present in baseline, not introduced by V1.

---

## F1 — [FIXED] Multiple-inheritance marks were dropped  *(the reported bug)*

- **input:** `@foo class Foo`, `@bar class Bar`, `class TestDings(Foo, Bar)`.
- **observed (baseline):** `get_unpacked_marks(TestDings) = [foo]` — `bar` is silently
  lost, because `getattr(TestDings, "pytestmark")` returns only the first `pytestmark`
  found along attribute lookup (`Foo`'s).
- **expected (issue + maintainer ruling):** both `foo` and `bar`.
- **V1:** walks the whole MRO → `flatten([…, [bar], [foo], …]) = [bar, foo]`. ✔
- Trace to: PO1. The fix is the `reversed(obj.__mro__)` comprehension.

## F2 — [CONFIRM] Mark order is *forced*, not free

- **question raised by the spec:** in what order should multi-base marks appear?
- **finding:** the order is **not a free choice**. To keep the long-standing
  single-inheritance order (`B(A)` ⇒ `[a, b]`, base-before-derived — see the baseline
  trace in PROOF_OBLIGATIONS PO3), the walk **must** be `reversed(__mro__)`. A forward
  walk would yield `[b, a]` and break existing single-inheritance tests.
- **consequence for `C(A, B)`:** the result is `[b, a, c]` (base-first, with siblings in
  reverse-declaration order, because that is how the MRO + reversal lays them out). Any
  hidden test asserting an *exact* multi-inheritance order should expect this base-first
  layout, the only one compatible with single inheritance.
- **V1:** uses `reversed(obj.__mro__)`. ✔ Confirmed correct.
- Trace to: PO3 **[forcing]**.

## F3 — [CONFIRM] The fix is two coupled changes, not one

- **finding:** changing only `get_unpacked_marks` (to walk the MRO) while leaving
  `store_mark` on the default `consider_mro=True` would **re-introduce duplication**.
  Example: `@a class A`, then `@b class B(A)` → `store_mark` would write
  `B.__dict__["pytestmark"] = [a, b]` (inherited `a` copied in), and the MRO walk would
  then yield `own(A) ++ own(B) = [a] ++ [a, b] = [a, a, b]` — duplicate `a`.
- **V1:** `store_mark` passes `consider_mro=False`, so it writes own-marks only
  (`B.__dict__["pytestmark"] = [b]`), and collection yields `[a, b]`. ✔
- Trace to: PO4 **[forcing]**, PO2.

## F4 — [CONFIRM / PRE-EXISTING] Marks are not deduplicated by name

- **input:** `@x class Foo`, `@x class Bar`, `class C(Foo, Bar)`.
- **observed (V1):** `[x_from_Bar, x_from_Foo]` — the same-named mark appears twice.
- **is this wrong?** No. Baseline single inheritance already did this (`@x A`, `@x B(A)`
  → `[x, x]`), and pytest deliberately does **not** collapse marks by name (repeated
  marks are meaningful: multiple `parametrize`, multiple `skipif` with different
  conditions). The issue *floated* "deduplicating marker names by MRO" as one option,
  but the implemented contract does **structural** dedup only (each class visited once),
  not name-dedup. This matches baseline semantics.
- **V1:** keeps all marks; no name-dedup. ✔ Consistent.
- Trace to: PO2 (structural-only dedup).

## F5 — [INTENT] Subclass body `pytestmark = [...]` now *merges* instead of *overrides*

- **input:**
  ```python
  class Base:  pytestmark = [pytest.mark.a]
  class Test(Base):  pytestmark = [pytest.mark.b]   # set in the body, not via decorator
  ```
- **observed (baseline):** `[b]` — the subclass attribute **shadowed** the parent, so
  `a` was dropped.
- **observed (V1):** `flatten([own(object), own(Base), own(Test)]) = [a, b]` — they
  **merge**.
- **is this wrong?** It is an intentional consequence of the maintainer ruling that
  "marks transfer with the MRO." A user who set `pytestmark = []` in a subclass to
  *clear* inherited marks would no longer succeed (the inherited marks now persist).
- **UltimatePowers question:** "When a subclass assigns `pytestmark` in its body, should
  that *replace* inherited marks or *merge* with them?" The implemented answer is
  *merge* (consistent with the issue); flag it so the next intent pass can confirm and
  document.
- **decision:** keep V1 (merge). It is what the issue asks for. Documented, not silently
  accepted.
- Trace to: PO1, PO3 (merge is inherent to the MRO-concat contract).

## F6 — [INTENT] A metaclass `pytestmark` *property* is bypassed by the `__dict__` read

- **input:** the issue's own workaround — a metaclass exposing `pytestmark` as a
  computed `property` (storing the real data under `_pytestmark`).
- **observed (baseline):** `getattr(cls, "pytestmark")` *invokes the property*, so the
  workaround "worked" (that is the issue's whole point).
- **observed (V1):** the class branch reads `cls.__dict__.get("pytestmark")`, which does
  **not** trigger a metaclass property (the property lives on `type(cls)`, not in
  `cls.__dict__`). If such a metaclass stores marks under a *different* attribute, V1
  would not see them.
- **is this wrong?** It is an accepted limitation. (a) The metaclass is a *workaround for
  the very bug being fixed* — once V1 walks the real MRO, plain classes need no
  metaclass. (b) Reading `__dict__` is exactly what makes diamond dedup correct (PO2);
  switching back to `getattr` per MRO entry would re-introduce duplication. So the
  trade-off is deliberate.
- **UltimatePowers question:** "Should pytest support a *computed* `pytestmark`
  (descriptor/property) on classes, or only a stored list/decorator?" Implemented
  answer: stored own-marks via `__dict__`.
- **decision:** keep V1 (`__dict__` read). Supporting the property would break PO2.
- Trace to: PO2 (read `__dict__`), SPEC §2 MRO-DISTINCT.

## F7 — [PRE-EXISTING] A non-list, non-mark `pytestmark` (e.g. a tuple) raises `TypeError`

- **input:** `class T: pytestmark = (pytest.mark.a,)` (a tuple, not a list).
- **observed (both baseline and V1):** the tuple is treated as a *single* value, wrapped
  `[tuple]`, then `normalize_mark_list` does `getattr(tuple, "mark", tuple)` → the tuple
  → not a `Mark` → `TypeError`.
- **finding:** the implicit contract is "`pytestmark` is a `list` of marks/decorators, or
  a single mark/decorator." A tuple is unsupported. **Unchanged by V1** — not a
  regression. Worth documenting in the marker docs.
- Trace to: PO6.

## F8 — [PRE-EXISTING] Instances (not classes) would not get MRO merging

- **input:** hypothetically calling `get_unpacked_marks(instance_of_C)`.
- **observed (V1):** `isinstance(instance, type)` is `False` ⇒ `else` branch ⇒
  `getattr(instance, "pytestmark")` ⇒ first-found along the instance's class MRO (old
  behavior, single class).
- **finding:** pytest **never** passes an instance to `get_unpacked_marks` (call sites
  are modules, classes, and functions only). So this path is unreachable in practice;
  noted for completeness, not a bug.
- Trace to: SPEC §1 call-site analysis; PO5.

## F9 — [PRE-EXISTING/minor] `TypeError` is now raised eagerly

- **finding:** baseline returned the lazy generator from `normalize_mark_list`, so a
  malformed mark raised `TypeError` only when iterated; V1 wraps in `list(...)`, raising
  eagerly. All three call sites consume the result immediately, so the observable
  behavior is unchanged; if anything, fail-fast is a slight improvement.
- Trace to: PO6, PO8.

---

## Spec-difficulty signal

A clean specification **was** writable (SPEC §3: four crisp contracts; SPEC §5: a single
loop circularity with **no** side condition, **no** nonlinear/division VC — only
associativity-with-unit of list concatenation). Per the kit's heuristic, *easy clean
spec ⇒ low bug-likelihood in the core algorithm*. The only friction was intent-level
(F5, F6) and ordering (F2/PO3) — all resolved by the issue's stated intent, none a code
defect. This is concordant with "V1 stands."

---

## Proof-derived findings from `/verify`

| # | Evidence | Classification | Next-iteration action |
|---|----------|----------------|-----------------------|
| PD1 | PO4 forcing argument: `store_mark` with `consider_mro=True` yields `[a,a,b]` | needed code guard (already present in V1) | Keep `consider_mro=False`; add a regression test asserting no duplicate after `@b class B(A)` collection. |
| PD2 | PO3 forcing argument: forward MRO gives `[b,a]`, breaking single-inheritance order | underspecified intent → resolved | Document that multi-base order is base-first (`reversed(__mro__)`); keep a single-inheritance order test. |
| PD3 | F5: subclass-body `pytestmark` now merges | underspecified intent | Ask the user to confirm merge-vs-override; add a documented test for the chosen semantics. |
| PD4 | F6: metaclass `pytestmark` property bypassed | underspecified intent / accepted limitation | Decide officially whether computed `pytestmark` is supported; document "stored marks only." |
| PD5 | (GUC) needs only list assoc-with-unit, no `/Int` lemma | proof-capability: comfortably in tier | None — clean. Confirms the algorithm is simple/correct. |

**No proof obstacle indicated a code bug.** All obstacles were either *forcing
arguments that V1 already satisfies* (PD1, PD2) or *intent questions* (PD3, PD4). The
recommendation is therefore to **confirm V1 unchanged** — see
[`ITERATION_GUIDANCE.md`](ITERATION_GUIDANCE.md).
