# FVK Findings

Status: constructed, not machine-checked. Findings are based on public intent,
source inspection, and symbolic reasoning only.

## F-001: Legacy raw bytes display stringified `bytes`

Classification: code bug, fixed in V2.

Evidence:

- Intent ledger E-1/E-2.
- Pre-fix code wrote `"[{}]".format(fixturedef.cached_param)`.
- For the reported direct parameter `b"Hello World"`, direct parametrization is
  represented as a pseudo-fixture with `fixturedef.ids` false, so
  `fixturedef.cached_param` was the original `bytes` object.

Input -> observed vs expected:

- Input: `--setup-show`, `request.param = b"Hello World"`, no explicit fixture
  IDs, Python `-bb`.
- Observed pre-fix: output formatting calls `str(bytes_value)` and raises
  `BytesWarning`.
- Expected: setup-show writes a parameter display without raising
  `BytesWarning`.

Resolution:

- V2 caches `saferepr(request.param, maxsize=42)` in the no-IDs branch before
  `_show_fixture_action` writes the output.

## F-002: V1 under-specified raw parameter representation

Classification: code bug / incomplete fix, fixed in V2.

Evidence:

- Intent ledger E-3/E-4.
- V1 formatted non-string cached values with `saferepr`, but kept raw string
  params as bare strings. That avoided the specific bytes crash, but did not
  uniformly implement the public hint that setup-show displays the raw fixture
  `param` with bounded `saferepr`.

Input -> observed vs expected:

- Input: `--setup-show`, `request.param = "x" * 100`, no explicit fixture IDs.
- Observed in V1 by source inspection: cached raw string would be written as the
  unbounded bare string.
- Expected from E-3/E-4: raw parameter display should use bounded safe
  representation.

Resolution:

- V2 applies `saferepr(..., maxsize=42)` when caching all no-IDs raw params,
  including strings.

## F-003: All-values `saferepr` at write time would over-change explicit IDs

Classification: compatibility risk, avoided in V2.

Evidence:

- Intent ledger E-5.
- Existing setup-only tests use explicit `ids=["spam", "ham"]` as labels.
- `fixturedef.cached_param` historically held either raw params or explicit IDs;
  formatting all cached values at write time cannot distinguish those cases.

Input -> observed vs expected:

- Input: fixture with `params=["foo"]`, `ids=["spam"]`.
- Problematic alternative: `saferepr(fixturedef.cached_param)` in
  `_show_fixture_action` would display `['spam']`.
- Expected: explicit string ID remains a label display `[spam]`.

Resolution:

- V2 formats raw params at cache time, and formats explicit IDs through
  `_format_fixture_id`, preserving plain string IDs while safe-representing
  non-string IDs.

## F-004: Existing raw-string display tests are stale for the raw-param contract

Classification: public-test conflict / SUSPECT legacy behavior.

Evidence:

- Intent ledger E-7.
- Existing tests match raw string fixture params as `arg_same?foo?`.
- E-3/E-4 require bounded `saferepr` for raw params.

Input -> observed vs expected:

- Input: raw fixture param `"foo"` with no explicit `ids=`.
- Legacy expectation: display `[foo]`.
- Expected from the FVK spec: display uses `saferepr("foo", maxsize=42)`, i.e.
  a repr-style display inside the brackets.

Resolution:

- Source code follows the issue-derived raw-param spec.
- Test files were not edited, per task constraints.

## F-005: Proof and tests were not executed

Classification: process / residual risk.

Evidence:

- The task forbids running tests, Python, or K tooling.
- FVK proof artifacts are constructed, not machine-checked.

Input -> observed vs expected:

- Input: the exact K commands in `SPEC.md` / `PROOF.md`.
- Observed: commands were written but not executed.
- Expected later: `kprove fvk/setup-show-spec.k -I fvk` should return `#Top`
  after a human runs the machine-checking commands in an environment with K
  installed.

Resolution:

- Keep relevant tests. Do not remove or mark tests redundant until the emitted
  K commands have been run successfully.
