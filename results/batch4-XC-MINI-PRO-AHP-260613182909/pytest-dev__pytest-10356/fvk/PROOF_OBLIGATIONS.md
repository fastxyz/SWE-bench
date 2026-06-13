# PROOF OBLIGATIONS — pytest-dev__pytest-10356

Each obligation is what the V1 fix must satisfy for the contracts in
[`SPEC.md`](SPEC.md) to hold. Status is **constructed, not machine-checked**; the
discharge argument is in [`PROOF.md`](PROOF.md). Obligations marked **[forcing]**
are the ones whose discharge *pins a specific V1 design choice* — i.e. the audit shows
the choice is not arbitrary but required.

| ID | Obligation | Discharged? | Pins which V1 choice |
|----|------------|-------------|----------------------|
| PO1 | Multiple-inheritance completeness | yes | walk full `__mro__` |
| PO2 | No structural duplication (diamonds) | yes | read `__dict__` per class |
| PO3 | Order = baseline for single inheritance | yes **[forcing]** | `reversed(__mro__)` |
| PO4 | `store_mark` stores own-marks only | yes **[forcing]** | `consider_mro=False` |
| PO5 | Non-class path behavior preserved | yes | the `else` branch |
| PO6 | Type safety / `Mark`-only result | yes | keep `normalize_mark_list` |
| PO7 | Termination | yes | finite MRO + finite lists |
| PO8 | mypy / call-site compatibility (`List` return) | yes | `list(...)` wrap |

---

## PO1 — Multiple-inheritance completeness  *(the bug being fixed)*

**Statement.** For a class `obj` and `consider_mro=True`, for **every** class
`c ∈ mro(obj)` and every mark `m ∈ own(c)`, `m ∈ get_unpacked_marks(obj)`.

**Why it can fail (the baseline bug).** Baseline used `getattr(obj, "pytestmark")`,
which returns the **first** `pytestmark` found along attribute lookup. For
`C(Foo, Bar)`, that is `Foo.pytestmark`; `Bar`'s marks are dropped.

**Discharge.** V1 builds `mark_lists = [own(c) for c in reversed(obj.__mro__)]` and
`flatten`s it. The comprehension ranges over the *entire* MRO, so every class's
`own(c)` is included. ∎ (Proof: PROOF.md §3, completeness corollary of (GUC).)

**Concrete witness.** `class TestDings(Foo, Bar)`, `@foo` on `Foo`, `@bar` on `Bar`:
baseline → `[foo]`; V1 → `flatten([[], [], [bar], [foo], []]) = [bar, foo]`. Both
present. ✔

---

## PO2 — No structural duplication in diamonds

**Statement.** For each `c`, the marks of `own(c)` appear in the result with exactly
their multiplicity in `c.__dict__["pytestmark"]`, **not** multiplied by the number of
subclasses that inherit `c`.

**Discharge.** Two facts combine:
1. **MRO-DISTINCT** (Python language guarantee): `mro(obj)` lists each ancestor class
   exactly once. So the comprehension visits each `c` once.
2. V1 reads `c.__dict__.get("pytestmark", [])` — the class's **own** dict — never
   inherited attributes. Combined with **PO4** (store_mark writes own-marks only),
   `c.__dict__["pytestmark"]` contains only `c`'s own marks.

Hence each `own(c)` is concatenated exactly once. For the diamond
`Base ◅ Foo, Bar ◅ TestDings`, `Base` appears once in the MRO ⇒ `own(Base)` appears
once. ∎

**Counter-design that fails PO2.** Reading `getattr(c, "pytestmark")` per MRO entry
(instead of `c.__dict__`) would re-resolve inheritance for each `c` and concatenate
ancestor marks repeatedly ⇒ duplication. V1 avoids this by reading `__dict__`.

---

## PO3 — Order equals baseline for single (and zero) inheritance  **[forcing]**

**Statement.** For `B(A)` (and for a class with no inheritance), the result order
equals the baseline order: base-class marks before derived, declaration order within a
class.

**Baseline order (established by trace).** `@a` on `A`, `@b` on `B(A)`:
- baseline `store_mark(A,a)` → `A.pytestmark=[a]`;
- baseline `store_mark(B,b)` → `[*getattr(B,"pytestmark"), b] = [a, b]`;
- baseline collection `getattr(B,"pytestmark") = [a, b]`. **Order `[a, b]`.**

**Discharge.** V1 `reversed(mro(B)) = reversed([B, A, object]) = [object, A, B]` ⇒
`own(A) ++ own(B) = [a] ++ [b] = [a, b]`. **Identical.** ∎

