# FVK Proof: mwaskom__seaborn-3187

Status: constructed, not machine-checked. No tests, Python, `kompile`, or `kprove` were run.

## Summary

The V1 patch is correct against the intent in `fvk/SPEC.md`: when a formatter reports non-empty offset text, both audited legend paths include it in legend labels; when no offset is active, labels and semantic values are unchanged.

## Proof Sketch

### Lemma L1: `_add_formatter_offset` with empty offset is identity

Given any label list `L` and formatter `F` where `F.get_offset() == ""`:

1. The helper binds `offset = formatter.get_offset()`.
2. The condition `if offset:` is false.
3. The helper returns `labels` without entering the list comprehension.

Therefore the output is exactly `L`. This discharges PO2.

### Lemma L2: `_add_formatter_offset` with non-empty offset preserves order and exposes offset

Given any label list `L = [l0, ..., ln]` and formatter `F` where `F.get_offset() == O` and `O != ""`:

1. The helper binds `offset = O`.
2. The condition `if offset:` is true.
3. The helper constructs `[f"{label} {offset}".strip() for label in labels]`.
4. Python list comprehension over `labels` is order preserving and emits exactly one output per input.
5. For every input label `li`, the constructed text includes `O`; `.strip()` can remove only surrounding whitespace, not the non-empty offset substring.

Therefore the output has the same length and order as `L`, and every label contains `O`. This discharges PO1.

### Theorem T1: Relational brief numeric legends include offset text

In `locator_to_legend_entries`:

1. `raw_levels` are computed and clipped before V1 code runs.
2. The formatter is selected exactly as before V1.
3. The formatter receives `raw_levels` with `formatter.set_locs(raw_levels)`.
4. Labels are formatted exactly as before V1.
5. V1 applies `_add_formatter_offset(formatted_levels, formatter)`.

By L1, if the formatter offset is empty, labels are unchanged. By L2, if the formatter offset is non-empty, every returned label contains that offset. `raw_levels` are not passed to the helper and remain unchanged.

This discharges PO3 and the relational part of PO5.

### Theorem T2: Objects continuous semantic legends include offset text

In `ContinuousBase._setup` when `prop.legend` is true:

1. `locs` are computed and clipped as before V1.
2. `labels = axis.major.formatter.format_ticks(locs)` is computed as before V1.
3. V1 applies `_add_formatter_offset(labels, axis.major.formatter)`.
4. `new._legend = list(locs), list(labels)` keeps the existing tuple shape.

By L1, empty-offset labels are unchanged. By L2, non-empty offset text is included in every label. `locs` are not changed by the helper.

This discharges PO4 and the objects part of PO5.

### Theorem T3: Public compatibility is preserved

The only new callable is `_add_formatter_offset`, a private utility. Existing audited callers retain their signatures and output shapes:

- `locator_to_legend_entries(locator, limits, dtype) -> (raw_levels, formatted_levels)`.
- `ContinuousBase._setup(...)._legend -> (values, labels)` when legend data exists.

No public API, public class contract, or test file is changed. This discharges PO7.

## Adequacy

The proof covers the full public issue scope named in `benchmark/PROBLEM.md`:

- Objects path: `so.Plot(..., pointsize="body_mass_mg").add(so.Dot())`.
- Classic relational path: `scatterplot` and the public hint's `relplot` path through brief numeric legends.
- Formatter-offset behavior: non-empty offset text is visible; empty offset text preserves ordinary labels.

The title-only alternative is not required because the issue explicitly allows title and/or label placement. This discharges PO6.

## Commands Not Run

The task forbids K tooling. If this proof were split into standalone K files, the intended commands would be recorded as:

```sh
kompile fvk/mini-legend-format.k --backend haskell
kast --backend haskell fvk/legend-format-spec.k
kprove fvk/legend-format-spec.k
```

Expected outcome after such an encoding: `#Top` for the helper identity/non-empty-offset claims and the two call-site composition claims, under the domain assumption that formatter offset text is an already-computed string after locs are set.

## Test Guidance

No tests were edited or run. Existing tests that assert ordinary no-offset legend labels should continue to be kept unless a future machine-checked proof and project policy justify removal. New targeted tests would be useful for:

- Objects semantic legend labels with a `ScalarFormatter` offset.
- Relational brief hue/size legend labels with a `ScalarFormatter` offset.
- Empty-offset legends remaining unchanged.
