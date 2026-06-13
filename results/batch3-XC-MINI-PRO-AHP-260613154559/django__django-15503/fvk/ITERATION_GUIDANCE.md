# FVK ITERATION GUIDANCE — JSONField `has_key` numeric-key fix

Feedback package for the next generate→formalize→verify pass. Each item ties to a
Finding (`fvk/FINDINGS.md`) and an obligation (`fvk/PROOF_OBLIGATIONS.md`).

---

## 1. Code changes already applied this pass (V1 → V2)

| Change | Driven by | Obligation closed |
|---|---|---|
| `compile_json_path_final_key` now does `json.dumps(str(key_transform))` (was `json.dumps(key_transform)`) | **F-int** / **P1** | **O1-pre** (precondition `K:str` now holds for all scalars) |

Rationale: the final key of `has_key`/`has_keys`/`has_any_keys` is *always* a JSON
object key (a string). Coercing with `str()` makes a numeric key passed as an
`int`/`float` (`has_key=1111`) render as `$."1111"`, identical to the string form,
and matches the pre-existing `str()` coercion in `HasKeys.get_prep_lookup`. The
change is a no-op for string keys (`str(s) is`-equivalent → identical SQL), so it
cannot regress the reported issue's test or any existing test.

Everything else in V1 stands — confirmed correct by C2–C5 and Findings
F-nonempty / F-preserve / F-navfinal.

## 2. UltimatePowers questions (intent the spec could not settle)

1. **Non-string scalar keys.** Should `has_key=1111` (int), `has_key=4.2` (float),
   `has_key=True` be accepted as object keys `"1111"`/`"4.2"`/`"True"` (V2's
   choice, consistent with `has_keys`), **rejected** with a validation error, or
   left undefined? V2 picks "coerce to string"; confirm that is the intended
   contract or tighten it. *(Finding F-int.)*
2. **`has_key=None`.** Meaningless today (pre-fix `TypeError`, V2 `$."None"`).
   Should it raise a clear error, or is `None` simply out of the domain? *(F-none.)*
3. **Literal `%` in a bare-string `has_key` on Oracle.** `has_key='a%b'` is
   pre-existingly broken (the path is `%`-formatted into SQL). Is fixing the
   bare-string `%`-escape in `HasKeyLookup.as_oracle` in scope for a follow-up?
   *(F-oracle-pct.)*

## 3. Recommended next code/spec changes (beyond this task's scope)

- **(optional, low priority)** Make `has_key`'s `None`/`%` behavior explicit per
  the answers to Q2/Q3 — either a `get_prep_lookup`-level validation or an Oracle
  `%`-escape for bare-string keys. Not done here: out of the issue's scope and
  untested; would widen the diff.
- **(spec)** If the project later adds full per-language K semantics, replace the
  `parsesAsInt`/`dumps` abstractions in `json_path.k` with the real `int()` /
  `json.dumps()` semantics so O1–O5 are checked against the literal library calls
  rather than their models.

## 4. Tests — add / keep / remove

**Add (would strengthen the contract, cheap):**
- `has_key` with a **numeric key on a JSON array column** asserting it does **not**
  match by index, e.g. `value=[10,20]`, `value__has_key="0"` → no match (object
  semantics, parity with PostgreSQL `?`). Pins C1/C5 against array columns.
- a non-string-numeric case `has_key=1111` (int) returning the same rows as
  `has_key='1111'` — directly pins **F-int / O1-pre** (the V2 change).

**Keep (do NOT drop — proof does not subsume them):**
- `test_has_key_deep`, `test_has_key_list` — navigation array indices (F-navfinal).
- `value__d__0__isnull=False` base querysets, `test_isnull_key` — F-preserve at DB
  level (Oracle/SQLite use `HasKeyOrArrayIndex`).
- `test_key_escape` and all cross-backend (SQLite/MySQL/Oracle/PostgreSQL) runs —
  backend acceptance of `$."1111"` is an assumption, not a discharged VC.

**Remove (only after `kprove` returns `#Top`, recommendation-only):**
- pure single-point string-builder unit checks subsumed by C1/C5 — see PROOF.md
  Benefit 1. Until machine-checked, **keep them**.

## 5. Residual risk carried forward

- **Constructed, not machine-checked** — run the `kompile`/`kprove` commands in
  `fvk/PROOF.md` to upgrade to machine-verified and to unlock the test removals.
- **mini-X adequacy** — `parsesAsInt`/`dumps` model the opaque library calls; the
  proof leans only on facts visible in the source (no array branch in
  `compile_json_path_final_key`; `dumps` of a string is quoted).
- **Backend SQL-path acceptance** of the quoted object member `$."1111"` —
  assumed, justified by the existing non-numeric `has_key` suite already using
  `$."key"` on all three affected backends.
