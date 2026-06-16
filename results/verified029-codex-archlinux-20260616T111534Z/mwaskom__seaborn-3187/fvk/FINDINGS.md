# FVK Findings: mwaskom__seaborn-3187

Status: constructed from public intent and source inspection; not machine-checked.

## Findings

### F1: Root code bug in V0, fixed by V1

Classification: code bug, fixed.

Input class:

```text
labels = ["2", "3", "4"]
formatter.get_offset() = "1e6"
```

Observed in V0:

```text
["2", "3", "4"]
```

Expected from public intent:

Legend text must include the formatter offset because the represented values are in the order of `1E6`.

Observed in V1 by source inspection:

```text
["2 1e6", "3 1e6", "4 1e6"]
```

Evidence: `repo/seaborn/utils.py:707-709`, `repo/seaborn/_core/scales.py:382-383`.

Linked proof obligations: PO1, PO3, PO4.

### F2: Empty-offset frame condition holds

Classification: frame condition, confirmed.

Input class:

```text
labels = ["0.20", "0.22"]
formatter.get_offset() = ""
```

Observed in V1 by source inspection:

```text
["0.20", "0.22"]
```

Expected from public intent:

Ordinary legends should not change when no formatter offset is active.

Evidence: `_add_formatter_offset` returns the input labels unless `offset` is truthy (`repo/seaborn/utils.py:714-719`).

Linked proof obligations: PO2, PO5.

### F3: Both named legend construction paths are covered

Classification: completeness against public issue scope, confirmed.

Input classes:

- Objects API continuous semantic legend (`so.Plot(..., pointsize="body_mass_mg").add(so.Dot())`).
- Classic relational brief numeric legend (`scatterplot` / `relplot` with numeric hue or size requiring brief legend ticks).

Observed in V1 by source inspection:

- Objects labels are passed through `_add_formatter_offset` after `format_ticks`.
- Relational labels are passed through `_add_formatter_offset` after `set_locs` and per-level formatting.

Expected from public intent:

Both code paths must include non-empty formatter offset text.

Evidence: problem statement and public hint; `repo/seaborn/_core/scales.py:378-384`; `repo/seaborn/utils.py:687-711`.

Linked proof obligations: PO3, PO4, PO5.

### F4: Title-only alternative is not required

Classification: underspecified representation, resolved by public allowance.

Alternative considered:

Put the offset only in the legend title/subtitle while leaving labels unchanged.

Reason rejected:

The public issue permits "legend title and/or labels." Labels are a valid placement. A label-based fix covers both legend systems without changing title/subtitle grouping logic, and it makes labels self-contained for classic legend APIs that expose semantic values as label text.

Linked proof obligations: PO6.

### F5: No public compatibility problem found

Classification: compatibility audit, confirmed.

Observed in V1 by source inspection:

The patch adds private helper `_add_formatter_offset`, changes no public function signatures, keeps `locator_to_legend_entries` returning `(raw_levels, formatted_levels)`, and keeps `new._legend` as `(values, labels)`.

Expected from public intent:

The bug fix should not alter public API shape or semantic mapping behavior.

Linked proof obligations: PO5, PO7.

### F6: Verification remains constructed, not machine-checked

Classification: proof capability limitation, not a code bug.

Observed:

No Python tests, imports, `kompile`, or `kprove` were run, per task instructions.

Expected:

The FVK artifacts should state constructed proof obligations and reason about expected outcomes without claiming machine-checked proof.

Linked proof obligations: all.

## Code Revision Decision

No new source edits are justified by these findings. V1 stands unchanged.
