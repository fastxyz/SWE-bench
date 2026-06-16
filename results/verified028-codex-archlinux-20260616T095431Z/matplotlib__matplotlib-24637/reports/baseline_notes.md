# Baseline Notes

## Root cause

`AnnotationBbox` is a composite artist: its `draw` method renders an optional
arrow patch, its frame patch, and the contained offset box. Those child artists
may each emit their own SVG elements, but `AnnotationBbox.draw` did not open a
renderer group for the parent artist itself. Because the SVG backend only uses
an artist's `gid` when the artist passes it to `renderer.open_group`, a `gid`
set directly on the `AnnotationBbox` was never attached to the SVG output that
represented the annotation as a whole.

## Changed files

`repo/lib/matplotlib/offsetbox.py`

Added `renderer.open_group('annotationbbox', gid=self.get_gid())` and the
matching `renderer.close_group('annotationbbox')` around the existing
`AnnotationBbox` child draw calls. The existing visibility and annotation
clipping checks remain before the group is opened, so skipped annotations do
not emit empty SVG groups. The draw order of the arrow, frame patch, and offset
box is unchanged.

`reports/baseline_notes.md`

Added this report to document the diagnosis, source edit, and assumptions.

## Assumptions and alternatives considered

I assumed the requested behavior is for the parent `AnnotationBbox` `gid` to
identify a single SVG group containing all of its rendered pieces. That matches
the issue hint and the existing pattern used by other composite artists such as
legends and tables.

I considered propagating the `AnnotationBbox` `gid` to one or more child
artists, such as the contained image or the frame patch. I rejected that because
it would either duplicate IDs or label only part of the annotation instead of
the annotation as a whole.

I also considered changing SVG backend image emission directly. I rejected that
because the missing `gid` is not image-specific; the parent artist never passed
its `gid` to the renderer, regardless of the type of offset box it contains.

No tests or executable project code were run, per the task instructions.
