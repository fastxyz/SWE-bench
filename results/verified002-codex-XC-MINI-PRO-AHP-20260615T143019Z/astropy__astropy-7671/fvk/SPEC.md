# FVK Specification: astropy.utils.introspection.minversion

Status: constructed, not machine-checked. No tests, Python, or K tools were run.

## Scope

The audited unit is the public function `minversion` in
`repo/astropy/utils/introspection.py`, plus the private helper
`_version_to_looseversion` introduced by the V1 fix. The proof models the
comparison-relevant behavior:

- resolving an already imported module or module name is abstracted to either a
  module with a version string, a missing import, or an invalid module argument;
- obtaining `have_version` through `version_path` is abstracted to the version
  string retrieved from the module;
- `LooseVersion` comparison is modeled only for numeric release lists, because
  the public issue and in-repo callsites exercise numeric package versions.

The proof is partial correctness: if the modeled function returns, it returns
the value specified below. Termination is not separately proved.

## Intent Ledger

| ID | Source | Evidence | Semantic obligation | Status |
|---|---|---|---|---|
| I1 | prompt | "`minversion('numpy', '1.14dev')`" raises `TypeError` | `minversion` must return a boolean, not propagate the mixed int/string `LooseVersion` failure, for numeric release versions with development suffixes. | Encoded in claims C1-C3. |
| I2 | prompt | "`LooseVersion('1.14.3') >= LooseVersion('1.14dev')`" raises `TypeError` | The root comparison hazard is suffix tokens in one version and numeric patch tokens in the other. | Encoded by suffix-stripping normalization obligation PO2. |
| I3 | prompt | "`parse_version('1.14.3') >= parse_version('1.14dev')` returns `True`" | For the reported case, installed `1.14.3` satisfies minimum `1.14dev`. | Encoded by example claim C1. |
| I4 | public hint | "put the regex back in that was there for `LooseVersion`" and "don't want to go back to `pkg_resources`" | Keep `LooseVersion`, but normalize version strings with a regex before comparison. | Encoded by PO2 and implementation check. |
| I5 | docstring | "`version` ... minimum (e.g. `'0.12'`)" and `inclusive` means `>=` by default, strict `>` otherwise | Inclusive mode uses greater-than-or-equal; exclusive mode uses greater-than on normalized release values. | Encoded by C2 and C3. |
| I6 | docstring | module can be module object or import name; failed import returns `False`; invalid type raises `ValueError` | Preserve public control-flow behavior outside version comparison. | Encoded by C4 and C5. |
| I7 | public tests/calls | tests use `0.12`, `0.12.1`, `0.12.0.dev`, `1`, `1.2rc1`; callsites use `numpy`, `matplotlib`, `yaml`, `scipy` numeric versions | Numeric release strings with optional suffixes are the intended domain for this fix. | Encoded as domain precondition PO1. |

## Intended Contract

Let `numeric_prefix(v)` be the leading sequence of decimal integer components in
a version string, separated by dots. Examples:

- `numeric_prefix("1.14dev") = [1, 14]`
- `numeric_prefix("1.14.3") = [1, 14, 3]`
- `numeric_prefix("0.12.0.dev") = [0, 12, 0]`

For in-domain version strings where both the installed version and required
version have such a numeric prefix:

1. `_version_to_looseversion(v)` returns `LooseVersion` applied to only
   `numeric_prefix(v)`, so suffix components such as `dev` and `rc1` are not
   present in the `LooseVersion` value compared by `minversion`.
2. `minversion(module, version, inclusive=True)` returns
   `LooseVersion(numeric_prefix(have_version)) >=
   LooseVersion(numeric_prefix(version))`.
3. `minversion(module, version, inclusive=False)` returns
   `LooseVersion(numeric_prefix(have_version)) >
   LooseVersion(numeric_prefix(version))`.
4. Missing import by module name returns `False`.
5. Invalid `module` argument type raises `ValueError`.

The in-domain comparison uses the same numeric-list ordering that
`LooseVersion` uses once suffix tokens have been removed: compare integer
components left to right; if all compared components match, the longer numeric
list sorts after the shorter one.

## Out of Scope / Residual Ambiguity

The public issue does not require full PEP 440 parsing. The FVK spec therefore
does not claim correctness for version strings without a leading numeric release
segment or for every possible package-version spelling. This is recorded in
`fvk/FINDINGS.md` as residual scope, not as a code bug.
