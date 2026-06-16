# FVK Proof Obligations: mwaskom__seaborn-3187

Status: constructed from public intent and source inspection; not machine-checked.

## Obligations

### PO1: Helper appends non-empty offset text

For all label lists `L` and formatter offsets `O`, if `O != ""`, `_add_formatter_offset(L, formatter)` returns a list with the same length and order as `L`, where each element contains `O`.

Discharge status: discharged by inspection of `repo/seaborn/utils.py:714-719`.

Linked findings: F1.

### PO2: Helper preserves labels when offset is empty

For all label lists `L`, if `formatter.get_offset() == ""`, `_add_formatter_offset(L, formatter) == L`.

Discharge status: discharged by inspection of `repo/seaborn/utils.py:716-719`; the list comprehension is skipped.

Linked findings: F2.

### PO3: Relational brief numeric legends call the helper after formatter locs are set

`locator_to_legend_entries` must call `_add_formatter_offset` only after the formatter has received `raw_levels`, because formatter offset text depends on locs.

Discharge status: discharged by inspection of `repo/seaborn/utils.py:707-709`.

Linked findings: F1, F3.

### PO4: Objects continuous semantic legends call the helper after `format_ticks`

`ContinuousBase._setup` must call `_add_formatter_offset` after `axis.major.formatter.format_ticks(locs)`, because `format_ticks` sets formatter locs and computes offset state.

Discharge status: discharged by inspection of `repo/seaborn/_core/scales.py:382-383`.

Linked findings: F1, F3.

### PO5: Legend values and ordering are preserved

The patch must not change the semantic legend values, the order of legend entries, or the count of legend entries.

Discharge status: discharged by inspection. `locator_to_legend_entries` still returns the original `raw_levels`; `ContinuousBase._setup` still stores `list(locs)`; `_add_formatter_offset` maps labels one-for-one.

Linked findings: F2, F5.

### PO6: Label placement is adequate to public intent

Because the issue permits using the offset in legend title and/or labels, placing the offset in labels is sufficient.

Discharge status: discharged by public evidence E6 in `fvk/SPEC.md`.

Linked findings: F4.

### PO7: Public compatibility is preserved

The patch must not change public signatures or public return/storage shapes.

Discharge status: discharged by inspection. `_add_formatter_offset` is private; `locator_to_legend_entries` retains its three-argument signature and two-item return; `_legend` remains a two-item `(values, labels)` tuple.

Linked findings: F5.

## Expected Machine-Check Outcome

The constructed proof obligations reduce to a two-branch string/list transformation:

```text
O == ""  -> identity on labels
O != ""  -> one-to-one map that appends visible offset text
```

If encoded in a mini Python/K string-list model, the expected `kprove` outcome is `#Top` for the helper claims and for the two call-site composition claims, assuming the Matplotlib formatter offset is modeled as an already-computed string after locs have been set.
