# FVK SPEC — JSONField `has_key` / `has_keys` / `has_any_keys` path building

Scope: the V1/V2 fix in `repo/django/db/models/fields/json.py`. We formalize the
**JSON-path string builders** that the fix touches and the property the fix must
establish. Default mode: **partial correctness** (the builders are pure, total,
terminating string functions, so partial = total here; noted in PROOF.md).

K artifacts: `fvk/json_path.k` (mini-Python fragment semantics) and
`fvk/json_path-spec.k` (the reachability claims). Everything is **constructed,
not machine-checked** (MVP — the toolchain is not run).

---

## 1. Intent (from `benchmark/PROBLEM.md` + hint)

`has_key='1111'` against a JSON **object** `{'1111': 'bar'}` must match on SQLite,
MySQL and Oracle exactly as it already does on PostgreSQL. The hint states the
root cause and the intended fix precisely:

> "has_key, has_keys and has_any_keys lookups use `compile_json_path()` … which
> uses array paths for integers. We shouldn't use array paths for these lookups."

So the **key being checked** is always a JSON *object key* (object keys are
strings) and must be compiled to object-member access `$."1111"`, **never** to
array-index access `$[1111]`. Navigation *into* nested arrays (e.g. `value__d__1`
where `d` is a list) is a different concern and must keep array indices.

## 2. Vocabulary (modelled in `json_path.k`)

- `parsesAsInt(K)` — models `try: int(K) except ValueError` (Python `str→int`).
- `dumps(K)` — models `json.dumps(K)` for a **string** `K`: always a quoted token.
- `seg(K)` — one segment as `compile_json_path` emits it:
  `"[K]"` if `parsesAsInt(K)`, else `"." + dumps(K)`.
- `segObject(K)` — the object-only segment `"." + dumps(K)` (no `parsesAsInt`
  branch). This is what `compile_json_path_final_key` emits.
- `cjp(KS)` = `compile_json_path(KS, include_root=False)` = `concat(seg(k) for k in KS)`.
- `isObjectToken(T)` — `T` is an object-member token (begins `."…`), not `[…]`.

## 3. Contracts

### C1 — `compile_json_path_final_key(K)` *(claim `FINALKEY`)*
- **Pre:** `K` is a string.
- **Post:** returns `segObject(K) = "." + dumps(K)`, which `isObjectToken` holds
  for **every** `K` — including numeric `K` where `parsesAsInt(K)` is true.
- **Significance:** this is the fix. The previous code path used `seg(K)`, which
  for numeric `K` returns the array token `"[K]"`. C1 says the checked key is
  *unconditionally* an object member.
- **Side condition / precondition gap:** the clean post needs `K:str`. For a
  non-string scalar (`int`/`float`) the bare `json.dumps` produced an *unquoted*
  token (`.1111`, `.4.2`), and for `None` the original `int(None)` even raised
  `TypeError`. See Findings **F-int** / **F-none**. **V2** discharges this by
  coercing `str(K)` inside `compile_json_path_final_key`, restoring the `K:str`
  precondition for all scalar inputs.

### C2 — fix vs. pre-fix, on numeric keys *(claim `SEG-VS-OBJECT`)*
- **Pre:** `parsesAsInt(K)`.
- **Post:** `seg(K) ≠ segObject(K)` — the old form is `"[K]"`, the new form is
  `"."+dumps(K)`. Formal statement that the divergence is exactly the numeric-key
  case (and only there), i.e. the fix changes nothing for non-numeric keys.

### C3 — `compile_json_path` homomorphism *(claim `HOMO`, the loop invariant)*
- **Post:** `cjp(A ++ B) = cjp(A) + cjp(B)` for all key lists `A`, `B`.
- This is the invariant of `compile_json_path`'s `for` loop (a left fold of `seg`
  with string concatenation); proved by induction on `A` (the circularity).

### C4 — `HasKeyOrArrayIndex` preserves original behaviour *(claim `PRESERVE`)*
- **Post:** `buildPathArr(LJP, NAV, FINAL) = LJP + cjp(NAV ++ [FINAL])`.
- Because `HasKeyOrArrayIndex.compile_json_path_final_key(K) = seg(K)` (= the
  `compile_json_path([K], include_root=False)` body) and by C3, splitting the
  navigation prefix from the final key and re-joining reproduces the *exact*
  string the **original** `HasKey.as_sql` produced for the whole key list.
- **Significance:** the three internal callers rewired to `HasKeyOrArrayIndex`
  (`KeyTransformIsNull.as_sqlite/as_oracle`, `KeyTransformExact.as_oracle`) emit
  byte-identical SQL to pre-fix — **zero regression** for `value__d__0__isnull`,
  `value__1__has_key`, `value__d__1__has_key`, etc.

### C5 — `HasKeyLookup.as_sql` rhs loop, has_key family *(claim `ASSQL-OBJECT`)*
- **Post:** each rhs path = `lhs_json_path + cjp(NAV) + segObject(FINAL)`, and the
  final segment `isObjectToken` for all `FINAL`. Navigation keeps `cjp` (array
  indices for numeric nav keys); only the final key is forced object-member.
- **Loop precondition (key invariant):** `rhs_key_transforms` is **non-empty** at
  the `*nav, final = rhs_key_transforms` unpack, otherwise it raises `ValueError`.
  Discharged structurally — see Finding **F-nonempty** (a *satisfied* precondition):
  the `else: rhs_key_transforms = [key]` branch yields length 1, and
  `KeyTransform.preprocess_lhs` returns a list seeded with `[self.key_name]`
  (length ≥ 1). So the unpack never fails.

## 4. What is deliberately NOT changed (and why the spec must say so)

- **Navigation segments** (`cjp(NAV)` and `lhs_json_path`) keep `seg`/array
  indices. Required by intent: `value__d__1__has_key="f"` (with `d` a JSON array)
  must compile to `$."d"[1]."f"`, and `value__1__has_key="b"` (column is a list)
  to `$[1]."b"`.
- **`as_postgresql`** does not use `cjp`/`as_sql`; it uses the `?`/`?&`/`?|`
  operators with the key as a string, which already means object key. Unchanged
  and already correct (PostgreSQL was never broken).

## 5. Trusted base / residual risk

- Adequacy of the **mini-X fragment**: `parsesAsInt`/`dumps` abstract the real
  `int()`/`json.dumps()`; the proof depends only on (a) `dumps(str)` is a quoted
  token and (b) `compile_json_path_final_key` has no `parsesAsInt` branch — both
  visible directly in the source.
- Backend acceptance of `$."1111"`: relied upon — it is the *same* quoted-member
  form the pre-existing non-numeric tests (`has_key="a"` → `$."a"`) already use on
  all three backends, so it is exercised by the current passing suite.
- "Constructed, not machine-checked" (run `kompile`/`kprove` to upgrade).
