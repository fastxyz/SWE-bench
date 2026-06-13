# FVK failure analysis — `pytest-dev__pytest-10356`

**Batch:** `batch4-XC-MINI-PRO-AHP-260613182909` · **Arm:** fvk (forked resume of baseline) · **Result:** FAIL (FAIL_TO_PASS 0/1; baseline & control fail identically) · **Repo:** pytest.

**VERDICT: STATED** (root cause fully present; FVK localized it perfectly, named the correct fix, and explicitly argued against it). **Counts toward headroom: YES.** Public-data reachable: YES.

---

## 1. Root cause

**Location:** `src/_pytest/mark/structures.py`, function `get_unpacked_marks` (and a coupled one-liner in `store_mark`). Consumer call sites in `src/_pytest/python.py` (`own_markers.extend(get_unpacked_marks(...))`).

**The issue (#7792 / PR #10356):** "Consider MRO when obtaining marks for classes." At the base commit, `get_unpacked_marks` read marks with a plain `getattr(obj, "pytestmark", [])`, which follows normal attribute lookup and returns only the **first** `pytestmark` along the MRO. A class inheriting from two marked sibling base classes (`class C(A, B)` with `@a A`, `@b B`) silently **dropped** one base's marks. The fix must collect the own-marks of *every* class in the MRO.

**Why this instance still failed — the precise root cause of the remaining F2P failure.** The fvk arm did **not** start from the buggy base commit; it started from **V1 = base + baseline patch**, and V1 had *already* implemented the MRO fix almost exactly like the oracle: the `consider_mro` keyword, `isinstance(obj, type)` branching, per-class `__dict__.get("pytestmark", [])`, `List[Mark]` return, and `store_mark(..., consider_mro=False)`. V1's **only** deviation from the oracle is one token — it iterates `reversed(obj.__mro__)` instead of forward `obj.__mro__`:

| | MRO branch in `get_unpacked_marks` | order for `C(A, B)` |
|---|---|---|
| **Oracle (gold)** | `[x.__dict__.get("pytestmark", []) for x in obj.__mro__]` | `[c, a, b]` (derived-first) |
| **V1 = baseline = fvk** | `[x.__dict__.get("pytestmark", []) for x in reversed(obj.__mro__)]` | `[b, a, c]` (base-first) |

So the true root cause of the failure is a **traversal-direction (ordering) defect**: `reversed()`. The headline "marks dropped" bug was already fixed by V1; the residual defect is purely that marks come back in the wrong order.

**Bug type:** wrong output / off-by-direction (MRO traversal order). Adjacent to the multiple-inheritance attribute-shadowing class, but the surviving defect is specifically an ordering error.

**The failing test** (`testing/test_mark.py::test_mark_mro`, the sole FAIL_TO_PASS) asserts the exact forward-MRO order:
```python
all_marks = get_unpacked_marks(C)            # C(A, B), @a A, @b B, @c C
assert all_marks == [xfail("c").mark, xfail("a").mark, xfail("b").mark]   # [c, a, b]
```
fvk run output (authoritative `fvk.report.json`: `resolved=false`, only this test in `FAIL_TO_PASS.failure`, 79/79 PASS_TO_PASS pass):
```
E  At index 0 diff: Mark(name='xfail', args=('b',)...) != Mark(name='xfail', args=('c',)...)
```
i.e. V1 returned `[b, ...]` (base-first), test wanted `[c, ...]` (derived-first). -> `1 failed, 88 passed, 1 xfailed`.

**Public-data reachability: YES.** The issue text states the symptom, trigger, and mechanism, including the expected set `{foo, bar, ...}`. The exact ordering required by the hidden test is *not* spelled out in the issue, but it is the natural/standard MRO order (a forward `__mro__` walk) and the in-repo single-inheritance tests constrain it; deciding direction here was a reasoning question fully within reach. (Source-at-base-commit note: the pytest tree at the base commit is not checked out locally; this is grounded in the oracle `patch.diff`, the goldcheck `eval.sh` test patch + `test_output.txt`, the per-arm fvk `test_output.txt`, and the issue `problem_statement` — all consistent.)

---

## 2. What the fvk arm did (V1 vs final + key artifact contents)

**V1 vs final: NO CHANGE.** `diff solution_baseline.patch solution_fvk.patch` is empty; baseline, fvk, and control patches are byte-identical. The fvk phase made **zero source edits** — it produced only the formal artifacts and concluded "V1 stands, unchanged" (`fvk/ITERATION_GUIDANCE.md:5`).

**Artifacts produced** (all present): `fvk/SPEC.md`, `FINDINGS.md`, `PROOF_OBLIGATIONS.md`, `PROOF.md`, `ITERATION_GUIDANCE.md`; `reports/fvk_notes.md`. No standalone `.k` files — the mini-Python K fragments are embedded in `SPEC.md` sections 4-5. The audit formalized `get_unpacked_marks`/`store_mark`, stated four function contracts, enumerated **8 proof obligations** (all "discharged, constructed"), and emitted 9 findings.

**The audit centered on exactly the right thing — the ordering question.** It posed it explicitly and then answered it **wrong**:

- **F1 [FIXED]** correctly diagnoses the headline bug: `getattr` "returns only the first `pytestmark` found along attribute lookup," `bar` silently lost; V1 walks the whole MRO. (Correct.)
- **F2 [CONFIRM] "Mark order is *forced*, not free"** — raises "in what order should multi-base marks appear?", concludes "the walk **must** be `reversed(__mro__)`. A forward walk would yield `[b, a]` and break existing single-inheritance tests," and — critically — predicts: *"Any hidden test asserting an exact multi-inheritance order should expect this base-first layout `[b, a, c]`."* This is the precise **inversion** of the actual test (`[c, a, b]`).
- **PO3 [forcing]** constructs a "forcing argument" that `reversed(__mro__)` is "the **unique** compatibility-preserving choice." `PROOF.md` restates `[b, a, c]` as "the unique base-first order." `fvk_notes.md` Decision 1 and `ITERATION_GUIDANCE.md` Verdict both lock it in: "keep."

The agent's argument is **logically flawed**: the oracle uses forward `obj.__mro__` and *all* single-inheritance PASS_TO_PASS tests still pass (e.g. `test_mark_decorator_baseclasses_merged`). The agent conflated *MRO traversal order* with *output-list order* — it assumed a forward walk reverses the legacy `[a, b]` single-inheritance result, which it does not under the oracle's flattening. The formal apparatus (a "forcing" PO) then dressed this incorrect assumption as a proved necessity.

**Transcript:** the agent Grepped `pytestmark`/`get_unpacked_marks`, Read `structures.py` repeatedly, and Read the `get_unpacked_marks` call sites in `python.py` and `nodes.py`. It looked at the correct code. It never saw `test_mark_mro` (the hidden test was unavailable) and reasoned purely from the issue plus its own backward-compatibility assumption.

---

## 3. Artifact audit — VERDICT

**VERDICT: STATED.** Primer tell #8 ("STATED-but-reasoned-against: the artifact names the correct fix, then argues against it"). This is the strongest possible "present" case and arguably stronger than the canonical example: the artifacts not only localize the defect to the exact function, construct, and decision axis, they make an **explicit, falsifiable, and wrong prediction** about the hidden test.

The root-cause region is not merely present — it is the single most-analyzed subject in the artifact set. The decision that *is* the bug (`reversed` vs forward MRO) is named verbatim, the correct alternative (forward walk) is named verbatim, and it is rejected with a constructed proof obligation.

**Exact load-bearing excerpt** — `fvk/FINDINGS.md` F2 (the spot a knowledgeable reader, pointed here, agrees encodes the fault):
> "the order is **not a free choice**. To keep the long-standing single-inheritance order (`B(A)` => `[a, b]`, base-before-derived ...), the walk **must** be `reversed(__mro__)`. A forward walk would yield `[b, a]` and break existing single-inheritance tests.
> **consequence for `C(A, B)`:** the result is `[b, a, c]` (base-first ...). Any hidden test asserting an *exact* multi-inheritance order should expect this base-first layout, the only one compatible with single inheritance."

Corroborating: `fvk/PROOF_OBLIGATIONS.md` PO3 "Forcing argument" ("A *forward* MRO walk gives `[b, a]` ... Therefore ... **forces** `reversed(__mro__)`"); `fvk/PROOF.md:108-109` ("the **unique** base-first order"); `reports/fvk_notes.md` Decision 1; `fvk/ITERATION_GUIDANCE.md:5-12`.

**Pointed-at-the-spot test applied to the *cause* (not a symptom string):** the cause is the traversal direction. F2/PO3 are *about* the traversal direction, name both options, and choose the wrong one. This is not a symptom-string match wrapped around an unrelated mechanism (the tell #4 decoy) — it is the exact mechanism, exactly localized. Confidence is high.

**Why STATED, not BURIED:** the signal is not hidden in formal scaffolding awaiting surfacing — it was surfaced, framed as a top-level finding (F2) and a flagged `[forcing]` obligation (PO3), and a wrong conclusion was acted on. The information was right there in plain language; the failure is the audit reasoning to the wrong answer and confirming the bug. (It is the inverse of tell #9 false-positive certification in spirit — here the *correct* fix is named and dismissed, rather than the buggy output silently enshrined — but the controlling tell is #8.)

---

## 4. How FVK could surface it (prose, general, no-exec)

- **Treat a "forced ordering/value" obligation as a hypothesis to falsify, not a result to confirm.** When a PO claims a concrete choice (here `reversed`) is *uniquely* forced by backward compatibility, FVK should be required to (a) write down the *forward* alternative's predicted output explicitly and (b) re-derive the legacy single-inheritance trace under **both** candidates side by side. Doing so here would have exposed that forward `__mro__` also reproduces `[a, b]` for `B(A)` (because flattening own-marks per class is order-preserving), collapsing the "forcing argument."
- **Separate traversal order from output order in the spec.** The error was a conflation that a more careful symbolic trace (`reversed([B, A, object]) = [object, A, B]` vs forward `[B, A, object]`, then mapping to `own(...)` concatenation) would have surfaced as two distinct orderings rather than one "forced" answer.
- **Flag any artifact that *predicts* a hidden test's exact value as high-risk.** F2 literally states what "any hidden test asserting an exact multi-inheritance order should expect." A surfacing layer that escalated such concrete, checkable predictions (rather than burying them in a CONFIRM finding) would route exactly the cases where the audit has bet the whole verdict on an unverified ordering assumption.
- **When a single design token (`reversed`) is the entire delta from the intended contract and the spec hard-codes it, the ordering axis is under-constrained by the issue and should be marked spec-difficulty / open-intent, not [CONFIRM].** The issue specified the *set* of marks, never the order; promoting an unstated axis to a "forced" CONFIRM is exactly where the false confidence entered.