**Forcing argument.** A *forward* MRO walk gives `own(B) ++ own(A) = [b, a]`, reversing
the long-standing order and breaking existing single-inheritance tests. Therefore the
backward-compatibility obligation **forces** `reversed(__mro__)`. (Equivalent
formulation: prepend `own(c)` while iterating forward MRO — same `[b,a,c]` result for
`C(A,B)`.) The audit thus *confirms* V1's `reversed` is the unique
compatibility-preserving choice, not an arbitrary one.

---

## PO4 — `store_mark` stores own-marks only  **[forcing]**

**Statement.** After `store_mark(obj, m)`:
`own(obj)_after = own(obj)_before ++ [m]`, and `own(c)` is unchanged for all `c ≠ obj`;
in particular no inherited mark is copied into `obj.__dict__["pytestmark"]`.

**Discharge.** `store_mark` computes `get_unpacked_marks(obj, consider_mro=False)`,
which by **C-CLASS-OWN** equals `own(obj)_before`, then assigns
`obj.pytestmark = own(obj)_before ++ [m]`. The assignment writes `obj.__dict__` only. ∎

**Forcing argument (why `consider_mro=False` is mandatory).** Suppose `store_mark`
used the default `consider_mro=True`. For `B(A)` with `@a` on `A`, applying `@b` to `B`:
`get_unpacked_marks(B, mro)= [a]` (A's own), so `B.__dict__["pytestmark"] = [a, b]` —
**polluted with the inherited `a`**. Then C-CLASS-MRO collection computes
`reversed(mro(B)) = [object, A, B]` ⇒ `own(A) ++ own(B) = [a] ++ [a, b] = [a, a, b]` —
a **duplicate `a`**. So PO2 would fail. Therefore the two halves of the fix are
coupled: walking the MRO at *read* time (PO1) is sound **only if** writes are own-only
(PO4). The audit confirms V1 made exactly the matching pair of changes.

---

## PO5 — Non-class path behavior preserved

**Statement.** For `¬isinstance(obj, type)` the result equals the baseline
implementation for all inputs.

**Discharge.** Baseline:
`m = getattr(obj,"pytestmark",[]); m = m if isinstance(m,list) else [m]; normalize(m)`.
V1 `else`-branch:
`m = getattr(obj,"pytestmark",[]); m = m if isinstance(m,list) else [m]; list(normalize(m))`.
Logically identical (the `isinstance` test is merely inverted). The only delta is the
`list(...)` wrapper (see PO8). ∎ Modules and functions are unaffected; this is verified
by inspection, not by the loop proof.

---

## PO6 — Type safety: result is `Mark`-only

**Statement.** Every element of the returned list is a `Mark`; any element that is
neither a `Mark` nor a `MarkDecorator` raises `TypeError`.

**Discharge.** The result is `list(normalize_mark_list(mark_list))` in **all** branches.
`normalize_mark_list` maps `e ↦ getattr(e, "mark", e)` and asserts `isinstance(_, Mark)`,
raising `TypeError` otherwise. Unchanged from baseline. ∎ (Note: V1 raises this
**eagerly** because of `list(...)`; baseline raised it lazily on iteration — see
FINDINGS F9. No caller depends on laziness.)

---

## PO7 — Termination

**Statement.** `get_unpacked_marks` always terminates.

**Discharge.** `obj.__mro__` is a finite tuple; `reversed(...)` of a finite tuple is
finite; the comprehension and the `for item in mark_lists` loop iterate finite lists;
each `own(c)` is finite; `normalize_mark_list` iterates a finite list. No recursion, no
unbounded loop. Total (not merely partial) termination holds. ∎

---

## PO8 — Call-site / type compatibility of the `List[Mark]` return

**Statement.** Changing the return from a lazy `Iterable[Mark]` (baseline) to a
materialized `List[Mark]` (V1) breaks no caller and no type check.

**Discharge.** Three call sites:
- `store_mark`: `[*get_unpacked_marks(obj, consider_mro=False), m]` — unpacking a list
  works.
- `python.py:314`, `python.py:1717`: `self.own_markers.extend(get_unpacked_marks(...))`
  — `extend` accepts a list.
All consume the result eagerly exactly once, so list-vs-generator is immaterial at
runtime. The annotation `List[Mark]` is a subtype of the previous `Iterable[Mark]`, so
no downstream type narrows incorrectly. ∎

---

## Trusted base (assumptions the proof rests on, stated honestly)

- **MRO-DISTINCT**: `type.__mro__` lists each ancestor exactly once (Python language
  guarantee / C3 linearization). Used by PO2. This is a cited language fact, **not** a
  faked `[trusted]` admission of an unprovable code VC.
- **Adequacy of the mini-Python fragment** (§4 of SPEC) vs. real CPython for the
  constructs used (`list`, `isinstance`, `append`, `extend`, `for`, `if`, `def`/call).
- The reachability proof-system metatheory and `kprove` (not run here).
- `normalize_mark_list`, `Mark`, `MarkDecorator` semantics unchanged from baseline.
