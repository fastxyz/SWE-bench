# PROOF_OBLIGATIONS.md

Status: constructed, not machine-checked.  The commands listed here are for a
future environment with K installed; they were not run.

## Formal Core

- Semantics fragment: `fvk/mini-axis-color.k`
- Claim file: `fvk/axis-offset-color-spec.k`

Deferred machine-check commands:

```sh
kompile fvk/mini-axis-color.k --backend haskell
kast --backend haskell fvk/axis-offset-color-spec.k
kprove fvk/axis-offset-color-spec.k
```

Expected result in an environment with K installed: all claims discharge to
`#Top`.

## Obligations

### PO-001: Explicit label color branch

- Statement: for `T in {xtick, ytick}`, if
  `rcParams[T.labelcolor] != "inherit"`, `_get_tick_label_color(T)` returns
  `rcParams[T.labelcolor]`.
- Intent evidence: SPEC E1, E2, E5.
- Code evidence: `_get_tick_label_color()` reads `f"{tick_name}.labelcolor"`
  and returns it unless it equals `"inherit"`.
- Findings: F-001, F-002, F-004.
- Status: discharged by branch inspection.

### PO-002: Inherit fallback branch

- Statement: for `T in {xtick, ytick}`, if
  `rcParams[T.labelcolor] == "inherit"`, `_get_tick_label_color(T)` returns
  `rcParams[T.color]`.
- Intent evidence: SPEC E3, E4, E5.
- Code evidence: `_get_tick_label_color()` explicitly replaces `"inherit"`
  with `mpl.rcParams[f"{tick_name}.color"]`.
- Findings: F-003, F-004.
- Status: discharged by branch inspection.

### PO-003: X-axis offset text initialization

- Statement: `XAxis._init()` assigns `offsetText` color to
  `_get_tick_label_color("xtick")`.
- Intent evidence: SPEC E1, E2, E3.
- Code evidence: V1 changed the `self.offsetText.set(..., color=...)`
  argument in `XAxis._init()`.
- Findings: F-002, F-003, F-004.
- Status: discharged by direct call inspection.

### PO-004: Y-axis offset text initialization

- Statement: `YAxis._init()` assigns `offsetText` color to
  `_get_tick_label_color("ytick")`.
- Intent evidence: SPEC E1, E2, E3.
- Code evidence: V1 changed the `self.offsetText.set(..., color=...)`
  argument in `YAxis._init()`.
- Findings: F-001, F-003, F-004.
- Status: discharged by direct call inspection.

### PO-005: Tick label and offset text resolver consistency

- Statement: default tick labels and offset text resolve `*.labelcolor` using
  the same helper.
- Intent evidence: SPEC E5, E6, E8.
- Code evidence: `Tick.__init__` now uses `_get_tick_label_color(name)` when no
  explicit `labelcolor` is supplied; both axis `_init()` methods use the same
  helper.
- Findings: F-004.
- Status: discharged by shared helper inspection.

### PO-006: Frame conditions

- Statement: V1 does not change transforms, positions, font size, tick marker
  color, label visibility, formatter behavior, locator behavior, scales, or
  public method signatures.
- Intent evidence: SPEC intent item 4 and compatibility audit.
- Code evidence: diff changes only the color resolver and color arguments for
  `offsetText`; all other arguments in `self.offsetText.set(...)` remain
  unchanged.
- Findings: F-005.
- Status: discharged by diff inspection.

### PO-007: Public compatibility

- Statement: no public callsite, subclass override, or public API signature is
  made incompatible by V1.
- Intent evidence: FVK compatibility requirement.
- Code evidence: `_get_tick_label_color` is a private helper; no existing
  public method signature changed; no new virtual dispatch keyword was added.
- Findings: F-005.
- Status: discharged by static compatibility audit.

## Proof Coverage

Covered:

- x-axis and y-axis offset text initialization;
- explicit label-color branch;
- `"inherit"` fallback branch;
- default tick label consistency with offset text;
- source diff frame conditions.

Not covered:

- rendering backend pixel output;
- termination or performance, since there is no loop/recursion in the audited
  change;
- runtime behavior outside the rcParam/style initialization contract, except as
  supporting evidence where existing code already updates `offsetText` for
  non-reset `tick_params(labelcolor=...)`.
