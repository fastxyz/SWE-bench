# FINDINGS.md

Status: constructed, not machine-checked.  Findings are based on public intent
and static source inspection only.

## F-001: Y-axis offset text used tick color instead of explicit label color

- Classification: code bug in the pre-fix implementation.
- Evidence: problem reproduction sets `ytick.labelcolor` to `red` and expects
  the exponent/offset label to be red.
- Input/state: `rcParams["ytick.labelcolor"] = "red"` and
  `rcParams["ytick.color"] = "black"` or any distinct tick marker color.
- Pre-fix observed behavior: `YAxis._init()` assigned
  `color=mpl.rcParams["ytick.color"]` to `offsetText`.
- Expected behavior: `offsetText` color is `rcParams["ytick.labelcolor"]`
  because it is not `"inherit"`.
- V1 status: resolved.  `YAxis._init()` now uses
  `_get_tick_label_color("ytick")`, which returns the explicit label color in
  this case.
- Related proof obligations: PO-001, PO-004.

## F-002: X-axis offset text had the symmetric rcParam defect

- Classification: code bug in the pre-fix implementation.
- Evidence: the issue names both `xtick.labelcolor` and `ytick.labelcolor`,
  and the public hint proposes symmetric x/y changes.
- Input/state: `rcParams["xtick.labelcolor"] = "blue"` and
  `rcParams["xtick.color"] = "yellow"`.
- Pre-fix observed behavior: `XAxis._init()` assigned
  `color=mpl.rcParams["xtick.color"]` to `offsetText`.
- Expected behavior: `offsetText` color is `rcParams["xtick.labelcolor"]`
  because it is not `"inherit"`.
- V1 status: resolved.  `XAxis._init()` now uses
  `_get_tick_label_color("xtick")`.
- Related proof obligations: PO-001, PO-003.

## F-003: The default `"inherit"` behavior must remain backward compatible

- Classification: preservation obligation, not a bug in V1.
- Evidence: `matplotlibrc` and public docs define `*.labelcolor: inherit` as
  inheriting from `*.color`.
- Input/state: `rcParams["xtick.labelcolor"] = "inherit"` and
  `rcParams["xtick.color"] = "yellow"`; likewise for y.
- Expected behavior: offset text color is the corresponding tick color.
- V1 status: preserved.  `_get_tick_label_color()` returns `*.color` when
  `*.labelcolor == "inherit"`.
- Related proof obligations: PO-002, PO-003, PO-004.

## F-004: Tick labels and offset text must use the same rcParam resolver

- Classification: consistency obligation.
- Evidence: existing tick initialization already resolved `*.labelcolor`
  independently from tick marker color; the issue asks offset/exponent text to
  follow the same label-color behavior.
- Input/state: any valid x/y tick rcParams where `*.labelcolor` is either a
  real color or `"inherit"`.
- Expected behavior: default tick labels and offset text resolve to the same
  label color.
- V1 status: resolved.  `Tick.__init__`, `XAxis._init`, and `YAxis._init` all
  call `_get_tick_label_color()`.
- Related proof obligations: PO-001 through PO-005.

## F-005: No unresolved proof-derived code finding

- Classification: confirmation finding.
- Evidence: the proof obligations cover both axes, both resolver branches, and
  the frame/compatibility conditions for the V1 edit.
- V1 status: stands unchanged after FVK audit.  No additional source edit is
  justified by the public rcParam/style intent.
- Related proof obligations: PO-001 through PO-007.

## Test Guidance

No test files were modified.  If tests were allowed, focused coverage would add
offset-text assertions for:

- explicit `ytick.labelcolor` overriding `ytick.color`;
- explicit `xtick.labelcolor` overriding `xtick.color`;
- `"inherit"` falling back to the corresponding `*.color`.

Existing tests must remain until any formal proof is actually machine-checked
and the project maintainers choose to remove redundant coverage.
