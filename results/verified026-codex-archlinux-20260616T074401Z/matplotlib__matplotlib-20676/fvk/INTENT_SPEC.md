# Intent Spec

Status: constructed from public/local evidence only.

## Required behavior

I1. Constructing `SpanSelector(ax, callback, "horizontal", interactive=True)`
must not force the x-axis limits to include `0` before any user interaction.

I2. For an axes whose plotted x data is `[10, 20]`, the limits after
constructing the horizontal interactive selector should remain the plotted
data limits plus normal margins, not expand to include `0`.

I3. The obligation is on construction, not on selection or dragging. The issue
clarifies that the limit change occurs when calling the constructor.

I4. The selector's internal rectangle and edge handles are UI helper artists.
They must remain drawable, removable, visible/hidden by the widget, and usable
for hit testing, but their initial coordinate `0` is not plotted user data.

I5. The same frame principle applies to `direction="vertical"` by API symmetry:
the selected data axis must not be polluted by the selector helper coordinate
at construction.

I6. No public API signature or test files should change. The fix target is
production widget code.

## Out of scope

Termination and runtime performance are not at issue. Rendering fidelity beyond
preserving the existing patch/handle geometry is not separately specified by
the issue.
