# Analysis — `pydata__xarray-6992` (FVK arm, FAIL_TO_PASS 0/12)

Batch: `batch5-XC-MINI-PRO-AHP-260614105258`. Repo: `pydata/xarray`, base commit
`45c0a114e2b7b27b83c9618bc05b36afac82183c`. F2P=12, P2P=945.
Result parity (`scores.json`/`eval/fvk.report.json`): baseline `0/12`, **fvk `0/12`**, control `1/12`
— zero flips, fvk patch applied cleanly (a behavioral miss, not an apply failure).

---

## 1. Root cause

The user-visible symptom is `ValueError: __len__() should return >= 0` from
`DataVariables.__len__` (`xarray/core/dataset.py:367`, unedited):
`return len(self._dataset._variables) - len(self._dataset._coord_names)`. The problem
statement names the broken invariant directly: *"since the index refactor we can end up
with **more `_coord_names` than `_variables`**"* and gives the MVCE
`ds.set_index(z=['a','b']).reset_index("z", drop=True)`.

The oracle patch (`evidence/oracle_patch.diff`) edits **three functions across two files** —
`Dataset.reset_index` and `Dataset.set_index` in `xarray/core/dataset.py`, and
`PandasMultiIndex.keep_levels` in `xarray/core/indexes.py`. The true root cause has **two
coupled components**, both inside `reset_index`:

- **(a) Additive `coord_names` that never shrinks.** The pre-fix tail
  `coord_names = set(new_variables) | self._coord_names` only ever *grows* `coord_names`.
  When variables are dropped, their names are not removed from `coord_names`, so
  `len(_coord_names) > len(_variables)` → negative `__len__`. (This alone produces the
  reported crash on the MVCE, where `new_variables = {}`.)
- **(b) Missing-case in the `for name in dims_or_levels` loop.** The pre-fix multi-index
  branch is guarded by `if isinstance(index, PandasMultiIndex) and name not in self.dims:`.
  When you reset a whole **multi-index dimension** (the MVCE: `name="z"` *is* a dim), the
  branch is skipped entirely, so the level coordinate variables (`a`, `b`) are **neither
  dropped nor converted**. The oracle restructures this into `drop_or_convert(...)` (which,
  on `drop=False`, calls `self._variables[k].to_base_variable()` to convert each
  `IndexVariable` to a base `Variable`) and adds `drop_variables.add(index.dim)` on the
  whole-dimension branch. The supporting `keep_levels` change renames a collapsed single
  level to the dimension (`index.rename(self.dim)`).

The tail fix the oracle ships is the *simpler* `coord_names = self._coord_names - drop_variables`,
made correct only because the rewritten loop now puts the right names into `drop_variables`.

**Bug type:** missing-case / wrong-branch-guard **plus** broken invariant maintenance
(non-subtractive `coord_names` bookkeeping) during index rebuild; secondary
wrong-value-preserved (`IndexVariable` not converted to base `Variable`; level coord not
renamed to dim).

**Public-data reachability: YES, strongly.** The issue text names the exact invariant
(`_coord_names > _variables`), the exact exception, the exact crash line (L368), and a
deterministic MVCE. Stepping the MVCE through the public `reset_index` source exposes both
the skipped branch and the additive `coord_names`. (The `drop=False` `to_base_variable`
conversion and the `keep_levels` rename — tied to companion issues #6946/#6989 — are the
harder-to-infer refinements, but the 8 parametrized tests assert them and the core defect is
fully derivable.)

