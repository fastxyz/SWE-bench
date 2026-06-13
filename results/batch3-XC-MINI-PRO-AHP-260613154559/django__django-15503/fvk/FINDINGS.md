# FVK FINDINGS — JSONField `has_key` numeric-key fix

Plain-language findings from formalizing the V1 fix, each as
`input → observed vs expected`. Findings are non-blocking advice; the ones that
drove a V2 code change are marked **[fixed in V2]**, confirmations are **[OK]**,
and out-of-scope/pre-existing ones are **[pre-existing]**.

The code under audit (`repo/django/db/models/fields/json.py`):

```python
class HasKeyLookup(PostgresOperatorLookup):
    def compile_json_path_final_key(self, key_transform):          # V2
        return ".%s" % json.dumps(str(key_transform))
    def as_sql(self, ...):
        ...
        *rhs_key_transforms, final_key = rhs_key_transforms
        rhs_json_path  = compile_json_path(rhs_key_transforms, include_root=False)
        rhs_json_path += self.compile_json_path_final_key(final_key)
        ...
class HasKeyOrArrayIndex(HasKey):
    def compile_json_path_final_key(self, key_transform):
        return compile_json_path([key_transform], include_root=False)
```

---

## F-int — numeric key passed as a non-string `int`/`float` **[fixed in V2]**

Writing contract **C1** forced the precondition `K:str` (the clean post
`isObjectToken(result)` only holds for strings). That precondition is exactly a
**silently-assumed** one the V1 code did not enforce — the same class of bug as
the issue itself.

- input: `data__has_key=1111` (a Python **int**), `data = {'1111':'bar'}`
  - V1 observed: `compile_json_path_final_key(1111)` → `"." + json.dumps(1111)`
    → `".1111"`, i.e. path `$.1111` (an **unquoted** member token). This is not
    the quoted `$."1111"` produced for the string key, and is not reliably
    accepted across SQLite/MySQL/Oracle → may silently match **0 rows**.
  - expected: the key `1111` denotes object key `"1111"`; path must be `$."1111"`,
    identical to `data__has_key='1111'`.
- input: `data__has_key=4.2` → V1 `".4.2"` → path `$.4.2` (two dots, malformed).
- **Why it matters:** `has_key` semantics are "object has this key"; object keys
  are strings, so `1111` and `'1111'` must behave identically. V1 diverges.
- **V2 fix:** coerce `str(key_transform)` before `json.dumps`, mirroring
  `HasKeys.get_prep_lookup`'s existing `[str(item) for item in self.rhs]`. Now
  `compile_json_path_final_key(1111) = "." + json.dumps("1111") = '."1111"'`,
  identical to the string case. Discharges C1 for all scalar inputs.
- **Regression check:** for any string `K`, `str(K) is K`-equivalent, so
  `json.dumps(str(K)) == json.dumps(K)` — byte-identical output. No existing
  (string-key) test or generated SQL changes.

## F-none — `has_key=None` is undefined behavior **[pre-existing, documented]**

- input: `data__has_key=None`
  - pre-fix observed: `compile_json_path([None], False)` does `int(None)` which
    raises **`TypeError`** (only `ValueError` is caught) → 500-level crash.
  - V1 observed: `json.dumps(None)` → `"null"` → path `$.null` (nonsense).
  - V2 observed: `json.dumps(str(None))` → `'"None"'` → `$."None"` (still
    nonsense, but no crash).
- `has_key=None` is meaningless input outside the intended domain. **Kept as a
  finding**, not fixed: the spec domain is "scalar object key". V2 at least no
  longer risks the `TypeError` path here. No test exercises this.

## F-nonempty — the `*nav, final = rhs_key_transforms` unpack **[OK, satisfied]**

The unpack raises `ValueError` if `rhs_key_transforms` is empty. Spec contract
**C5** lists "`rhs_key_transforms` non-empty" as a loop precondition.

- Discharged **structurally**: the two producers are
  `rhs_key_transforms = [key]` (length 1) and
  `*_, rhs_key_transforms = key.preprocess_lhs(...)`, where
  `KeyTransform.preprocess_lhs` seeds `key_transforms = [self.key_name]` and only
  `insert`s — length ≥ 1. So the precondition always holds; **no crash reachable**.
