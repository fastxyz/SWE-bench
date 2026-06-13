# FVK notes — audit of the django__django-15503 fix

This documents the FVK audit of the V1 fix and the single V2 code change it
produced, tracing each decision to `fvk/FINDINGS.md` and
`fvk/PROOF_OBLIGATIONS.md`. Artifacts: `fvk/SPEC.md`, `fvk/FINDINGS.md`,
`fvk/PROOF_OBLIGATIONS.md`, `fvk/PROOF.md`, `fvk/ITERATION_GUIDANCE.md`, plus the
constructed K files `fvk/json_path.k` and `fvk/json_path-spec.k` (all **constructed,
not machine-checked**).

## What I formalized

The fix is pure JSON-path **string construction**, so I built a mini-Python
fragment (`json_path.k`) modelling the key list, string concatenation, and the two
opaque library calls (`int()` → `parsesAsInt`, `json.dumps()` → `dumps`). The
central contracts (`fvk/SPEC.md` §3):
- **C1/FINALKEY** — the checked key is *unconditionally* an object member;
- **C2/SEG-VS-OBJECT** — the change touches numeric keys *only*;
- **C3/HOMO + C4/PRESERVE** — `HasKeyOrArrayIndex` reproduces the original SQL;
- **C5/ASSQL-OBJECT** — the lookup loop = navigation (array-aware) + object final.

## The one code change (V1 → V2)

**`HasKeyLookup.compile_json_path_final_key` now coerces `str(key_transform)`
before `json.dumps`.**

- **Trace:** Finding **F-int** ⇄ obligation **O1-pre** / proof-derived **P1**.
  Writing C1 forced the precondition `K:str` — the clean postcondition
  `isObjectToken(result)` (O2) only holds for strings. That precondition was a
  *silently-assumed* one V1 did not enforce: `compile_json_path_final_key(1111)`
  (int) returned `".1111"` (path `$.1111`, unquoted) and `…(4.2)` returned
  `".4.2"` (path `$.4.2`, malformed) — the **same bug class as the issue itself**,
  for numeric keys that arrive as `int`/`float` instead of strings.
- **Why this fix and not another:** the value is always a JSON object key (a
  string); `HasKeys.get_prep_lookup` already does `[str(item) for item in self.rhs]`,
  so `str()`-coercing the single `has_key` key is the consistent, minimal closure
  of O1-pre. It lives in `compile_json_path_final_key` because that is the unique
  point where the scalar final key is rendered (nested `KeyTransform`/`F()` rhs go
  through the `isinstance(key, KeyTransform)` branch and never reach here as raw
  scalars).
- **Why it is safe (no regression):** for any string `K`, `str(K)` is
  value-identical, so `json.dumps(str(K)) == json.dumps(K)` — byte-identical SQL.
  The reported issue's `has_key='1111'` and every existing string-key test produce
  exactly the V1 output. Verified against F-int's regression note and **O17**
  (param/placeholder count and the join/return are untouched — the edit changed
  only how one segment string is built).
- **Scope confinement:** `HasKeyOrArrayIndex` *overrides*
  `compile_json_path_final_key` (using `compile_json_path([K], False)`), so the
  `str()` change does **not** touch the isnull/exact callers (their keys are
  already strings from `KeyTransform.__init__` anyway). Confirmed by O9/F-preserve.

## What I deliberately kept unchanged in V1 (each justified)

1. **Navigation keeps array indices** (`compile_json_path` for `lhs_json_path` and
   nested-rhs `NAV`). Trace: Finding **F-navfinal** ⇄ **C2/O5** + **C5**. The spec
   showed a blanket "object-member everywhere" change would compile
   `value__d__1__has_key="f"` to `$."d"."1"."f"` and break `test_has_key_deep` /
   `test_has_key_list`. V1's nav-vs-final granularity is provably the correct
   scope, so it stands.

2. **`HasKeyOrArrayIndex` and the three rewired callers**
   (`KeyTransformIsNull.as_sqlite/as_oracle`, `KeyTransformExact.as_oracle`). Trace:
   Finding **F-preserve** ⇄ **C3/HOMO (O6–O8)** + **C4/PRESERVE (O9–O12)**. The
   homomorphism `cjp(A++B)=cjp(A)+cjp(B)` instantiated at `B=[FINAL]` proves
   `HasKeyOrArrayIndex.as_sql` emits the *byte-identical* string the original
   `HasKey.as_sql` did, so `value__d__0__isnull` (and all the base querysets built
   on it), `value__1__has_key`, etc. are unchanged. This was the highest-risk part
   of V1; the proof retires the risk, so it stands unchanged.

3. **The `*rhs_key_transforms, final_key = …` unpack** (no length guard added).
   Trace: Finding **F-nonempty** ⇄ obligation **O15**. The `ValueError`-on-empty
   risk is proved unreachable: both producers yield a length-≥1 list. A guard would
   be dead code, so none was added.

4. **`as_postgresql`** untouched. Trace: **O18** — it never calls the path builders
   (uses `?`/`?&`/`?|`), and PostgreSQL was never broken (per PROBLEM.md).

## Items surfaced but intentionally NOT fixed (out of scope)

- **F-none** (`has_key=None`): meaningless input outside the spec domain
  ("scalar object key"). V2 incidentally removes the pre-fix `TypeError` risk but I
  did not add validation — that is an intent question (ITERATION_GUIDANCE §2 Q2),
  not a correctness obligation, and no test exercises it.
- **F-oracle-pct** (literal `%` in a bare-string `has_key` on Oracle):
  **pre-existing** (the old `compile_json_path` had the identical behavior),
  untested, and orthogonal to numeric keys. Recorded as a follow-up (Q3), not
  fixed, to keep the diff minimal.

## Verification status & honesty gate

The proof is **constructed, not machine-checked** — `fvk/PROOF.md` emits the exact
`kompile`/`kprove` commands; expected result `#Top`. The Benefit-2 findings
(F-int etc.) hold independently of machine-checking. The Benefit-1 test-removal
suggestions are **recommendation-only, conditioned on `kprove` returning `#Top`**;
all navigation, isnull, escape, and cross-backend tests are explicitly **kept**. I
did not modify any test files.

## Net

V1 was correct for the reported (string numeric key) domain and for all existing
tests; the audit confirmed that (C2–C5, F-navfinal/F-preserve/F-nonempty) and
surfaced one real adjacent gap (**F-int**: non-string numeric keys), closed by a
single zero-risk `str()` coercion that discharges obligation **O1-pre** while
leaving every other behavior byte-identical.
