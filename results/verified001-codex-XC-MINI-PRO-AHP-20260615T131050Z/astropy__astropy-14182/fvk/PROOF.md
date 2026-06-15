# Constructed Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`,
Python, or tests were run.

## Claims Proved in This Pass

The constructed proof covers the obligations in
`fvk/PROOF_OBLIGATIONS.md`:

- O1: `RST.__init__` accepts and forwards `header_rows`.
- O2: requested header-row values and order come from the fixed-width writer.
- O3: the RST separator is selected after all configured header rows.
- O4: default one-header-row RST output is preserved.
- O5: matching multi-header RST readback uses `data.start_line = K + 2`.
- O6: the optional constructor keyword is public-API compatible.
- O7: no-header and empty-table cases are outside the verified domain.

## Proof Sketch

Let `H = normalize(header_rows)`, where `normalize(None) = ["name"]`, and let
`K = len(H)`. The verified domain requires `K >= 1`.

`RST.__init__` calls `FixedWidth.__init__` with `header_rows=header_rows`.
`FixedWidth.__init__` normalizes `None` to `["name"]` and stores the configured
sequence on both `self.header.header_rows` and `self.data.header_rows`. Therefore
the writer constructed by `core._get_writer` no longer rejects the issue input
with an unexpected-keyword `TypeError`, proving O1.

`FixedWidthData.write` iterates through `self.data.header_rows` in order. For
each header attribute, it reads `getattr(col.info, col_attr)` for every column,
converts missing values to empty strings, and appends the joined row. This is the
same value source used by `ascii.fixed_width`, proving O2 for RST because RST
delegates formatting to the fixed-width base class before adding RST separators.

For `K` header rows, the inherited line list has the abstract shape:

```text
lines = HeaderLines(H) ++ [Sep] ++ DataLines
```

`FixedWidthData.write` creates this shape because it appends all header rows
first and then appends the position line when `self.header.position_line` is not
`None`. In RST, that position line is the separator made from `"="` characters.
Thus `lines[K] == Sep`. V1 computes `separator = lines[len(self.header.header_rows)]`,
then returns:

```text
[Sep] ++ HeaderLines(H) ++ [Sep] ++ DataLines ++ [Sep]
```

This is exactly the RST simple-table shape required by O3.

For the default call, `header_rows is None`, so `H = ["name"]` and `K = 1`.
V1 selects `lines[1]`, which is the same separator index used by the previous
implementation. Therefore the default output shape is unchanged, proving O4.

For matching readback with `K` configured header rows, the first data row follows
one top separator, `K` header rows, and one middle separator. The data start is
therefore `1 + K + 1 = K + 2`. V1 sets that value in the constructor, proving
O5 for the modeled readback line-index obligation.

Static compatibility inspection found no in-repo subclass overriding RST
construction or write dispatch. Existing zero-argument construction remains
valid because the new parameter has a default. The public writer dispatch
already routes writer-specific kwargs to constructors, proving O6.

## Adequacy Check

The English meaning of the constructed claims matches the public issue:

- The proof removes the exact reported `TypeError`.
- It produces the requested additional unit header row using the same fixed-width
  machinery that the issue used as the comparison point.
- It preserves the existing default RST shape.
- It does not claim unrequested behavior for no-header or empty-table cases.

No adequacy mismatch was found that would block `V2 == V1`.

## Commands Not Run

The FVK documents call for K commands. This benchmark forbids K execution, so
the commands below are recorded only as the expected machine-check step for a
future environment where the K-style claims in `fvk/SPEC.md` are materialized as
standalone `.k` files:

```sh
kompile fvk/mini-rst-writer.k --backend haskell
kast --backend haskell fvk/rst-header-rows-spec.k
kprove fvk/rst-header-rows-spec.k
```

Expected outcome after materializing the claims faithfully: `kprove` returns
`#Top` for O1 through O6 under the O7 domain boundary.

## Test Recommendation

No tests were edited. If this proof were machine-checked, unit tests that only
assert the in-domain issue behavior for `header_rows=["name", "unit"]` would be
subsumed by O1 through O3. Existing default RST output tests should still be kept
unless and until O4 is machine-checked in an executable K model. Boundary tests
for no-header rows, empty tables, continuation lines, column spans, and full I/O
integration are not subsumed by this proof.

