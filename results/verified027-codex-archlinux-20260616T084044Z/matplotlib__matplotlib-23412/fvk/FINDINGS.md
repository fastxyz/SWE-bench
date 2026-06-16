# FINDINGS

Status: constructed for FVK audit; not machine-checked.

## F-001: Legacy `Patch.draw()` zeroed in-domain dash offsets

Classification: code bug, resolved by V1.

Evidence: E1-E7 and PO-4.

Concrete input:

- visible `Rectangle`
- `linewidth = 4`
- `linestyle = (10, (10, 10))`
- dash cycle `C = 20`
- `lines.scale_dashes = true`

Observed pre-fix behavior:

- `set_linestyle` and `set_linewidth` store effective offset `40`
- `Patch.draw()` temporarily replaces `_dash_pattern` with `(0, dash_list)`
- `gc.set_dashes` receives offset `0`

Expected behavior:

- `gc.set_dashes` receives offset `40`
- the offset can phase-shift the patch edge relative to an otherwise identical
  patch with offset `0`

V1 status:

- Resolved. `Patch.draw()` now enters `_bind_draw_path_function()` directly, so
  `_bind_draw_path_function()` passes the stored `_dash_pattern` to
  `gc.set_dashes`.

## F-002: V1 satisfies the audited formal obligations

Classification: confirmation of candidate fix.

Evidence: PO-2 through PO-5.

The setter/scaling path already preserved tuple offsets. The only proof
obstacle was draw-time replacement of the stored offset with `0`. V1 removes
that replacement and therefore discharges the constructor-order, post-init, and
non-zero forwarding claims.

Recommended code action:

- Keep V1 unchanged.

## F-003: Behavior changes for callers relying on ignored non-zero offsets

Classification: compatibility note, not a blocker.

Evidence: E7 and PO-6.

Concrete input:

- any patch with `linestyle=(nonzero_offset, valid_onoffseq)`

Observed pre-fix behavior:

- the non-zero offset was ignored during base `Patch.draw()`

Expected behavior:

- the non-zero offset is honored

V1 status:

- This is an intentional behavior correction. The public issue discussion
  rejects preserving code that explicitly set an offset but relied on it not
  being applied.

Recommended code action:

- No warning or compatibility shim.

## F-004: Test and release-note work is outside this benchmark edit

Classification: test/documentation gap, not a source-code bug.

Evidence: public hint mentions tests and a release note; benchmark instructions
forbid modifying tests and require source-code repair plus reports.

Recommended future work:

- Add a public test that a patch with `linestyle=(10, (10, 10))` forwards a
  different dash offset than `linestyle=(0, (10, 10))`, preferably covering a
  rectangle and an ellipse.
- Add a user-facing release note if following the full project contribution
  workflow.

V1 status:

- No source change required by this finding.

## F-005: Backend pixel rendering is a residual trusted component

Classification: proof boundary, not a discovered code bug.

Evidence: PO-2 and `SPEC_AUDIT.md`.

The FVK model proves that the correct offset reaches `gc.set_dashes`. It does
not prove that every backend rasterizes dashed patch paths identically to
`Line2D` at the pixel level.

Recommended future work:

- Keep image/backend integration tests.
- Machine-check the K claims before treating unit tests as redundant.

V1 status:

- This boundary does not justify additional source changes because the public
  issue and source evidence localize the defect to the offset being overwritten
  before the graphics context call.
