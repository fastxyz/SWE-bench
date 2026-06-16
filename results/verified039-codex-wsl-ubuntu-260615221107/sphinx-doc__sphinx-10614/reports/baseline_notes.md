# Baseline Notes

## Root cause

`sphinx.ext.inheritance_diagram` resolves class cross-references into URIs that are
relative to the HTML page currently being written. That is correct for PNG output,
because the clickable image map is embedded in that page.

For SVG output, the generated SVG is embedded through an `<object>` tag and stored
under the builder image directory (`_images`). Links inside the SVG are resolved by
the browser relative to the SVG file itself, not relative to the HTML page that
contains the object. The existing SVG branch tried to account for this by adding a
fixed `"../"` prefix to the page-relative URI. That only works for pages at the
output root. For a page such as `my_package/index.html`, a resolved page-relative
link like `my_class_1.html#...` was converted to `../my_class_1.html#...`, which
points at the output root rather than `my_package/my_class_1.html`.

## Changed files

`repo/sphinx/ext/inheritance_diagram.py`

- Added `_render_target_uri()` to convert a current-page-relative URI into a URI
  relative to the HTML output root, preserving query strings and fragments.
- Changed the SVG `refuri` path handling to use that helper instead of prepending a
  fixed `"../"` prefix.
- Changed the SVG same-page `refid` handling to use `builder.get_target_uri()` for
  the current document instead of constructing the filename from `current_docname`
  and `out_suffix`. This keeps the target consistent with the builder's link
  format.
- Left PNG handling unchanged, because image-map links are still resolved relative
  to the containing HTML page.

`reports/baseline_notes.md`

- Added this required summary of the root cause, implementation, assumptions, and
  rejected alternatives.

## Assumptions and alternatives considered

I assumed that the existing Graphviz SVG post-processor should remain responsible
for converting output-root-relative SVG links into links relative to `_images`.
The inheritance diagram code now feeds that post-processor a root-relative output
URI instead of a partially image-relative URI.

I considered leaving `child['refuri']` unchanged for SVG output, but that would
still be page-relative and would fail for nested pages once the SVG file is loaded
from `_images`.

I also considered directly calculating final `_images`-relative URLs in the
inheritance diagram extension. I rejected that because `sphinx.ext.graphviz`
already rewrites relative links in generated SVG files, and bypassing or duplicating
that behavior would make inheritance diagrams inconsistent with normal Graphviz SVG
handling.
