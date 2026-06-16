# FVK Specification: pytest-dev__pytest-7205

Status: constructed, not machine-checked. No tests, Python, `kompile`, or
`kprove` were executed.

## Scope

Target source:

- `repo/src/_pytest/setuponly.py`

Audited behavior:

- `pytest_fixture_setup` caches the active fixture parameter display used by
  `--setup-show` / `--setup-only` / `--setup-plan`.
- `_show_fixture_action` writes that cached display during setup and teardown.
- `_format_fixture_id` handles explicit user-provided fixture IDs.

Out of scope:

- Fixture resolution, parametrization collection, and terminal writer internals.
  The issue traceback localizes the failure to formatting `fixturedef.cached_param`
  inside `_show_fixture_action`.

## Intent Spec

IS-1. For an in-domain parametrized fixture or pseudo-fixture with
`request.param = b"Hello World"` and `--setup-show` enabled, pytest must not raise
`BytesWarning` while writing the setup line under `python -bb`.

IS-2. Raw fixture parameters displayed by setup-show should be represented with
pytest's safe representation machinery rather than implicit `str()`.

IS-3. The raw parameter representation should be bounded by a smaller maximum
than the default `saferepr` size of 240. The chosen bound is 42, matching an
existing small `saferepr(..., maxsize=42)` convention in pytest assertion output.

IS-4. Explicit fixture IDs are display labels, not raw parameters. Plain string
IDs should remain plain labels; non-string IDs should still be made safe before
being cached for output.

IS-5. The setup-show frame behavior is preserved: no parameter display is added
when no `cached_param` exists, and cached parameter display is reused for teardown
until `pytest_fixture_post_finalizer` deletes it.

## Public Evidence Ledger

E-1. Source: prompt. Evidence: "BytesWarning when using --setup-show with bytes
parameter". Obligation: eliminate `BytesWarning` for bytes parameters in
setup-show output. Status: encoded by K claims `rawParam(bytesParam(B))` and
`writeCached(safeRepr42(bytesParam(B)))`; implemented in V2.

E-2. Source: prompt traceback. Evidence:
`tw.write("[{}]".format(fixturedef.cached_param))` raises
`BytesWarning: str() on a bytes instance`. Obligation: the writer must not receive
the original bytes object and stringify it. Status: encoded by the postcondition
that `writeCached` takes a `Display`; implemented by caching a string display.

E-3. Source: prompt. Evidence: "Shouldn't that be using `saferepr` or something
rather than (implicitly) `str()`?" Obligation: use safe representation for raw
params, not implicit string conversion. Status: encoded by `rawParam(P) =>
safeRepr42(P)`; implemented by `saferepr(request.param, maxsize=42)`.

E-4. Source: public hint. Evidence: "Probably with a shorter `maxsize` than the
default as well, 240 is too long." Obligation: bound raw parameter display below
240. Status: encoded by `safeRepr42`; implemented by
`SETUP_SHOW_PARAM_MAXSIZE = 42`.

E-5. Source: public tests. Evidence: `ids=["spam", "ham"]` are matched as
display labels in setup-only tests. Obligation: do not reinterpret explicit
string IDs as raw params. Status: encoded by `fixtureId(idStr(S)) => display(S)`;
implemented by `_format_fixture_id`.

E-6. Source: implementation. Evidence: direct parametrization is converted to
pseudo-fixtures with `ids=False` in `add_funcarg_pseudo_fixture_def`. Obligation:
the no-IDs branch must handle the reported `@pytest.mark.parametrize` bytes
case. Status: implemented by applying `saferepr` in the `else` branch for
`fixturedef.ids`.

E-7. Source: public tests, marked SUSPECT for raw params only. Evidence:
existing tests match raw string params as `arg_same?foo?`. Obligation conflict:
this legacy output form is weaker than E-3/E-4 for raw params because it keeps
implicit string display and no bounded repr. Status: not used to veto IS-2/IS-3;
explicit string IDs remain preserved under IS-4.

## Formal Spec English

C-1. Raw bytes parameters reach a safe, bounded display representation instead
of a `BytesWarning` outcome.

C-2. Once a raw parameter has been cached as a display string, setup-show output
wraps that display in brackets and does not inspect or stringify the original
parameter object.

C-3. Raw parameters of any modeled kind (`str`, `bytes`, `other`) use the same
`safeRepr42` representation path.

C-4. Explicit plain string IDs remain display strings exactly as supplied.

C-5. Explicit non-string IDs are safe-represented before caching, so a bytes ID
cannot reintroduce the `str(bytes)` warning path.

## Spec Audit

C-1 passes: it directly matches E-1, E-2, and E-3.

C-2 passes: it directly matches E-2 and the implementation-localized traceback.

C-3 passes for raw params: E-3 says the raw fixture `param` should use
`saferepr`; E-4 adds the bounded-size requirement. The older public test pattern
for raw strings is marked SUSPECT because it preserves the legacy raw-param
display behavior rather than the issue's safe-repr intent.

C-4 passes: E-5 supports treating explicit IDs as labels. This is a narrower
compatibility condition than preserving all raw string output.

C-5 passes: it follows from E-1/E-3 by preventing a bytes-like explicit ID from
using implicit stringification.

No required behavior is marked fail or ambiguous after the V2 edit.

## Public Compatibility Audit

Changed public symbols: none.

Changed private/internal symbols:

- Added `_format_fixture_id(param)` in `setuponly.py`.
- Added `SETUP_SHOW_PARAM_MAXSIZE`.
- Changed internal meaning of `fixturedef.cached_param` while setup-show is
  active: it is now a cached display string, not the original raw parameter in
  the no-IDs branch.

Public callsites and overrides:

- `rg cached_param` finds use only inside `repo/src/_pytest/setuponly.py`.
- `_show_fixture_action` is private and called only by setup-only hooks.
- No public function signatures, hook signatures, or fixture APIs changed.

Compatibility conclusion:

- Explicit string IDs remain label-compatible.
- Raw string parameter display intentionally changes from bare string to repr
  string because that is the raw-param safe-repr obligation from the issue. Tests
  asserting the old raw-string display shape should be treated as stale relative
  to this issue's intent; test files were not edited.

## Formal Core

Constructed K semantics: `fvk/mini-pytest-setup-show.k`.

Constructed K claims: `fvk/setup-show-spec.k`.

Exact commands to machine-check later, not executed in this session:

```sh
kompile fvk/mini-pytest-setup-show.k --backend haskell
kast --backend haskell fvk/setup-show-spec.k -I fvk
kprove fvk/setup-show-spec.k -I fvk
```
