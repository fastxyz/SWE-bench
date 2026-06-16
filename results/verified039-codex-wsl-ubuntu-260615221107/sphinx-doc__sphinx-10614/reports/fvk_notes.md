# FVK Notes

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Decisions and Traceability

1. Kept the V1 `_render_target_uri()` helper in
   `repo/sphinx/ext/inheritance_diagram.py`.

   Trace: F-02 and PO-01. The issue requires nested-page `refuri` values such as
   `my_class_1.html#...` to become output-root-relative targets such as
   `my_package/my_class_1.html#...` before SVG rewriting.

2. Kept the V1 use of `builder.get_target_uri()` for same-document `refid`
   targets.

   Trace: PO-02. This is more faithful than `current_docname + out_suffix`
   because HTML builders can define directory-style or custom target URIs.

3. Added the V2 edit in `repo/sphinx/ext/graphviz.py` to use
   `builder.imagedir` as the SVG rewrite base.

   Trace: F-01, PO-03, and PO-04. The V1 audit found that `builder.imgpath` is
   relative to the current HTML page. On nested pages it can be `"../_images"`,
   but the generated SVG file is actually under `outdir/_images`. Rewriting from
   `builder.imagedir` aligns the calculation with the asset's real URL base.

4. Added the V2 edit in `repo/sphinx/ext/graphviz.py` to use `posixpath` URL
   path operations and preserve trailing slashes.

   Trace: PO-03 and PO-04. SVG hrefs are URL paths, not platform filesystem
   paths. This matters for the Windows context in the issue and for stable hrefs
   in generated SVG files.

5. Added the V2 guard that leaves scheme, network-location, and absolute-path
   SVG hrefs unchanged.

   Trace: F-03 and PO-05. `fix_svg_relative_paths()` is only justified for local
   relative links. Rewriting non-relative URLs would exceed the function's stated
   purpose and can corrupt valid external or absolute links.

6. Left PNG handling unchanged.

   Trace: F-04 and PO-06. The public issue says PNG/default mode does not show
   the bug, and PNG image-map links are embedded directly in the containing HTML
   page.

7. Did not edit any tests.

   Trace: F-05 and the task's explicit restriction. The FVK guidance recommends
   nested SVG inheritance regression coverage when test edits are allowed, but
   this benchmark requires production-source changes only.

8. Did not claim machine-checked proof or test redundancy.

   Trace: F-06. The task forbids running K tooling and tests, so the proof is a
   constructed audit. Existing tests should be kept.

## Summary

The FVK audit found that V1 fixed the inheritance URL source but not the full SVG
href pipeline. V2 adds the missing Graphviz post-processing correction, so the
composition now satisfies the core obligation:

```text
Resolve(_images/file.svg, final_svg_href) = Resolve(current_html_page, refuri)
```