**The 12 F2P tests — common theme.** All exercise `reset_index` (directly or via groupby
internals): `test_reset_index` (×2, DataArray+Dataset), `test_reset_index_drop_dims`,
8× `test_reset_index_drop_convert[...]`, and `test_groupby_drops_nans` (which calls
`.stack(...).…reset_index("id", drop=True)` — the exact whole-multi-index-dim drop path).
The 8 parametrized cases pin component (b): for `drop=True` the named coords must be **truly
removed**; for `drop=False` they must be **converted** via
`assert_identical(reset[name].variable, ds[name].variable.to_base_variable())`; a collapsed
single level must be **renamed** to the dimension. (Failing assertion verbatim in
`evidence/failing_test_drop_convert.txt`: *"Left and right IndexVariable objects are not
identical"*.)

---

## 2. What the fvk arm did (V1 vs final + key artifact contents)

**V1 vs final = a provable no-op.** Both `solution_baseline.patch` (V1) and
`solution_fvk.patch` (final) edit **only one line** of `reset_index` (~L4180), touching no
other line and no other file. The only change fvk made is to **reorder the operands** of the
tail and lengthen the comment (`evidence/v1_vs_fvk_patch_diff.txt`):

- V1: `coord_names = (set(new_variables) | self._coord_names) - set(drop_variables)`  `≡ (N∪C)−D`
- final: `coord_names = (self._coord_names - set(drop_variables)) | set(new_variables)`  `≡ (C−D)∪N`

FVK's own `FINDINGS.md` **F8** states the two forms are *"provably equal whenever `N ∩ D = ∅`
(which holds for every realistic/tested input, incl. the MVCE where `N=∅`)"*. So the
refinement changes nothing on the entire test suite — 0/12 was guaranteed before the edit.

**Key artifact contents:**
- **SPEC.md** — intent-spec mode. Target = `Dataset.reset_index`; class invariant
  **INV: `coord_names ⊆ keys(variables)`**; set model `V,C,D,N`; postconditions P1–P4. The
  `for name in dims_or_levels` loop is "summarised by its outputs `(D, N)`" (§6 trusted base).
  **P4 proves the `drop=False` path "byte-for-byte unchanged"** (SPEC.md:90–93).
- **FINDINGS.md** — F1 = root-cause line (component (a), captured exactly). F3 = the multi-key
  `N∩D≠∅` corner (touches `keep_levels`/`create_variables`) but classed "**not** the reported
  bug". F4 = precondition `C⊆V` declared "**clean** … *not* a spec-difficulty bug signal".
  F6 = audit of all `coord_names` builders. F7 = "the fix is right and minimal." No
  ✅/✏️/⚠️ markers.
- **PROOF_OBLIGATIONS.md** — PO1 (INV) DISCHARGED; PO2 DISCHARGED-V2-only (the corner that
  "motivates" the reorder); **PO9 "Full semantic correctness of which names are
  kept/dropped/recreated" = OUT-OF-SCOPE**; PO8 (loop) = ASSUMED.
- **PROOF.md** — constructed (NOT machine-checked) finite-set-algebra proof of `(C−D)∪N ⊆
  (V−D)∪N`; emits but never runs `kompile`/`kprove`.
- **`reset_index.k` / `reset_index-spec.k`** — the **mechanism** is **pure Boolean-set-key
  algebra** over opaque `D`/`N`. The model comment (`reset_index.k:5–18`) states it models
  only the *post-loop* straight-line code and abstracts each mapping by its key set. There is
  **no in-place-mutation rule, no index-rebuild rule, no variable-conversion rule** — the
  `claim … [all-path]` (`reset_index-spec.k:59–74`) proves only `cn <= vk` under `subset(C,V)`.
  `to_base_variable` / `IndexVariable→Variable` is structurally unrepresentable in this model.
- **ITERATION_GUIDANCE.md** — G3 defers the multi-key `drop=True` semantics as
  "underspecified intent (out of scope for #6992)"; notes "no `[ESCALATION BOUNDARY]` needed."
- **fvk_notes.md** — decision log for the single V1→V2 line reorder.

**Localization vs. fix.** FVK localized to the **correct file and method region**
(`reset_index` in `dataset.py`) and captured component (a) of the cause precisely. But it
**abstracted away the loop that is the actual fix site**, declared that loop's semantics
out of scope, and shipped a tail-line cosmetic change.

---

## 3. Artifact audit — VERDICT

**VERDICT: MISSING (inverted) — reachable. Does NOT count toward headroom.**

This is the rare "split cause" case: **one half is STATED, the other half is MISSING and
inverted**, and the half the 12 tests measure is the missing one. Net verdict for *the cause
the tests pin* is **MISSING**.

Applying the "pointed-at-the-spot" test to the **cause the failing tests measure** —
component (b), the loop's drop/convert/rename semantics:

- **The single most-asserted tested behavior, `to_base_variable` (the `drop=False`
  `IndexVariable→Variable` conversion), is absent from every artifact** (grep over `fvk/` +
  `fvk_notes.md`: 0 matches for `to_base_variable`, `drop_or_convert`; the failing assertion
  is literally `…ds[name].variable.to_base_variable()`). The `keep_levels` *rename* fix and
  the file `indexes.py` are also absent (`keep_levels` appears 3× but only as the *source of
  symbol `N`*, never as a fix target). See `evidence/fvk_artifact_excerpts.md` §F.

- **The `.k` mechanism cannot carry it.** `reset_index.k:5–18` abstracts the entire
  `for name in dims_or_levels` loop into opaque key-sets `D`/`N`; the proof is set inclusion
  only. The mechanism the tests exercise (rebuild indexes via `keep_levels`/`create_variables`,
  convert via `to_base_variable`, drop the dim variable on the whole-multi-index branch) is
  outside the model by construction — `evidence/fvk_artifact_excerpts.md` §E.

- **Worse than silent omission — the artifacts point the *wrong* way (inverted, primer tells
  #7 + #9).** `SPEC.md` P4 (lines 90–93) *proves* the `drop=False` path is **"byte-for-byte
  unchanged"** and asserts "All `reset_index` semantics asserted by existing tests for
  `drop=False` are preserved" — but the oracle's whole `drop=False` fix *is* changing that
  path (`to_base_variable`), and **6 of the 12 failing tests are `drop=False`**. FVK
  certified the buggy behavior as the spec (tell #9). `FINDINGS.md` F4 declares the surfaced
  precondition "**clean … *not* a spec-difficulty bug signal**" — inverting the kit's
  "hard-to-spec ⇒ bug" heuristic into false reassurance (tell #7). F7 then certifies the fix
  "right and minimal."

- **The near-miss does not rescue it.** `FINDINGS.md` F3 (lines 43–70) *describes* the
  multi-key path and even traces `keep_levels`/`create_variables` re-emitting the dimension
  coordinate — but it points at the **wrong defect axis** (whether the recreated name lands in
  `coord_names`, a set-membership concern) and explicitly rules itself out: *"**not** the
  reported bug and **not** a V1 regression."* The drop/convert/rename behavior the tests
  assert is never identified as defective. Per the primer's pointed-at-the-spot rubric
  (applied to the *cause*, not a symptom string), a correctly-shaped observation aimed at the
  wrong defect axis is **not** PRESENT.

So component (a) is STATED (`FINDINGS.md` F1 names the buggy line and the fix direction "Fixed
by subtracting `D`") and FVK acted on it — but acting on (a) is provably insufficient (F8).
Component (b) — the cause of all 12 failures — is **MISSING and inverted**.

**Single most important excerpt (the inversion that decides the verdict):**
`results/batch5-XC-MINI-PRO-AHP-260614105258/pydata__xarray-6992/fvk/SPEC.md:90–93` (P4:
`drop=False` "byte-for-byte unchanged" / "existing tests … preserved") — directly contradicted
by `evidence/failing_test_drop_convert.txt` ("Left and right IndexVariable objects are not
identical"). Corroborated by `fvk/PROOF_OBLIGATIONS.md:68–74` (PO9 OUT-OF-SCOPE).

**Headroom accounting:** MISSING-but-reachable ⇒ **does not count toward headroom**, but is a
genuine FVK gap (the information was derivable; FVK scoped it out and then certified the gap
shut). The fix region was reachable from public data (§1).

---

## 4. How FVK could surface it (prose, general, no-exec)

- **Forbid abstracting the very statement under repair.** The methodology summarized the
  `for name in dims_or_levels` loop "by its outputs `(D, N)`" — but that loop *is* the fix
  site, and the values it computes (which names enter `D`/`N`, and whether kept coords are
  *converted*) are precisely what the tests measure. A guard: when the spec abstracts a region
  into opaque symbols, it must justify that the *defect cannot live in the abstracted region*.
  Here the issue's MVCE flows straight through that loop, which should block the abstraction.

- **Treat "the precondition/postcondition is clean" as a prompt to widen scope, not to stop.**
  F4 found a clean precondition and P4 a clean frame condition, and read both as *reassurance*.
  The kit's own heuristic is the opposite ("if a clean spec is easy, check you specified the
  right property"). A "clean, minimal, total" result that leaves the reported behavior
  unchanged on a path the issue exercises (`drop=False`) is a red flag, not a green one.

- **Make the intent ledger model the *value/type* axis, not just the membership axis.** FVK's
  INV (`coord_names ⊆ variables`) is a *set-membership* invariant; the tests assert a *value*
  property (the variable is a base `Variable`, equal to `to_base_variable()`). Mining the
  issue plus companion references (#6946/#6989) into obligations over variable *identity/type*
  — not just name sets — would have created an obligation that the existing code provably fails,
  surfacing component (b).

- **Cross-check "this corner is not the reported bug" against the test surface, not the issue
  text alone.** F3 reached the right code path and dismissed it as untested. A no-exec but
  evidence-grounded step — reading the repo's `reset_index` tests and the companion issues —
  would show that path *is* (about to be) tested, converting the dismissal into a finding.
