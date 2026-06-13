# FVK PROOF — JSONField `has_key` path builders

**Constructed, not machine-checked** (MVP: the K toolchain is not executed). This
write-up constructs the correctness proof of the claims in `fvk/json_path-spec.k`
against the fragment semantics in `fvk/json_path.k`, by symbolic execution + one
list-induction circularity (`HOMO`). Obligations are itemized in
`fvk/PROOF_OBLIGATIONS.md`.

Default scope: **partial correctness**. Note the builders (`compile_json_path`,
`compile_json_path_final_key`) are **structurally recursive over a finite key
list** with no unbounded loop, so they are **total** and termination is immediate
(the list strictly shrinks each step) — partial = total here.

---

## What is proved (plain language)

1. **The fix (C1/FINALKEY).** For every key string `K`,
   `compile_json_path_final_key(K)` returns the object-member token `."<K>"` — and
   this holds for **all** `K`, *including numeric* `K` like `"1111"`. There is no
   array branch in this function, so the checked key is never compiled to `[1111]`.
   This is exactly "we shouldn't use array paths for these lookups."
2. **The change is minimal (C2/SEG-VS-OBJECT).** The new final-key form differs
   from the old one **only** on numeric keys; on non-numeric keys it is identical.
3. **No regression for the rewired callers (C3+C4/HOMO+PRESERVE).**
   `HasKeyOrArrayIndex.as_sql` produces **byte-identical** SQL to the original
   `HasKey.as_sql`, so `value__d__0__isnull`, `value__1__has_key`,
   `value__d__1__has_key`, and the Oracle exact-null branch are unchanged.
4. **The full lookup (C5/ASSQL-OBJECT).** Each rhs path is
   `lhs_json_path + navigation + object-final-key`, navigation keeping array
   indices, the final key always an object member, with the loop's only
   precondition (non-empty key list) proved unreachable-to-violate.

## Proof 1 — FINALKEY (the fix), short form

`compile_json_path_final_key(K)` ⇝ `".%s" % json.dumps(str(K))`.
- For `K:String`, `str(K) = K`, so the value is `"." +String dumps(K) = segObject(K)`  (O1).
- `isObjectToken(segObject(K)) = isObjectToken("." +String dumps(K)) ⇝ true` by the
  `[simplification]` rule on `dumps` (O2): `json.dumps` of a string is a quoted
  token, so `."<quoted>"` begins with `."` and is not an array token.
- There is **no** `try int(...)`/`parsesAsInt` branch in this function (O3); the
  numeric case is therefore *not* special-cased. ∎

This is the crux: contrast `compile_json_path([K], False)` which *does* branch
(`seg(K)`), giving `"[1111]"` for `K="1111"` — the original bug — with
`compile_json_path_final_key(K)` which gives `."1111"`.

## Proof 2 — HOMO (the loop circularity) and PRESERVE

`HOMO: cjp(A ++ B) = cjp(A) +String cjp(B)`, by induction on `A` (K uses the claim
as its own coinductive hypothesis; guardedness from the `cjp` unfold step, O8):

- **Base** `A = .List` (O6): `cjp(B) = "" +String cjp(B)` by left-identity L2. ✓
- **Step** `A = ListItem(K) A'` (O7): unfold
  `cjp(ListItem(K) A' ++ B) = seg(K) +String cjp(A' ++ B)`; apply the circularity
  hypothesis to `A'`: `= seg(K) +String (cjp(A') +String cjp(B))`; reassociate (L1)
  to `(seg(K) +String cjp(A')) +String cjp(B) = cjp(ListItem(K) A') +String cjp(B)`. ✓

`PRESERVE` (O9–O12) instantiates `HOMO` at `B = ListItem(FINAL)` and uses
`cjp(ListItem(FINAL)) = seg(FINAL)` (cjp base + L2):
`buildPathArr(LJP,NAV,FINAL) = LJP + cjp(NAV) + seg(FINAL) = LJP + cjp(NAV ++ [FINAL])`.
Since the **original** `HasKey.as_sql` computed `lhs_json_path + cjp(rhs_key_transforms)`
for the whole list, and `HasKeyOrArrayIndex.compile_json_path_final_key = seg`,
the two are equal. ∎  (This retires the highest-risk part of the V1 change.)

