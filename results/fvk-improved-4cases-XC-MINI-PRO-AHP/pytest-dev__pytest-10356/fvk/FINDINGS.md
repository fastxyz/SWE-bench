# FINDINGS.md — get_unpacked_marks / MRO mark collection

Plain-language findings, each `input → observed vs expected`. The headline finding (F0)
is the original bug and is **fixed** by V2; F1 is the **change V2 makes on top of V1**;
the rest are corner cases and recommendations.

---

## F0 — (FIXED) marks of all-but-one base class are lost under multiple inheritance

- **Input:** `@pytest.mark.foo class Foo`, `@pytest.mark.bar class Bar`,
  `class TestDings(Foo, Bar)` → `get_unpacked_marks(TestDings)`.
- **Legacy observed:** `[foo]` only (`getattr(TestDings, "pytestmark")` resolves via MRO
  to the **first** class that defines `pytestmark`, i.e. `Foo`; `Bar`'s `[bar]` is never
  seen). bluetech REPL confirms: `C(A,B)` → `[a, c]`, "b is missing".
- **Expected (L1, L2):** `[foo, bar]` — every MRO class's marks present.
- **Status:** **fixed** in V1 and V2 by walking `obj.__mro__` and reading each class's own
  `__dict__["pytestmark"]`. Proven as the completeness corollary of (GUM).

## F1 — (CHANGED V1→V2) merged-mark order must be forward MRO, not reversed

- **Input:** `class Test3(Test1, Test2)` with `@pytest.mark.mark1 class Test1`,
  `@pytest.mark.mark4 class Test2`; inspect `test_d`'s marks.
