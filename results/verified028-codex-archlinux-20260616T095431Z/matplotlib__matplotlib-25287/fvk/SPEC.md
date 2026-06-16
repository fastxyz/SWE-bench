# SPEC.md

Status: constructed, not machine-checked.  No tests, Python, `kompile`, or
`kprove` were run.

## Scope

The audited production change is `repo/lib/matplotlib/axis.py`, limited to the
rcParam-driven default color used for tick labels and axis `offsetText` during
axis initialization/reset.  The target observable is the color assigned to the
scientific-notation offset/exponent text for both x and y axes.

The formal core for later machine checking is in:

- `fvk/mini-axis-color.k`
- `fvk/axis-offset-color-spec.k`

## Intent-Only Specification

For each axis family `T` in `{xtick, ytick}`:

1. If `rcParams[T.labelcolor] != "inherit"`, then tick labels and offset text
   must use `rcParams[T.labelcolor]`.
2. If `rcParams[T.labelcolor] == "inherit"`, then tick labels and offset text
   must use `rcParams[T.color]`.
3. `xtick.color` / `ytick.color` remain the tick marker colors; setting
   `xtick.labelcolor` / `ytick.labelcolor` independently must not force offset
   text back to the tick marker color.
4. The change must not alter public method signatures, transforms, positions,
   font sizes, tick marker colors, or test files.

## Public Evidence Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt | "offsetText is colored based on tick.color instead of tick.labelcolor" | The bug is the offset text using `*.color` when an explicit `*.labelcolor` exists. | Encoded in claims `OFFSET-INIT` and findings F-001/F-002. |
| E2 | prompt | "when setting ytick.labelcolor / xtick.labelcolor in styles / rcParams, it does not change the color of the exponent label as well" | rcParam and style initialization are in-domain; exponent/offset label must follow the tick label rcParam. | Encoded for both `xtick` and `ytick`. |
| E3 | prompt patch | Suggested expression uses `*.color` only when `*.labelcolor == "inherit"`. | `"inherit"` is a branch, not the unconditional behavior. | Encoded in resolver claims PO-001 and PO-002. |
| E4 | `matplotlibrc` comments | `xtick.labelcolor: inherit` means "inherit from xtick.color"; same for y. | The fallback branch must preserve existing default behavior. | Encoded in PO-002. |
| E5 | 3.4 public docs | Tick label color can be set independently and defaults to `"inherit"`. | Explicit label color overrides tick color; default remains backward compatible. | Encoded in PO-001/PO-002 and frame conditions. |
| E6 | public in-repo tests | Existing tests assert tick labels can differ from tick marker color. | Tick label color separation is already a public behavior; offset text should align with that label behavior. | Supporting evidence, not sufficient alone. |
| E7 | implementation | `Axis.clear()` calls subclass `_init()`, and `_init()` sets `offsetText` visual properties. | The defect localizes to `XAxis._init` / `YAxis._init` default color assignment. | Checked by proof obligations PO-003/PO-004. |
| E8 | implementation | `Axis.set_tick_params()` already applies runtime `labelcolor` to `offsetText` in the non-reset path. | The rcParam initialization path should be consistent with runtime labelcolor behavior. | Supporting evidence for V1; no additional source edit required. |

## Formal Specification

Let `Resolve(RC, T)` be the intended rcParam resolver:

```text
Resolve(RC, T) =
    RC[T.color]       if RC[T.labelcolor] == "inherit"
    RC[T.labelcolor]  otherwise
```

The formal K claims in `axis-offset-color-spec.k` encode:

- `RESOLVE-EXPLICIT`: for `T in {xtick, ytick}`, if
  `RC[T.labelcolor] != "inherit"`, `resolveColor(T)` reaches
  `RC[T.labelcolor]`.
- `RESOLVE-INHERIT`: for `T in {xtick, ytick}`, if
  `RC[T.labelcolor] == "inherit"`, `resolveColor(T)` reaches `RC[T.color]`.
- `OFFSET-INIT`: `initOffset(T)` stores `Resolve(RC, T)` as the offset text
  color for both axis families.
- `TICK-LABEL-INIT`: default tick labels store the same `Resolve(RC, T)`,
  keeping offset text and tick labels consistent.

## Adequacy Audit

The formal English above matches the intent-only obligations:

- Explicit `*.labelcolor` wins over `*.color`: pass, from E1/E2/E5.
- `"inherit"` falls back to `*.color`: pass, from E3/E4/E5.
- Applies to both x and y axes: pass, from E2 and the symmetric rcParams.
- Frame conditions: pass, because V1 changes only the color argument and adds a
  private helper; no public signature or test file is changed.

No required behavior is marked fail or ambiguous.

## Compatibility Audit

- Public API signatures: unchanged.
- Public class hierarchy: unchanged.
- New symbol: `_get_tick_label_color` is private module helper only.
- Public callsites/subclass overrides: no new dispatch argument or override
  requirement is introduced.
- Test files: unchanged, per task constraint.
