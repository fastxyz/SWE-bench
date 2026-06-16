// Constructed, not machine-checked.
// Abstract claims for the inheritance SVG URL rewrite proof.

requires "mini-url-rewrite.k"

module INHERITANCE-SVG-SPEC
  imports MINI-URL-REWRITE
  imports K-EQUAL

  // SPEC-PROVENANCE:
  // - from_prompt: nested SVG inheritance diagram links must not resolve to 404
  // - from_prompt: SVG hrefs are relative to the SVG object file
  // - from_code: render_dot writes SVG files under builder.imagedir
  // - from_code: make_refnode gives page-relative refuri values
  claim
    <k> finalSvgHref(CURRENT:String, REFURI:String, IMAGEDIR:String)
        => relFrom(IMAGEDIR, rootResolve(CURRENT, REFURI)) ... </k>
    requires isLocalRelative(REFURI)
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: final SVG href must reach the same document as the class xref
  // - from_code: fix_svg_relative_paths rewrites local relative hrefs
  claim
    <k> resolvesFrom(IMAGEDIR:String,
                     relFrom(IMAGEDIR, rootResolve(CURRENT:String, REFURI:String)))
        => rootResolve(CURRENT, REFURI) ... </k>
    requires isLocalRelative(REFURI)
    [all-path]
endmodule
