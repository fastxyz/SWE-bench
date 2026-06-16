# FVK Proof Obligations

Status: constructed, not machine-checked. No `kprove` command was executed.

## PO-001: Raw bytes params do not reach `str(bytes)`

Finding: F-001.

Claim:

For every raw bytes parameter `B`, the setup-show cache step reaches
`safeRepr42(bytesParam(B))`, not `bytesWarning`.

K claim:

```k
claim <k> rawParam(bytesParam(B:String)) => safeRepr42(bytesParam(B)) </k>
  [all-path]
```

Source obligation:

- `pytest_fixture_setup`, no-IDs branch:
  `fixturedef.cached_param = saferepr(request.param, maxsize=42)`.

Discharge argument:

- In the no-IDs branch, the original `bytes` object is immediately converted to a
  safe display string.
- `_show_fixture_action` later writes that cached string, not the original
  object.

## PO-002: Cached displays are written without re-reading the raw parameter

Findings: F-001, F-003.

Claim:

For every cached `Display D`, setup-show output wraps `D` in brackets and returns
`ok(bracket(D))`.

K claim:

```k
claim <k> writeCached(safeRepr42(bytesParam(B:String)))
       => ok(bracket(safeRepr42(bytesParam(B))))
    </k>
  [all-path]
```

Source obligation:

- `_show_fixture_action` executes `tw.write("[{}]".format(fixturedef.cached_param))`.
- After V2, `fixturedef.cached_param` is already a display string for raw params.

Discharge argument:

- Python `str.format` receives a string, so no `bytes.__str__` path is reachable
  for raw bytes params.
- The setup and teardown paths both use the same cached display.

## PO-003: Raw params use bounded safe representation uniformly

Finding: F-002.

Claim:

For every raw parameter in the modeled domain, the no-IDs branch uses
`safeRepr42(P)`.

K rule:

```k
rule <k> rawParam(P:Param) => safeRepr42(P) </k>
```

Source obligation:

- `fixturedef.ids` false branch in `pytest_fixture_setup` uses
  `saferepr(request.param, maxsize=SETUP_SHOW_PARAM_MAXSIZE)`.
- `SETUP_SHOW_PARAM_MAXSIZE == 42`.

Discharge argument:

- The code has only one no-IDs assignment to `fixturedef.cached_param`.
- The assignment is independent of the concrete runtime type of `request.param`.

## PO-004: Explicit string IDs remain labels

Finding: F-003.

Claim:

For every explicit string ID `S`, formatting the ID returns `display(S)`.

K claim:

```k
claim <k> fixtureId(idStr(S:String)) => display(S) </k>
  [all-path]
```

Source obligation:

- `_format_fixture_id` returns `param` unchanged when `isinstance(param, str)`.

Discharge argument:

- The callable-IDs and indexed-IDs branches both call `_format_fixture_id`.
- Plain string labels are not passed through raw-param `saferepr`, avoiding the
  broad write-time formatting change rejected in F-003.

## PO-005: Explicit non-string IDs cannot reintroduce bytes stringification

Finding: F-003.

Claim:

For every explicit bytes-like ID `B`, formatting the ID returns
`safeRepr42(bytesParam(B))`.

K claim:

```k
claim <k> fixtureId(idBytes(B:String)) => safeRepr42(bytesParam(B)) </k>
  [all-path]
```

Source obligation:

- `_format_fixture_id` routes non-`str` ID values to
  `saferepr(param, maxsize=42)`.

Discharge argument:

- If an ID function returns a bytes value, `_show_fixture_action` still receives a
  safe display string and cannot call `str(bytes)` while writing brackets.

## PO-006: Frame behavior is unchanged

Findings: no open code bug; supports IS-5.

Claim:

The V2 change only affects the value stored in `fixturedef.cached_param` when a
parameter exists. It does not change when setup-show writes, when capture is
suspended/resumed, when dependencies are listed, or when `cached_param` is
deleted after teardown.

Source obligation:

- The diff touches only the cached display assignment and adds `_format_fixture_id`.
- `_show_fixture_action`, `pytest_fixture_post_finalizer`, and
  `pytest_cmdline_main` control flow remain otherwise unchanged.

Discharge argument:

- No hook signatures or public API entry points changed.
- `cached_param` remains internal to `setuponly.py`.

## Machine-Check Commands

Commands to run later in a K environment:

```sh
kompile fvk/mini-pytest-setup-show.k --backend haskell
kast --backend haskell fvk/setup-show-spec.k -I fvk
kprove fvk/setup-show-spec.k -I fvk
```

Expected machine-check result after any syntax adjustments required by the local
K version: `#Top`.
