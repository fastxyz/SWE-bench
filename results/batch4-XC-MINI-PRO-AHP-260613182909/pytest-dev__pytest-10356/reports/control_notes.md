# Control notes — V2 review outcome for pytest-dev__pytest-10356

## Decision summary

After a systematic, skeptical re-review (see `review/FINDINGS.md`), **V1 stands
unchanged**. No source edits were made in this pass. Every candidate concern
either confirmed V1's correctness or resolved to an intended consequence of the
fix that the issue and maintainers explicitly endorse. This document justifies
that decision finding-by-finding.

## What V1 contains (unchanged)

- `src/_pytest/mark/structures.py`
  - `get_unpacked_marks(obj, *, consider_mro=True) -> List[Mark]`: for classes,
    walk `reversed(obj.__mro__)` and concatenate each class's *own*
    `pytestmark` read from `cls.__dict__`; for non-classes, unchanged `getattr`
    behavior.
  - `store_mark`: persist only own marks via `consider_mro=False`.
- `changelog/7792.bugfix.rst`.

## Why no code changes were required

### Core behavior is correct → keep
- The reported bug is fixed and verified by reasoning in **F1** (multiple
  inheritance), **F2** (`-m`/keyword selection end-to-end), and **F2b** (the
  issue's detailed `Test3(Test1, Test2)` example resolves to the
  maintainer-endorsed `{mark1, mark4}` on `test_d`). No change needed.

### The riskiest property — not regressing existing suites — holds → keep
- **F3** shows single-inheritance mark ordering is reproduced exactly, and this
  is *because* V1 walks `reversed(obj.__mro__)` (base-first). I considered
  switching to forward MRO order (most-derived-first, "true MRO precedence"),
  but rejected it: it would invert the long-standing base-first ordering that
  existing tests and `get_closest_marker` consumers rely on. Preserving F3 is
  the dominant constraint, so the `reversed(...)` choice stays.

### `__dict__` vs `getattr` per MRO entry → keep `__dict__`
- **F4** is the decisive reason. Reading each class's own `__dict__` makes a
  shared diamond base contribute its marks exactly once. Using `getattr(cls,
  "pytestmark")` per MRO entry would re-resolve inheritance and duplicate
  ancestor marks. The current code is the correct formulation; changing it
  would reintroduce duplication. No change.

### `store_mark` own-only storage → keep
- **F12** establishes that `consider_mro=False` in `store_mark` is *required*
  for soundness: if `store_mark` kept copying inherited marks into the subclass
  dict (old behavior) while reads also walk the MRO, every inherited mark would
  appear twice. The pair "own-only storage + MRO-walking reads" is internally
  consistent and must be kept together. No change.

### Edge cases already handled → keep
- **F5** (per-class single non-list `pytestmark`), **F6** (class-body attr +
  decorator), **F8** (empty/default), and **F9** (malformed value still raises
  the same `TypeError`) are all handled by the existing branch logic. I
  specifically retained the two-step `mark_lists` → `mark_list` flattening in
  the class branch because F5 needs per-class list/non-list handling; collapsing
  it would drop that case. No change.

### Return-type change is safe and better → keep
- **F11**: switching from a lazy generator to a concrete `List[Mark]` is safe
  for all three call sites and aligns the annotation with reality. Reverting to
  a generator would be churn with no benefit. No change.

## Behavior changes that are intended, not bugs (documented, not "fixed")

These were examined as potential regressions and deliberately left as-is because
they are the point of the fix:

- **F13** — A subclass can no longer clear/override inherited marks via
  `pytestmark = []` or by re-declaring the attribute; marks now merge along the
  MRO. This is the explicit intent ("marks have to transfer with the mro") and a
  breaking change appropriate for a feature release. Not reverted.
- **F14** — The issue's metaclass `pytestmark`-property workaround no longer
  contributes marks (V1 reads `__dict__`, bypassing the property). Acceptable
  because the workaround exists only to compensate for the very bug being fixed;
  real marks are found by the MRO walk. Not accommodated, by design.
- **F12** (user-facing part) — Direct access to `Subclass.pytestmark` now
  returns own-only marks. This attribute is an undocumented internal detail; all
  supported APIs see the full inherited set. Not changed.

I considered adding name-based mark deduplication to soften F13/F7, and rejected
it: marks legitimately repeat with different args (e.g. multiple
`parametrize`/`skipif`), the maintainers stated dedup "doesn't buy anything that
isn't already solved," and F4 already prevents the only *structural* duplication
(a diamond base visited twice). Adding dedup would risk dropping meaningful
marks. No change.

## Consistency / quality confirmations (no change needed)

- **F17** — V1's `isinstance(obj, type)` + per-class `__dict__` walk mirrors the
  existing `PyCollector.collect()` MRO idiom (`python.py:434-438`); the fix is
  idiomatic.
- **F18** — Imports (`List`, `Union`) are present, `Iterable` stays in use, and
  the body is mypy-clean.
- **F19** — `consider_mro=True` default correctly enables the fix at the sole
  class call site while `store_mark` opts out.
- **F15/F16/F20** — Modules, functions, the runtime `add_marker` path, and the
  legacy hook-mark reader are unaffected; the changelog follows convention.

## Conclusion

The review surfaced no defect requiring a code edit. V1 is correct, minimal,
idiomatic, and its secondary behavior changes are the intended semantics of
MRO-based marker inheritance. V1 is confirmed and left unchanged.
