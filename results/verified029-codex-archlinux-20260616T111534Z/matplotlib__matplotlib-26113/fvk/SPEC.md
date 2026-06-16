# FVK Spec

Status: constructed, not machine-checked. No tests, Python code, or K tooling
were executed.

## Scope

This FVK pass verifies the `Axes.hexbin` min-count selection behavior introduced
by V1. The model abstracts over already-computed bin memberships and reasons
about the selected-bin predicate for a finite list of per-bin point counts.

The full rendering pipeline is framed out: coordinate scaling, hex geometry,
`PolyCollection` construction, color normalization, `bins`, and marginal bars
are not reimplemented in the formal model. This is deliberate because the issue
and V1 patch concern the threshold predicate deciding which bins survive.

## Public Intent Ledger

See `PUBLIC_EVIDENCE_LEDGER.md` for the full ledger. The critical obligations
are:

- E1/E3: `mincnt` must not become stricter merely because `C` is supplied.
- E2/E4: explicit `mincnt` is inclusive: count exactly equal to `mincnt` is
  selected.
- E5: `C` mode with omitted `mincnt` keeps only non-empty bins to avoid reducing
  empty arrays by default.
- E6: count-only mode with omitted `mincnt` keeps every bin, including zero
  counts.
- E8: public signatures and `pyplot.hexbin` forwarding are preserved.

## Abstract State

For each finite real bin `b`, let:

- `count[b]` be the number of `(x, y)` samples assigned to that bin.
- `selected_count(M, b)` be the count-only selected predicate.
- `selected_C(M, b)` be the `C`-aggregation selected predicate before the
  existing final NaN filter.

The bin-assignment code is shared by both branches: both compute `i1`, `i2`, and
`bdist` before the `if C is None` split. The count-only branch counts those
assignments with `np.bincount`; the `C` branch appends exactly one `C[i]` to the
same bin selected for point `i`. Therefore, for each real bin, the length of the
`C` accumulator list equals `count[b]`.

## Formal Contract

For explicit positive `mincnt=M`:

```text
selected_count(M, b) == (count[b] >= M)
selected_C(M, b)     == (count[b] >= M)
```

For omitted `mincnt`:

```text
selected_count(None, b) == true
selected_C(None, b)     == (count[b] >= 1)
```

For explicit `mincnt=0` in `C` mode, the inclusive threshold predicate is
`count[b] >= 0`, but a bin is observable only if `reduce_C_function` is defined
on that bin's values and the final reduced value is not NaN. This edge case is
outside the documented positive-`mincnt` domain but is compatible with the
issue's requested `>=` comparator for reducers such as `np.sum`.

## K Artifacts

- `mini-hexbin.k` defines a minimal selection-loop semantics over a list of bin
  counts and a mode-specific effective threshold.
- `hexbin-mincnt-spec.k` contains the K claims:
  - `CLAIM-LOOP`: the selection loop appends `count >= threshold` for each bin.
  - `CLAIM-COUNT-EXPLICIT`: count-only explicit positive `mincnt` is inclusive.
  - `CLAIM-C-EXPLICIT`: `C` explicit positive `mincnt` is inclusive.
  - `CLAIM-C-DEFAULT`: `C` omitted `mincnt` uses threshold one.
  - `CLAIM-COUNT-DEFAULT`: count-only omitted `mincnt` uses threshold zero.

## Adequacy

`FORMAL_SPEC_ENGLISH.md` paraphrases each K claim. `SPEC_AUDIT.md` compares
those paraphrases to the public intent and marks all required positive-`mincnt`
behavior as pass. The only ambiguity is explicit `mincnt=0` in `C` mode, because
the issue mentions it but the public docstring says `int > 0`; V1 remains
compatible with reducers that handle empty input.
