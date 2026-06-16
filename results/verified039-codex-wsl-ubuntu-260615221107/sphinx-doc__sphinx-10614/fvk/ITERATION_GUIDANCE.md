# FVK Iteration Guidance

Status: constructed, not machine-checked.

## Decision

V1 should not stand unchanged. Finding F-01 showed that the inheritance helper's
root-relative URL output was still passed through a Graphviz SVG post-processor
that used the current page's `imgpath` as a filesystem base. That fails the
asset-relative proof obligation for nested pages.

V2 keeps the V1 inheritance changes and adds a targeted Graphviz SVG
post-processing fix.

## Source Changes to Keep

Keep `repo/sphinx/ext/inheritance_diagram.py` changes from V1:

- `_render_target_uri()` discharges PO-01.
- `builder.get_target_uri()` for same-page `refid` discharges PO-02.
- PNG branches remain unchanged, satisfying PO-06.

Keep V2 changes in `repo/sphinx/ext/graphviz.py`:

- Use `builder.imagedir` instead of `builder.imgpath` for SVG href rewriting.
  This discharges PO-03 and PO-04.
- Use `posixpath` for URL-relative path calculation. This keeps URL separators
  stable and supports the Windows context in the issue.
- Skip scheme, network-location, and absolute-path URLs. This discharges PO-05.

## Follow-Up Tests When Allowed

Do not edit tests in this task. When test edits are allowed, add:

1. A nested-document `inheritance-diagram` build with
   `graphviz_output_format = "svg"`.
2. An assertion on the generated SVG href:
   `../my_package/my_class_1.html#my_package.MyClass1`.
3. A regression assertion that the bad form
   `../my_class_1.html#my_package.MyClass1` does not appear.
4. A generic nested Graphviz SVG rewrite test for a local relative target to
   ensure `builder.imagedir`, not `builder.imgpath`, is the rewrite base.

## Residual Risk

- The proof is constructed, not machine-checked.
- The source still only rewrites namespaced `xlink:href` attributes, matching the
  current code and tests. If future Graphviz versions emit plain `href`, that
  would require a separate compatibility audit.
- Generic Graphviz fragment-only links retain the existing output-root behavior.
  The reported issue is inheritance diagram class links, where V2 supplies the
  current document URI before SVG rewriting.

## Next Agent Prompt

If another iteration is requested, start from F-01 through F-06 and PO-01 through
PO-07. Do not regress to a fixed `"../"` prefix; prove any alternate change by
showing `Resolve(D / file.svg, final_href) = Resolve(C, refuri)` for nested and
root documents.
