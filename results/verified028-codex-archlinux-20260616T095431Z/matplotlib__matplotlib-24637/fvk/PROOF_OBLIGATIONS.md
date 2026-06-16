# Proof Obligations

Status: constructed, not machine-checked.

## PO-1: Parent gid reaches SVG output

For any visible, in-bounds `AnnotationBbox` with truthy gid `G`, normal
`draw(renderer)` must call `renderer.open_group('annotationbbox', gid=G)`.
For `RendererSVG`, that event must produce an SVG group element with `id=G`.

Evidence: E1, E2, E5.

Discharge status: satisfied by `repo/lib/matplotlib/offsetbox.py` lines
1455-1463 and `repo/lib/matplotlib/backends/backend_svg.py` lines 663-667.

## PO-2: The group encloses the entire annotation

The open group must occur before the annotation's child drawing, and the close
group must occur after all child drawing. The enclosed child set is: optional
arrow patch, frame patch, and contained offset box.

Evidence: E3, E4.

Discharge status: satisfied. V1 opens the group before `update_positions` and
all child draw calls, and closes it after `offsetbox.draw`.

## PO-3: Skipped annotations do not emit groups

If the annotation is not visible or `_check_xy(renderer)` rejects the annotated
point, `draw` must return without opening a renderer group or drawing children.

Evidence: E7 and pre-existing `AnnotationBbox.draw` behavior.

Discharge status: satisfied. V1 keeps the existing guard before `open_group`.

## PO-4: Existing child draw order is preserved

The fix must not reorder annotation rendering. The sequence remains:
`update_positions`, optional arrow patch draw, frame patch draw, contained
offset box draw, stale flag cleared.

Evidence: E4 and preservation intent for an SVG metadata fix.

Discharge status: satisfied. V1 inserts only the group boundary calls around
the existing sequence.

## PO-5: Renderer API compatibility is preserved

The fix must use existing renderer API methods without changing public method
signatures, subclass protocols, or child artist draw signatures.

Evidence: E6.

Discharge status: satisfied. `RendererBase` already defines `open_group` and
`close_group`; no signatures or dispatch arguments changed.

## PO-6: No duplicate child IDs are introduced

The parent `AnnotationBbox` gid must identify the parent group. The fix must not
copy the same gid to the frame patch, arrow patch, contained `OffsetImage`, or
underlying `BboxImage`, because duplicate SVG IDs would be invalid and would not
identify the annotation as a whole.

Evidence: E3 and SVG uniqueness expectations.

Discharge status: satisfied. V1 passes the gid only to the parent renderer group.

## PO-7: Normal-path group balance

On all normal-return visible/in-bounds paths, every annotationbbox open-group
event must have a matching close-group event after child drawing.

Evidence: E3 and renderer grouping API shape.

Discharge status: satisfied for normal returns. Exception-path balance is not
proved and is listed as residual risk F-003.
