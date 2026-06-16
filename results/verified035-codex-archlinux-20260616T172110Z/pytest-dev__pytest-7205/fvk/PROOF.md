# FVK Proof

Status: constructed, not machine-checked. This proof was written by source
inspection and symbolic reasoning. The K commands below were not executed.

## What Is Proved

For the audited setup-show formatter/cache path:

1. Raw fixture parameters with no explicit IDs are converted to
   `saferepr(param, maxsize=42)` before output.
2. A raw bytes parameter therefore cannot reach the legacy
   `"[{}]".format(bytes_value)` path that emits `BytesWarning`.
3. `_show_fixture_action` writes only the cached display string for setup and
   teardown.
4. Explicit string fixture IDs remain display labels, while explicit non-string
   IDs are safe-represented.

This is a partial-correctness proof over the formatting path. Termination is not
separately proved; the audited code path has no loops or recursion.

## Constructed Proof Sketch

### PO-001 / PO-003: raw parameter cache step

In V2, the only no-IDs assignment is:

```python
fixturedef.cached_param = saferepr(
    request.param, maxsize=SETUP_SHOW_PARAM_MAXSIZE
)
```

with `SETUP_SHOW_PARAM_MAXSIZE = 42`.

Symbolically, for arbitrary raw parameter `P`:

```k
rawParam(P) => safeRepr42(P)
```

Specializing `P = bytesParam(B)` gives:

```k
rawParam(bytesParam(B)) => safeRepr42(bytesParam(B))
```

The modeled legacy error transition is:

```k
oldWriteParam(bytesParam(B)) => bytesWarning
```

The V2 raw-param path does not use `oldWriteParam`; it rewrites to a display
value before the writer runs. Therefore the `bytesWarning` outcome is
unreachable on this path.

### PO-002: cached display write step

After PO-001, the writer input is a display value. The model reduces:

```k
writeCached(D) => ok(bracket(D))
```

For the reported bytes case:

```k
writeCached(safeRepr42(bytesParam(B)))
  => ok(bracket(safeRepr42(bytesParam(B))))
```

This corresponds to `_show_fixture_action` formatting a cached string. Python's
`str.format` may call `str()` on the cached string, but not on the original
`bytes` object, so the reported `str(bytes)` warning path is eliminated.

### PO-004: explicit string IDs

For explicit IDs, V2 calls `_format_fixture_id` before caching.

The string branch is:

```python
if isinstance(param, str):
    return param
```

Symbolically:

```k
fixtureId(idStr(S)) => display(S)
```

Thus user-provided labels such as `"spam"` remain labels and are not converted
to repr-style raw-param output.

### PO-005: explicit non-string IDs

The non-string branch of `_format_fixture_id` is:

```python
return saferepr(param, maxsize=SETUP_SHOW_PARAM_MAXSIZE)
```

Symbolically:

```k
fixtureId(idBytes(B)) => safeRepr42(bytesParam(B))
```

So even an unusual bytes-valued ID function result cannot reintroduce the
`str(bytes)` warning in `_show_fixture_action`.

### PO-006: frame behavior

The diff leaves the hookwrapper structure, capture suspension/resumption,
dependency display, terminal flush, teardown display, and deletion of
`cached_param` unchanged. The only changed state value is the internal cached
display string. This discharges the frame obligation.

## Proof-Derived Findings

The proof construction surfaced F-002: V1's type-specific formatter fixed the
reported bytes crash but did not prove the stronger raw-param contract from the
public hint, because raw strings were still unbounded bare strings. V2 repairs
that by moving raw-param `saferepr` to the cache step.

The proof also surfaced F-003: applying `saferepr` blindly in
`_show_fixture_action` would not distinguish raw params from explicit IDs.
V2 keeps those cases separate.

## Test-Redundancy Recommendation

No tests should be removed.

Reasons:

- The task forbids running tests and K tooling.
- The proof is constructed, not machine-checked.
- The proof covers a narrow formatting path, while setup-only tests also cover
  integration behavior such as hook ordering, fixture scoping, capture, and
  teardown.

After a successful `kprove` result, a narrowly targeted bytes setup-show unit
test would be logically subsumed by PO-001/PO-002, but keeping integration tests
would still be appropriate.

## Machine-Check Commands

Not executed:

```sh
kompile fvk/mini-pytest-setup-show.k --backend haskell
kast --backend haskell fvk/setup-show-spec.k -I fvk
kprove fvk/setup-show-spec.k -I fvk
```

Expected result after machine-checking in a suitable K environment: `#Top`.

## Residual Risk

- The K files are a small abstract semantics of the formatter path, not a full
  Python/K semantics for pytest.
- The proof relies on the local contract of `_pytest._io.saferepr.saferepr` as a
  total safe representation helper with a maximum-size argument.
- Tests were not run by instruction.