- This is a *positive* finding: the spec checked a real failure mode and proved it
  unreachable. No code change.

## F-navfinal — navigation vs. final-key split is the correct scope **[OK, design]**

The central design question the spec made explicit: which path components become
object-member access?

- Only the **final** key (the key whose existence is tested) → object member
  (`segObject`, contract C5/C1).
- **Navigation** components (`lhs_json_path`, and `cjp(NAV)` for a nested-rhs
  `KeyTransform`) keep `seg` (array index for numeric nav keys).
- input: `value__d__1__has_key="f"`, `value.d = ["e", {"f":"g"}]`
  - observed (V1/V2): `$."d"[1]."f"` — `1` stays an array index (nav), `f` is the
    object final key. ✓ matches the existing `test_has_key_deep`.
- input: `value__1__has_key="b"`, column is the list `[{"a":1},{"b":"x"}]`
  - observed: `$[1]."b"` — `1` array index, `b` object key. ✓ `test_has_key_list`.
- A blanket "all components object-member" change would have produced `$."d"."1"."f"`
  / `$."1"."b"` and **broken** those tests. The spec confirms V1/V2 picked the
  right granularity. No change.

## F-preserve — internal callers unchanged byte-for-byte **[OK, no regression]**

Contracts **C3 (HOMO)** + **C4 (PRESERVE)** prove
`buildPathArr(LJP, NAV, FINAL) = LJP + cjp(NAV ++ [FINAL])`, i.e.
`HasKeyOrArrayIndex.as_sql` emits exactly the string the **original**
`HasKey.as_sql` emitted for the whole key list.

- input: `value__d__0__isnull=False` (heavily used as a base queryset)
  - observed: `$."d"[0]` on both pre-fix and V1/V2 — identical. ✓
- Therefore rewiring `KeyTransformIsNull.as_sqlite/as_oracle` and
  `KeyTransformExact.as_oracle` to `HasKeyOrArrayIndex` cannot change their SQL.
  This was the highest-risk part of V1; the proof retires that risk. No change.

## F-oracle-pct — literal `%` in a plain `has_key` string on Oracle **[pre-existing]**

- input: `data__has_key='a%b'` on Oracle
  - observed: `HasKeyLookup.as_oracle` does `sql % tuple(params)`; the path
    `$."a%b"` contains a lone `%`, so Python `%`-formatting raises/ misformats.
  - This predates the fix: the old `compile_json_path(['a%b'], False)` produced the
    same `."a%b"` (only `KeyTransform`-sourced keys are `%`-escaped by
    `preprocess_lhs`; a bare string `has_key` argument is not). V1/V2 do not change
    this. **Out of scope**, recorded for completeness. No test exercises it.

---

## Proof-derived findings from `/verify`

| # | Evidence (claim/step) | Classification | Outcome |
|---|---|---|---|
| P1 | `FINALKEY` post needs `K:String`; fails for `Int`/`Float`/`None` | missing precondition / needed code guard | **F-int fixed in V2** (`str()` coercion); F-none kept as out-of-domain |
| P2 | `SEG-VS-OBJECT` discharges only for `parsesAsInt(K)` and is *false* without it | confirms scope: fix changes numeric keys **only** | OK — no over-broad change |
| P3 | `HOMO` needs string-concat associativity + identity `[simplification]` (L1,L2); base case `cjp(.List)=""` | routine list induction (the loop circularity) | discharged in bundled tier |
| P4 | `PRESERVE` = `HOMO` instantiated at `B=[FINAL]` | proves zero regression for isnull/exact callers | OK |
| P5 | `ASSQL-OBJECT` final segment `isObjectToken` for all `FINAL` | the bug-fix postcondition holds universally on the domain | OK |
| P6 | unpack `*nav, final` — list-length side obligation | needed code guard? → proved unnecessary (F-nonempty) | OK, no guard needed |

No proof obstacle indicated a *correctness* gap in the navigation/preserve logic.
The single actionable gap was **P1 → F-int**, now closed by V2.