## Proof 3 — ASSQL-OBJECT (the lookup loop)

The rhs loop maps `buildPathObj(lhs_json_path, nav(k), final(k))` over `rhs`
(O16, a trivial map circularity — iterations are independent, O17 unchanged
return). Each entry (O13) is `LJP + cjp(NAV) + segObject(FINAL)`; the final
segment is an object token for all `FINAL` (O14 = O2). The unpack precondition
"non-empty `rhs_key_transforms`" (O15) is discharged structurally (both producers
yield length ≥ 1), so no `ValueError` is reachable. ∎

## Machine-detailed sketch (for `kprove`)

- `kompile json_path.k --backend haskell` compiles the fragment (functions
  `parsesAsInt`, `dumps`, `seg`, `segObject`, `cjp`, `buildPathObj/Arr` + the
  `isObjectToken` simplifications).
- Each claim is `[one-path]` over pure functional terms (no `<store>` mutation
  needed — these are total functions), so symbolic execution is just rewriting to
  a normal form, then the `ensures` equality is dispatched by Z3 / the L1–L2 +
  `isObjectToken` `[simplification]` lemmas.
- `HOMO` is the only inductive claim; K discharges it by the circularity on the
  `cjp(ListItem(_) _)` recursion (guardedness O8).
- Expected `kprove` result: **`#Top`** for all five claims.

## Reproduce the machine check

```sh
cd fvk
kompile json_path.k --backend haskell        # compile the fragment semantics
kast    --backend haskell json_path-spec.k    # (optional) parse-check the claims
kprove  json_path-spec.k                       # discharge; expected: #Top
```

Until `kprove` returns `#Top`, treat every result here as **constructed, not
machine-checked**, and keep the tests below.

---

## Benefit 1 — test-redundancy (recommendation only; conditioned on `kprove`)

Mapping `repo/tests/model_fields/test_jsonfield.py` onto the proved contracts.
**Nothing is auto-deleted; recommendations are conditioned on a `#Top` from the
emitted commands AND on these being unit checks of the path strings only.**

- **Subsumed-once-machine-checked** (each a single in-domain point of C1/C5):
  - `test_has_key` (`value__has_key="a"` → `$."a"`) — C5 with non-numeric final.
  - the numeric-key assertion the issue adds (`has_key='1111'` → `$."1111"`) — C1.
  - `test_has_keys`, `test_has_any_keys` — C5 per-key, object final keys.
  These are single input/output points the universal contracts already cover.
- **KEEP — explicitly** (outside the verified string-builder unit, or pin the
  exact behaviors the proof *relies on* but does not itself execute end-to-end):
  - `test_has_key_deep`, `test_has_key_list` — pin **navigation** array indices
    (`$."d"[1]."f"`, `$[1]."b"`); these guard F-navfinal and the `cjp`/seg split,
    and they exercise real DB execution, not just the string.
  - every `value__d__0__isnull=False` base queryset and `test_isnull_key` — pin
    F-preserve at the DB level (the proof shows the *string* is unchanged; the
    test confirms the DB still matches).
  - all **cross-backend** runs (SQLite/MySQL/Oracle/PostgreSQL) — the proof
    assumes backend acceptance of `$."1111"`; integration tests, always kept.
  - `test_key_escape` (`%`-keys) — guards F-oracle-pct territory.

Net: a small number of pure input/output unit points become redundant *after*
machine-checking; all navigation, isnull, escape, and cross-backend tests are
**kept**. Conservative CI savings — keep everything until `kprove` is run.

## Benefit 2 — bugs surfaced (full confidence, independent of machine-check)

- **F-int** (now fixed in V2): numeric key as `int`/`float` produced an unquoted
  `$.1111` / malformed `$.4.2` — same bug class as the issue, for non-string
  numerics. Closed by `str()` coercion.
- **F-none / F-oracle-pct**: out-of-domain / pre-existing, recorded.
- **F-nonempty / F-preserve / F-navfinal**: confirmations the spec turned into
  proved facts (no crash on empty list; zero regression for internal callers;
  correct nav-vs-final granularity).

See `fvk/FINDINGS.md` for the `input → observed vs expected` detail.
