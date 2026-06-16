# Constructed Proof

Status: constructed, not machine-checked.

## Claims Proved In The Model

The K-style claims in `fvk/get-format-spec.k` cover every branch relevant to a
lazy string `format_type`:

- C-001: localized arbitrary fallback returns `rawFormat(S)`.
- C-002: localized module hit returns `moduleValue(S)`.
- C-003: localized settings fallback returns `settingsValue(S)`.
- C-004: non-localized settings fallback returns `settingsValue(S)`.
- C-005: non-localized arbitrary fallback returns `rawFormat(S)`.
- C-006: cache hit returns `cacheValue(S)`.
- C-007: out-of-domain non-Promise values are not proven as broadly coerced.

There are no loops or recursive calls in the audited fragment, so no circularity
claim is required.

## Symbolic Execution Sketch

For any in-domain lazy string input `promiseType(S)`, the first semantic rule
rewrites:

```text
getFormat(promiseType(S), USE, CACHE, MODULE, INSETTINGS)
=> normalize(promiseType(S)) ~> continueWith(USE, CACHE, MODULE, INSETTINGS)
```

The normalization rule then rewrites:

```text
normalize(promiseType(S)) => strType(S)
```

After this step, the continuation receives `strType(S)` and rewrites to:

```text
resolve(S, USE, CACHE, MODULE, INSETTINGS)
```

All branch-specific rules operate on `S:String`, not on `promiseType(S)`.
Therefore the modeled `getattr()` failure rule for out-of-domain non-string
inputs is unreachable for `promiseType(S)`.

Case split over the branch booleans:

- `CACHE = true`: returns `cacheValue(S)`, discharging PO-001 and PO-004 for
  cache hits.
- `USE = true`, `CACHE = false`, `MODULE = true`: returns `moduleValue(S)`,
  discharging PO-002 and PO-004 for localized module lookup.
- `USE = true`, `CACHE = false`, `MODULE = false`, `INSETTINGS = true`: returns
  `settingsValue(S)`, discharging PO-002 and PO-004 for settings fallback.
- `USE = false`, `CACHE = false`, `INSETTINGS = true`: returns
  `settingsValue(S)`, discharging PO-004 without localized lookup.
- No module/settings value: returns `rawFormat(S)`, discharging PO-003 for the
  issue example family.

The real source implements the same ordering in
`repo/django/utils/formats.py`: V1 normalizes `Promise` values immediately after
language selection and before `cache_key`, `getattr(module, ...)`,
`format_type not in FORMAT_SETTINGS`, `getattr(settings, ...)`, and
`return format_type`.

## Adequacy

`fvk/FORMAL_SPEC_ENGLISH.md` paraphrases every nontrivial claim.
`fvk/SPEC_AUDIT.md` compares those paraphrases to the public intent. All
entries pass; none are marked fail or ambiguous.

The model abstracts concrete settings/module values, but it does not abstract
away the property under test. A passing instance and failing instance remain
distinguishable:

- Passing: `promiseType("Y-m-d")` normalizes to `strType("Y-m-d")` and reaches
  `rawFormat("Y-m-d")`.
- Failing pre-fix shape: a non-string reaching the localized lookup path reaches
  `typeError("getattr(): attribute name must be string")`.

## Commands Not Run

The commands to machine-check later are:

```sh
cd fvk
kompile mini-django-formats.k --backend haskell
kast --backend haskell get-format-spec.k
kprove get-format-spec.k
```

Expected successful result: `#Top` for all claims.

## Test Guidance

No tests were inspected for deletion and no test files were modified. Existing
tests should be kept until the K claims are machine-checked. Useful public tests
to add or keep would assert that `get_format(gettext_lazy("Y-m-d"))` returns
`"Y-m-d"` and that the `date` template filter accepts a lazy format string.
