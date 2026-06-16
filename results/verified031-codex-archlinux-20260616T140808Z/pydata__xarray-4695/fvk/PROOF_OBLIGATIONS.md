# Proof Obligations

Status: constructed, not machine-checked.

## PO-1 - Dimension Names Are Data

For every in-domain label-indexer mapping `M`, keys of `M` are dimension,
coordinate, or level names. A key equal to `method`, `tolerance`, or `drop`
must remain a key in `M` during dynamic selection dispatch.

Findings: `FVK-F1`, `FVK-F2`.

## PO-2 - Explicit `.loc` Mapping Dispatch

When `DataArray._LocIndexer.__getitem__` receives a dict-like key `M`, it must
call `.sel(M)` or an equivalent positional-indexers form, not `.sel(**M)`.

Findings: `FVK-F1`.

## PO-3 - Expanded `.loc` Key Dispatch

When `DataArray._LocIndexer.__getitem__` receives a non-dict key, it may expand
the key with `expanded_indexer` and `dict(zip(self.data_array.dims, labels))`;
after expansion, the resulting mapping must satisfy `PO-2`.

Findings: `FVK-F1`.

## PO-4 - Dynamic Single-Indexer Helper Dispatch

Any audited internal helper that constructs `{dim: value}` specifically to
select along a dynamic dimension must pass that mapping positionally to `.sel`.
It must not use keyword expansion.

Findings: `FVK-F2`.

## PO-5 - Exact Selection Options Are Framed

The `.loc` and dynamic-helper dispatch paths must not set `.sel(method=...)`,
`.sel(tolerance=...)`, or `.sel(drop=...)` from dimension names. Reserved `.sel`
parameters retain their defaults unless the public `.sel` API is called with
those parameters explicitly.

Findings: `FVK-F1`, `FVK-F2`, `FVK-F3`.

## PO-6 - Public Compatibility

The fix must not change public signatures or require downstream `.sel`
implementations to accept new keywords. Existing mapping-form `.sel(indexers)`
compatibility is sufficient.

Findings: `FVK-F2`, `FVK-F3`.

## PO-7 - Legacy Counterexample Is Removed

For the concrete public reproducer mapping `{"dim1": "x", "method": "a"}`, the
pre-fix path reaches an invalid-fill-method state by keyword binding. The fixed
path reaches downstream selection dispatch with the same mapping and exact
method state.

Findings: `FVK-F1`.

## PO-8 - Honesty Boundary

The proof and artifacts are constructed but not machine-checked. No source
decision may rely on hidden tests, benchmark verdicts, executed Python, executed
test results, or executed K tooling.

Findings: `FVK-F4`.
