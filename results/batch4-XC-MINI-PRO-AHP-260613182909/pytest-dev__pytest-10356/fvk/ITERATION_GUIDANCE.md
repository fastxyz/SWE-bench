# ITERATION GUIDANCE — pytest-dev__pytest-10356

Feedback package from `/formalize` + `/verify` for the next code-generation pass.

## Verdict: **V1 stands, unchanged.**

The FVK audit discharged all eight proof obligations
([`PROOF_OBLIGATIONS.md`](PROOF_OBLIGATIONS.md)) and found **no code defect**
([`PROOF.md`](PROOF.md) §4, [`FINDINGS.md`](FINDINGS.md) proof-derived table). The two
design choices that could have been wrong are *forced* by the obligations, and V1 makes
both correctly:

1. **`reversed(obj.__mro__)`** is forced by PO3 (backward-compatible ordering). A
   forward walk breaks single-inheritance order. → keep.
2. **`store_mark(..., consider_mro=False)`** is forced by PO4 (own-marks-only write),
   without which the MRO walk would re-duplicate inherited marks (F3/PD1). → keep.

Because correctness rests on these two coupled choices and V1 already makes them, **no
edit to `repo/` is warranted.** A change here would risk regressing PO3 or PO4.

## Why not even a "minimal refactor"

Considered and rejected:
- *Switch `__dict__.get` → `getattr` per MRO entry* — would re-introduce diamond
  duplication (PO2). Rejected.
- *Add name-based dedup* — contradicts pytest semantics (F4: repeated marks are
  meaningful) and the baseline. Rejected.
- *Drop the `list(...)` wrapper to keep a lazy `Iterable`* — V1's eager `List` is
  cleaner, fail-fast (F9), and the annotation is more precise (PO8). Keep V1's `list`.
- *Special-case metaclass `pytestmark` properties (F6)* — would require `getattr`,
  breaking PO2. Rejected; documented as an accepted limitation instead.

So V1 is already the minimal, correct change; refactoring would only add risk.

## Open intent questions (for an UltimatePowers-style pass, not blockers)

These are *intent* clarifications, not defects. V1 chose the issue-consistent answer in
each case:
- **PD3 / F5:** subclass body `pytestmark = [...]` — *merge* (chosen) vs *override*?
  The issue's "marks transfer with the MRO" implies merge. Confirm + document.
- **PD4 / F6:** is a computed/`property` `pytestmark` on classes supported? Chosen
  answer: no — stored own-marks via `__dict__` only. Confirm + document.
- **PD2 / F2:** multi-base order is base-first `reversed(__mro__)` (e.g. `C(A,B)` →
  `[b, a, c]`). Confirm this is the documented contract.

## Tests to add / keep (recommendation-only; the project suite is fixed & hidden — do NOT modify it)

**Add (regression):**
- multiple inheritance: `class T(Foo, Bar)` collects **both** `foo` and `bar` (F1/PO1).
- diamond: shared base mark appears **once** (F4 caveat / PO2).
- coupling guard: after `@b class B(A)`, collecting `B` yields `[a, b]` with **no
  duplicate `a`** — pins PO4/F3 so a future refactor of `store_mark` cannot silently
  break it (PD1).
- order: single inheritance `B(A)` stays `[a, b]` (PD2/PO3).

**Keep (outside the verified contract):**
- module-level and function-level marker tests (C-NONCLASS path, PO5).
- the issue's metaclass-property scenario (F6 — out of verified domain).
- any test pinning subclass-body override semantics (F5 — behavior changed).
- collection-ordering / integration / termination tests.

**Conditionally redundant (only after `kprove` returns `#Top`; nothing removed now):**
- point-wise "marks include X" assertions inside the verified domain are subsumed by
  `(GUC)` (PROOF.md §6). Until machine-checked, keep them.

## Residual risk carried forward

- Proof is **constructed, not machine-checked** — run SPEC §7 `kompile`/`kprove`.
- Trusted base: MRO-DISTINCT (Python C3), mini-Python fragment adequacy,
  `normalize_mark_list`/`Mark` unchanged (PROOF.md §5).
