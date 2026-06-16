# Public Compatibility Audit

Status: constructed from local source inspection only.

## Changed symbols

`SpanSelector.new_axes`

- Signature changed: no.
- Public callsites affected: no direct public signature change; `SpanSelector`
  continues to call `new_axes(ax)` internally.
- Behavior intentionally changed: the internal rectangle remains in
  `Axes._children` and `Axes.patches`, but is attached without automatic
  data-limit updates.
- Compatibility status: pass.

`ToolLineHandles.__init__`

- Signature changed: no.
- Public callsites found in source: `SpanSelector._setup_edge_handle`; public
  tests instantiate `ToolLineHandles(ax, positions, "horizontal", useblit=False)`.
- Behavior preserved: it still creates one `Line2D` per position; visibility,
  animation state, `positions`, `set_data`, `set_visible`, `set_animated`, and
  `remove` keep the same observable contract.
- Behavior intentionally changed: helper lines are attached without automatic
  data-limit updates or autoscale requests.
- Compatibility status: pass.

## Overrides and virtual dispatch

No method signature was changed and no new virtual method call or keyword
argument was introduced. No subclass override compatibility issue was found in
the local source.

## Residual compatibility risk

`ToolLineHandles` is public enough to appear in tests, but its purpose is a
canvas-control helper. The public issue and helper name support treating its
artists as UI controls rather than plotted data. No source evidence requires
standalone `ToolLineHandles` construction to autoscale an axes.
