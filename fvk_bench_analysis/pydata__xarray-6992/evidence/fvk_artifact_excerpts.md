# Key FVK-artifact excerpts — pydata__xarray-6992
Source dir: results/batch5-XC-MINI-PRO-AHP-260614105258/pydata__xarray-6992/

## A. The captured HALF of the root cause (component (a): the additive coord_names bug)
FINDINGS.md F1 (lines 11–31) — names the buggy line and the negative-len mechanism:
> ## F1 — ROOT CAUSE: `reset_index` could produce `coord_names ⊄ variables` (the reported bug)
> **Where:** `Dataset.reset_index`, the pre-V1 final line
> `coord_names = set(new_variables) | self._coord_names`.
> ... `coord_names = {z,a,b} ⊄ {a,b} = keys(variables)`; `z` is a coordinate name
> with no variable. `DataVariables.__len__ = 2 − 3 = −1` → `ValueError ...`.
> **This is the unique invariant-breaking line.** Fixed by subtracting `D`.

## B. The MISSING half (component (b): loop drop/convert/rename semantics — what the 12 tests assert)
PROOF_OBLIGATIONS.md PO9 (lines 68–74) — fences out exactly the tested behavior:
> ### PO9 — Full semantic correctness of which names are kept/dropped/recreated
> A complete contract for the *values* of `D, N` (e.g. "`drop=True` on a 3-level
> multi-index dim+level should/shouldn't keep a reduced index") depends on multi-
> index design intent that the issue does not pin down. **Status: OUT-OF-SCOPE** for
> #6992. ... The invariant (PO1) and P2 (PO2) hold for *whatever* `D, N` the existing
> logic emits, so the fix is safe regardless of how PO9 is eventually resolved.

PO8 (lines 58–66) — the loop (the actual fix site) abstracted into opaque D,N:
> ### PO8 — Adequacy of the loop abstraction
> The `for name in dims_or_levels` loop is modelled by its outputs `(D, N)` rather
> than stepped. **Status: ASSUMED (trusted base).** ... So abstracting the loop loses
> nothing for the invariant.

## C. The inversions (primer tells #7 and #9) — artifact certifies buggy behavior as correct
FINDINGS.md F4 (lines 72–78) — precondition declared "clean", NOT a bug signal (tell #7 inversion):
> ## F4 — Precondition surfaced: `reset_index` assumes a well-formed input (`C ⊆ V`)
> Writing P1 required the precondition `self._coord_names ⊆ set(self._variables)` ...
> This is **clean** (it is the class invariant), so it is *not* a spec-difficulty bug
> signal — it is the inductive hypothesis.

SPEC.md P4 (lines 90–93) — proves the drop=False path UNCHANGED (= preserves the bug; tell #9).
6 of 12 failing tests are drop=False:
> - **P4 (frame condition for `drop=False`):** when `drop=False`, `D = ∅`, so
>   `coord_names = C ∪ N` ... i.e. **`drop=False` behaviour is byte-for-byte
>   unchanged** from the pre-fix code. All `reset_index` semantics asserted by
>   existing tests for `drop=False` are preserved.

FINDINGS.md F7 (lines 104–112) — certifies the (too-weak) fix as right and minimal:
> That a clean, induction-free spec/proof exists is positive evidence the fix is
> right and minimal.

## D. F3 — DESCRIBES the multi-key mechanism (touches keep_levels/create_variables) but
##    points at the WRONG defect axis (coord_names set-membership, not to_base_variable),
##    and explicitly says it is "**not** the reported bug":
FINDINGS.md F3 (lines 43–70):
> ## F3 — CORNER CASE `N ∩ D ≠ ∅`: V1's formula keeps INV but demotes a recreated coordinate
> **Where:** `reset_index` when `dims_or_levels` contains **both** a multi-index
> *dimension* name and a *level* name ... (so ≥2 levels are kept and `keep_levels`
> returns a *multi*-index, whose `create_variables` re-emits the dimension coordinate).
> ... **Severity / scope:** pre-existing, never covered by a test ... **not** the
> reported bug and **not** a V1 regression ...

## E. The .k mechanism is PURE SET-KEY ALGEBRA — the loop (fix site) is OUTSIDE the model
reset_index.k (lines 5–18) — the model abstracts the loop away by construction:
> // The Python code being modelled (after the ``for name in dims_or_levels`` loop
> // has produced the name-sets V, C, D, N) is straight-line:
> //     variables   = {k: v for k, v in self._variables.items() if k not in D}
> //     variables.update(new_variables)            # keys(variables) = (V - D) | N
> //     coord_names = (self._coord_names - D) | N  # the fixed line
> //     return coord_names <= keys(variables)      # the invariant we prove
> // We abstract each mapping by its *key set* ...
There is NO in-place-mutation rule, NO index-rebuild rule, NO variable-conversion
rule. `to_base_variable` / `IndexVariable→Variable` is unrepresentable here.

## F. Documented ABSENCE (grep across fvk/ + reports/fvk_notes.md):
- `to_base_variable` / `base_variable`        → 0 matches  (the single most-asserted tested behavior)
- `drop_or_convert`                            → 0 matches
- `indexes.py` / `index.rename(self.dim)`      → 0 matches  (the keep_levels fix file)
- `keep_levels`                                → 3 matches, ALL only as the SOURCE of symbol N
                                                  (SPEC.md:84, FINDINGS.md:47, fvk_notes.md:52);
                                                  NEVER as a fix target / never the rename bug.