- **V1 observed:** V1 used `reversed(obj.__mro__)` → `[mark4, mark1]`.
- **Expected (L4, maintainer-confirmed "Correct"; L5 workaround; issue's own `[foo,
  bar]`):** `[mark1, mark4]` — first base before second base = **forward MRO order**.
- **Why V1 was wrong here:** its reversed order was justified only by preserving the
  *legacy* own-last ordering, whose sole evidence (bluetech REPL `[a, c]`, L7) is a
  **SUSPECT pre-fix display reporting the bug** — not a spec for post-fix order. Per the
  intent-evidence rules, that display cannot veto the explicit `[mark1, mark4]` intent.
- **Resolution (V2):** `reversed(obj.__mro__)` → `obj.__mro__`. Two-column derivation in
  PROOF.md §3 / PROOF_OBLIGATIONS PO-O1. Passes all visible (set-based) tests and now
  matches the maintainer's stated order.

## F2 — non-list `pytestmark` is wrapped, not dropped (corner case, preserved)

- **Input:** `class C: pytestmark = pytest.mark.foo` (a single `MarkDecorator`, **not** a
  list), possibly mixed with list-valued `pytestmark` on a base.
- **Observed/Expected (both V2 and legacy):** the `isinstance(item, list)` guard wraps a
  non-list entry into a one-element contribution (`append`), so it is normalized, not
  lost. `normalize_mark_list` then unwraps `MarkDecorator → Mark`.
- **Status:** OK — verified by inspection; cross-checked by
  `test_collection.py::test_unpacked_marks_added_to_keywords` (`pytestmark =
  pytest.mark.bar`). Not modeled in K (PO-D2).

## F3 — same-name marks across MRO levels: `get_closest_marker` now returns the derived one

- **Input:** `@pytest.mark.xfail(reason="b") class Base`, `@pytest.mark.xfail(reason="c")
  class Child(Base)` → `Child` item's `get_closest_marker("xfail")`.
- **V2 observed:** forward MRO ⇒ `own_markers = [xfail_c, xfail_b]` ⇒ closest = `xfail_c`
  (the **derived**/most-specific). Legacy/V1-reversed returned `xfail_b` (base).
- **Expected:** under-specified by the issue; but `get_closest_marker` is named
  *closest*, and the derived class is closer/more specific ⇒ V2's behavior is the more
  intuitive reading. **No visible test pins this** (`test_mark_closest` only tests
  function-vs-class node closeness, not base-vs-derived MRO).
- **Status:** accepted consequence of F1's forward order; flagged for awareness, not a
  bug. UltimatePowers question in ITERATION_GUIDANCE.

## F4 — diamond duplication is avoided structurally; manual concatenation can still duplicate

- **Input A (diamond):** `@pytest.mark.a class A`, `class B(A)`, `class C(A)`,
  `class D(B, C)` → `get_unpacked_marks(D)` = `[a]` (once). **OK** — `a` lives only in
  `A.__dict__`; `A` appears once in the MRO (PO-D1).
- **Input B (manual concat):** `class Base: pytestmark=[mark.a]`;
  `class Child(Base): pytestmark = Base.pytestmark + [mark.b]` →
  `get_unpacked_marks(Child)` = `[a, a, b]` (**duplicate `a`**: `a` is in both
  `Base.__dict__` and `Child.__dict__`).
- **Expected:** ambiguous. The fix deliberately does **not** value-de-duplicate (that
  could drop intentionally-repeated marks, e.g. stacked `parametrize`/`usefixtures`),
  matching Ronny's L6 ("doesn't buy anything that isn't already solved"). The manual-concat
  pattern is user-redundant now that the MRO walk merges automatically.
- **Status:** accepted edge case (rare, user-introduced). Recommendation: documentation
  note that manually concatenating a base's `pytestmark` is no longer necessary.

## F5 — exotic descriptor/property `pytestmark` on a class is read via `__dict__`

- **Input:** a class whose `pytestmark` is a `property`/descriptor (e.g. the issue's
  metaclass workaround).
- **Observed:** the class branch reads `cls.__dict__.get("pytestmark", [])`, which returns
  the raw descriptor object, **not** its computed value (unlike `getattr`).
- **Expected:** irrelevant going forward — the metaclass property was a *workaround for
  the very bug now fixed*; with V2 it is unnecessary. Normal `pytestmark` (plain list set
  by `store_mark` or a class attribute) is a real list in `__dict__` and reads correctly.
- **Status:** non-issue in practice; noted for completeness. (If ever needed, the
  non-`type` branch still uses `getattr`.)

---

## Proof-derived findings from `/verify`

- **PD1 (escalation, not a code bug).** The universal completeness predicate "∀k,
  `mark_lists[k]` ⊆ result" (PO-G3) needs list induction beyond the bundled arithmetic
  tier ⇒ `[ESCALATION BOUNDARY]`. The closed form `ML[0]++…++ML[n-1]` is a concrete
  witness, so the property is structurally manifest; this is a **proof-capability** gap,
  not a correctness gap. Keep the set-based merge tests until `kprove` closes it.
- **PD2 (side condition = real precondition).** (CONCAT) required `0 ≤ I ≤ size(ML)`.
  The `≤ size` upper bound is the formal echo of "walk the **whole** MRO": dropping it is
  exactly the legacy bug (stop after one entry). Healthy signal that the spec captures
  the intent.
- **PD3 (no public-API break).** Compatibility audit clean (SPEC §5): `get_unpacked_marks`
  / `store_mark` are private; signature change is back-compatible; return `List ⊑
  Iterable`.

## Tests (see ITERATION_GUIDANCE for the redundancy table)

- **Keep:** all of `test_mark_decorator_subclass_does_not_propagate_to_base`,
  `_baseclasses_merged`, `test_mark_should_not_pass_to_siebling_class`,
  `test_mark_closest`, `test_unpacked_marks_added_to_keywords` — they pin completeness,
  non-propagation-to-base/siblings, node-chain closeness, and module/class/method levels
  that the unit proof does not fully cover.
- **Add (recommended):** a multiple-inheritance *order* assertion mirroring L4
  (`[mark1, mark4]`) to lock F1; a diamond no-duplication assertion (F4-A).
