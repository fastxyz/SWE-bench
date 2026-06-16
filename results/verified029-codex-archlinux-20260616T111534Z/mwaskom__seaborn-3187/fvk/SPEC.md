# FVK Spec: mwaskom__seaborn-3187

Status: constructed from public intent and source inspection; not machine-checked.

## Scope

This FVK pass audits the V1 source changes for large-number semantic legend labels:

- `repo/seaborn/utils.py`, `locator_to_legend_entries` and `_add_formatter_offset`.
- `repo/seaborn/_core/scales.py`, `ContinuousBase._setup` legend label construction.

No tests, Python, or K framework tools were run.

## Intent Spec

I1. A numeric legend whose labels are produced by a Matplotlib formatter with non-empty offset text must show that offset somewhere in the legend text visible to the user.

I2. The issue specifically names `ScalarFormatter` and large numeric ranges, including values around `1E6`.

I3. The fix must cover the objects API path shown in the issue and the classic relational path mentioned in the hint (`scatterplot` / `relplot`).

I4. Ordinary legends where the formatter reports no offset must remain unchanged.

I5. The fix should not alter semantic legend values, order, cardinality, artist mappings, public call signatures, or test files.

## Public Evidence Ledger

| ID | Source | Evidence | Obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt | "Wrong legend values of large ranges" | Legend text must not omit magnitude information for large ranges. | Encoded in C1, C3, C4. |
| E2 | prompt | "legends describing large numbers that were created using `ScalarFormatter` with an offset are formatted without their multiplicative offset value" | If formatter offset text is non-empty, the legend representation must include it. | Encoded in C1. |
| E3 | prompt | Objects example using `pointsize='body_mass_mg'` | Objects continuous semantic legends are in scope. | Encoded in C4. |
| E4 | prompt | "The issue also reproduces if you create the mentioned plot using `scatterplot`" | Classic relational brief numeric legends are in scope. | Encoded in C3. |
| E5 | prompt | "The offset value can be safely retrieved from all formatters" | It is valid to call `formatter.get_offset()` after locs are set. | Domain assumption A1. |
| E6 | prompt | "used to create the legend title and/or labels" | Attaching offset to labels is an acceptable output form. | Encoded in C1 and adequacy audit. |
| E7 | source | `locator_to_legend_entries` formats labels after `formatter.set_locs(raw_levels)`. | Offset must be added after locs are set and labels are formatted. | Encoded in C3. |
| E8 | source | `ContinuousBase._setup` stores `new._legend = list(locs), list(labels)`. | Objects legend labels must be offset-aware before storing `_legend`. | Encoded in C4. |

## Domain Assumptions

A1. The formatter object implements Matplotlib's formatter protocol and has `get_offset()`, returning an empty string when no offset is active and a non-empty string when offset text is active. This is public-intent-derived from E5 and matches the local use of Matplotlib `Formatter` subclasses.

A2. The offset must be visible in either legend title or legend labels. V1 chooses labels because both audited code paths already traffic in label lists and because classic legend handle labels expose semantic values as labels.

A3. The FVK model abstracts Matplotlib's internal decision about whether an offset is active. The proof obligation starts after formatter locs have been set and `get_offset()` has a defined result.

## Formal Model

Let:

- `labels = [l0, ..., ln]` be the formatter-produced legend labels.
- `offset = formatter.get_offset()`.
- `add(labels, offset)` be V1's `_add_formatter_offset`.
- `strip(x)` be Python string stripping applied by the helper.

Formal definition under audit:

```text
add(labels, offset) =
  labels                                      if offset == ""
  [strip(li + " " + offset) for li in labels] if offset != ""
```

## Claims

C1. `_add_formatter_offset` offset visibility:

For every list of string labels and every formatter offset string:

- If `offset == ""`, `add(labels, offset) == labels`.
- If `offset != ""`, every returned label contains `offset`.
- Length and order are preserved in both cases.

C2. `_add_formatter_offset` frame property:

The helper does not mutate formatter state, does not alter semantic values, and only constructs a returned labels list.

C3. `locator_to_legend_entries` relational legend contract:

For every locator, limits pair, and dtype in the existing function domain:

- The returned `raw_levels` are exactly the clipped locator levels from the pre-existing algorithm.
- The returned formatted labels are the pre-existing formatter labels passed through C1 after `formatter.set_locs(raw_levels)`.
- Therefore, if the formatter offset is non-empty, every relational brief numeric legend label contains the offset text.
- If the formatter offset is empty, labels remain byte-for-byte equal to V0 labels.

C4. `ContinuousBase._setup` objects legend contract:

For every continuous semantic scale setup where `prop.legend` is true:

- The legend values stored in `new._legend[0]` are exactly the pre-existing `locs`.
- The legend labels stored in `new._legend[1]` are `axis.major.formatter.format_ticks(locs)` passed through C1.
- Therefore, if the formatter offset is non-empty, every objects semantic legend label contains the offset text.
- If the formatter offset is empty, labels remain equal to V0 labels.

C5. Public compatibility contract:

The patch adds only a private helper and a private import, changes no public function signature, and preserves the tuple shapes returned/stored by the audited legend paths.

## Adequacy Audit

The formal claims match the public intent:

- I1 and I2 require non-empty formatter offset text to be visible. C1, C3, and C4 guarantee it in label text.
- I3 requires both objects and classic relational paths. C3 and C4 cover those paths.
- I4 requires no behavioral change without offset. C1, C3, and C4 explicitly preserve empty-offset labels.
- I5 requires no unrelated API or mapping changes. C2 and C5 cover frame and compatibility.

The only design choice not forced to a single representation is title versus label placement. E6 explicitly permits title and/or labels, so V1's label-based choice is adequate.
