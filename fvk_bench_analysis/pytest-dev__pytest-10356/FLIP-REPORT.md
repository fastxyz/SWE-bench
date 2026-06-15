# FVK FLIP report — `pytest-dev__pytest-10356`

**Run:** `fvk-improved-4cases-XC-MINI-PRO-AHP` (hardened materials) · **Arm:** fvk (forked resume of baseline) · **Result: FLIP** — baseline (V1) `resolved=False`, fvk `resolved=True`. The only flip of the 4 instances in this run. · **Repo:** pytest · **FAIL_TO_PASS:** `testing/test_mark.py::test_mark_mro` (sole F2P).

This is the *same* instance the OLD materials (batch4) **failed** — fvk then fabricated a "forcing" proof obligation and confirmed V1's bug (see `ANALYSIS.md`). The hardening that mattered: the verify.md rule **"a 'forced' choice is a hypothesis to falsify, not a premise."**

---

## 1. The bug

**Issue #7792 — "Consider MRO when obtaining marks for classes."** `get_unpacked_marks` read marks with `getattr(obj, "pytestmark", [])`, which follows normal attribute lookup and returns only the **first** `pytestmark` on the MRO; `class C(A, B)` with `@a A`, `@b B` silently **dropped** one base's marks.

**What V1/baseline got right.** Baseline produced a near-oracle fix: the `consider_mro` kwarg, `isinstance(obj, type)` branching, per-class `__dict__.get("pytestmark", [])`, `List[Mark]` return, and `store_mark(..., consider_mro=False)`. The headline "marks dropped" bug was fixed.

**The residual defect (traversal direction).** V1 walked the MRO **`reversed`**, giving *base-first* order. The hidden test asserts *derived-first*:

```python
# test_mark_mro: C(A, B), @xfail("a") A, @xfail("b") B, @xfail("c") C
assert get_unpacked_marks(C) == [xfail("c").mark, xfail("a").mark, xfail("b").mark]   # [c, a, b]
```
V1 returns `[b, a, c]` ⇒ `E  At index 0 diff: Mark(...args=('b',)...) != Mark(...args=('c',)...)`. Baseline: F2P 0/1, PASS_TO_PASS 79/79 (`eval/baseline.report.json`).

**The one-token diff (V1 vs oracle/fvk):**
```python
mark_lists = [x.__dict__.get("pytestmark", []) for x in reversed(obj.__mro__)]  # V1  -> [b, a, c]
mark_lists = [x.__dict__.get("pytestmark", []) for x in obj.__mro__]            # fvk -> [c, a, b]
```

## 2. What fvk did

The fvk patch changes exactly that token (plus docstring + a `7792.bugfix.rst` changelog), `solutions/solution_fvk.patch`:
```diff
-                x.__dict__.get("pytestmark", []) for x in reversed(obj.__mro__)
+                x.__dict__.get("pytestmark", []) for x in obj.__mro__
```
This makes `test_mark_mro` PASS while keeping all PASS_TO_PASS green: F2P 1/1, PASS_TO_PASS 79/79, `resolved=True` (`eval/fvk.report.json`). It matches the gold patch (`evidence/oracle_patch.diff`).

## 3. How fvk got there (the mechanism)

The baseline notes had treated V1's order as "preserve legacy order." Writing `INTENT_SPEC` forced fvk to pin the order, and it then treated "the order is forced by backward-compat" as a **hypothesis to falsify** rather than a premise — searching the suite for what actually constrains order, then deriving both candidates against it.

The decisive step (transcript `fvk.jsonl.gz`, row 178, first-hand):
> "I've now exhaustively searched the visible test suite… **1. All** class-mark-merge tests are **set-based** (`assert_markers` compares `{m.name for m in iter_markers()}`)… none pin merged-mark order… My V1 used `reversed(obj.__mro__)`, which produces `[mark4, mark1]` — **contradicting the maintainer's explicit `[mark1, mark4]`**. That reversed order was justified only by preserving legacy (bluetech-style own-last) ordering, which FVK forbids using as justification. The fix should use **forward MRO**."

Because the legacy single-inheritance tests are set-based, forward and reversed produce the **same set** ⇒ both satisfy them ⇒ the order is **not forced** by backward-compat. The only positive order evidence (maintainer-confirmed `[mark1, mark4]` = L4; issue's `[foo, bar]` + metaclass workaround = L5) all points **forward**; the lone reversed signal is the pre-fix `[a, c]` REPL display (L7), a **SUSPECT** display of the bug itself, which cannot define post-fix order. The two-column derivation is recorded in `fvk/SPEC.md` §1 (L4/L5/L7/L8 ledger), `fvk/FINDINGS.md` F1, `fvk/PROOF.md` §3 (Order corollary PO-O1: forward ⇒ `[mark1, mark4]`; reversed ⇒ `[mark4, mark1]` ≠ L4), and `fvk/PROOF_OBLIGATIONS.md` §C. `reports/fvk_notes.md:42` states the rule it followed: a "named change… **promoted to a tested hypothesis** and accepted on **positive intent grounds** (L4/L5), not waved through."

## 4. Why the materials made the difference

The shipped rule that drove the flip, `third_party/formal-verification-kit/commands/verify.md:58`:
> **"Forced" choices are hypotheses to falsify, not premises.** Treat any claim that a concrete choice — an ordering, a value, a branch — is *uniquely forced*, or that "the alternative would break X / backward-compatibility requires it," as a hypothesis to falsify. Procedure: name the concrete alternative; write its predicted output explicitly; re-derive the legacy / backward-compat trace under **both candidates side by side** (a two-column derivation). … If both candidates satisfy the public obligations the choice is **under-determined, not forced** — record it as open, never as CONFIRM.

**Contrast with the OLD run** (per `ANALYSIS.md`, VERDICT: STATED): without this rule, fvk made **zero edits** and instead built a `[forcing]` proof obligation (PO3) asserting `reversed(__mro__)` was "the **unique** compatibility-preserving choice," explicitly predicting "any hidden test… should expect this base-first layout `[b, a, c]`" — the exact inversion of the real test. It conflated *MRO traversal order* with *output-list order* and dressed the wrong assumption as a proved necessity.

**Lesson.** The same agent, same model, same near-correct V1: the OLD materials let a plausible backward-compat story be enshrined as a "forcing" PO and confirm the bug; the new rule made that story a hypothesis, the side-by-side derivation falsified it, and the one-token fix followed. Falsifying "forced" claims — not more formal machinery — converted a STATED-but-confirmed miss into a fix.
