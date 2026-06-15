# ITERATION_GUIDANCE.md

Feedback package from the FVK audit of `get_unpacked_marks` / `store_mark`.

---

## 1. What changed this iteration (V1 → V2)

**One-line code change**, driven entirely by Finding **F1** / obligation **PO-O1**:

```diff
-                x.__dict__.get("pytestmark", []) for x in reversed(obj.__mro__)
+                x.__dict__.get("pytestmark", []) for x in obj.__mro__
```

(plus a docstring update describing the forward MRO order). `store_mark`'s
`consider_mro=False`, the MRO walk itself, and the non-`type` branch are **unchanged**
from V1 — the audit confirmed them correct (F0 completeness, F4-A diamond, PD3
compatibility).

**Why:** V1's `reversed` produced `[mark4, mark1]` for the maintainer's confirmed example
`Test3(Test1, Test2)`, contradicting the explicit intent `[mark1, mark4]` (L4) and the
issue's own `[foo, bar]` / workaround order (L5). V1's reversed order was supported only
by the SUSPECT pre-fix display `[a, c]` (L7), which reports the bug and cannot define the
post-fix order. Forward MRO satisfies the intent order, passes every visible (set-based)
test, and gives `get_closest_marker` the intuitive "derived is closest" behavior (F3).

## 2. What stands from V1 (confirmed, not changed)

- **MRO walk + per-class `__dict__` read** — fixes F0 (the actual bug). Proven completeness.
- **`store_mark(..., consider_mro=False)`** — stores each mark only on its own class ⇒
  read-time MRO walk reconstructs the full set with **no diamond duplication** (F4-A, L6,
  PO-D1). Essential companion to the walk; removing it reintroduces duplicates.
- **Non-`type` branch** — byte-for-byte the original `getattr` logic; functions/modules
  unchanged (I-NONCLASS).
- **`List` return / `consider_mro` kwarg** — back-compatible, private API (PD3).

## 3. UltimatePowers questions for the next intent pass

1. **Order contract (F1):** Should the order of merged class marks be a *guaranteed*
   public contract? If yes, confirm it is MRO order (most-derived first, bases
   left-to-right). Current public tests assert only **sets** (L8), so today it is
   intent-preferred but not test-locked.
2. **Same-name winner (F3):** For a base and a derived class both carrying a same-named
   mark, should `get_closest_marker` return the **derived** (V2: yes, "closest") or the
   base? Should `keywords[name]` agree with it? (They currently differ: closest=derived,
   keywords-last-wins=base.)
3. **Manual concat duplication (F4-B):** Is `pytestmark = Base.pytestmark + [...]`
   (now-redundant) worth a deprecation note, or should value-equal marks be de-duplicated
   (risking loss of intentional repeats)? Recommendation: document, do **not** dedup.

## 4. Test-redundancy report (Benefit 1) — recommendation only, conditioned on `kprove`

| Visible test | Relation to proof | Recommendation |
|---|---|---|
| `test_mark_decorator_baseclasses_merged` (set `{a,b,c}`/`{a,b,d}`) | entailed by (GUM) completeness within the verified domain | **Redundant *iff* machine-checked** — keep until `kprove` returns `#Top`; even then consider keeping as a readable regression for F0. |
| `test_mark_decorator_subclass_does_not_propagate_to_base` | completeness + the non-propagation-to-base direction (store side, PO-D1) | **Keep** — exercises `store_mark`'s own-`__dict__` write, which the unit proof argues only by data flow. |
| `test_mark_should_not_pass_to_siebling_class` (#568) | sibling isolation via node tree, not `get_unpacked_marks` | **Keep** — outside the proof's unit. |
| `test_mark_closest` | node-chain closeness (function vs class) | **Keep** — orthogonal to MRO order; also guards F3's node-level half. |
| `test_unpacked_marks_added_to_keywords` | module/class/method levels + non-list `pytestmark` (F2) | **Keep** — covers the non-`type`/keywords wiring not modeled in K. |
| `test_addmarker_order` (`["baz","foo","bar"]`) | `add_marker` ordering on a single node | **Keep** — unrelated to MRO; not subsumed. |

Net: only the pure set-membership merge test is a redundancy *candidate*, and only after
machine-checking. **Never auto-delete.** No test was modified (forbidden, and not needed).

## 5. Recommended new tests (lock the audit's conclusions)

- **Order (F1):** `class Test3(Test1, Test2)` with `@mark.mark1`/`@mark.mark4` →
  `[m.name for m in test_d.iter_markers()] == ["mark1", "mark4"]` (forward MRO), to lock
  the V1→V2 change against regression.
- **Diamond no-dup (F4-A):** `@mark.a class A`, `class B(A)`, `class C(A)`,
  `class D(B, C)` → exactly one `a` in `D`'s marks.
- **Issue reproducer (F0):** the literal `TestDings(Foo, Bar)` from the issue → both
  `foo` and `bar` present.

## 6. Honesty gate

All K artifacts are **constructed, not machine-checked** (no `kprove` run). Test-removal
advice is conditioned on running `kompile`/`kast`/`kprove` (commands in PROOF.md §6) and
getting `#Top`. The Findings (F0–F5, PD1–PD3) stand independently of machine-checking.
The completeness predicate PO-G3 has an `[ESCALATION BOUNDARY]` (list induction); its
closed-form witness makes the property manifest but not formally machine-closed here.
