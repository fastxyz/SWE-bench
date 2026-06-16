# FVK Proof Obligations

Status: constructed, not machine-checked. The obligations below are the claims
used to audit V1 and justify V2.

## PO-01: Page-Relative Xrefs Become Output-Root-Relative SVG Targets

Source findings: F-02.

Claim:

For any local relative resolved class `refuri` `R` on current output URI `C`,
`_render_target_uri(builder, R)` returns `Root(C, R)`, preserving query and
fragment.

Discharge:

- If `R` has a scheme, network location, or absolute path, the helper returns
  `R` unchanged. That is outside the local-relative class-link domain.
- If `R` has an empty path, the helper uses `C`; this covers fragment-only or
  query-only current-document references.
- Otherwise, it joins `R.path` against the directory part of `C` using POSIX URL
  path semantics and normalizes the result.

Example obligation:

`C = "my_package/index.html"` and
`R = "my_class_1.html#my_package.MyClass1"` imply
`Root(C, R) = "my_package/my_class_1.html#my_package.MyClass1"`.

Status: discharged by V2 source inspection.

## PO-02: Same-Document Xrefs Target the Current Builder URI

Source findings: F-02.

Claim:

For every same-document `refid` `A`, the SVG branch passes
`builder.get_target_uri(builder.current_docname) + "#" + A` into the SVG rewrite
pipeline.

Discharge:

This follows directly from `html_visit_inheritance_diagram()`. It also satisfies
the `dirhtml` builder shape because `get_target_uri()` may return `""` or
`"pkg/"`, whereas `current_docname + out_suffix` would not.

Status: discharged by V2 source inspection.

## PO-03: SVG Rewriting Uses the Actual SVG Directory

Source findings: F-01.

Claim:

For every local relative SVG href path `U`, `fix_svg_relative_paths()` rewrites
it to `posixpath.relpath(posixpath.normpath(path(U)), builder.imagedir)` and
restores query and fragment. The rewritten href resolves from a generated SVG in
`builder.imagedir` to the original output-root-relative target.

Discharge:

V2 uses `builder.imagedir`, not `builder.imgpath`. `builder.imagedir` is the
directory used by `render_dot()` when constructing `outfn`; `builder.imgpath` is
page-relative and changes with the current HTML document depth.

Example obligation:

`U = "my_package/my_class_1.html#my_package.MyClass1"` and `D = "_images"`
imply final href
`"../my_package/my_class_1.html#my_package.MyClass1"`.

Status: V1 failed; V2 discharged.

## PO-04: Composition Preserves Browser-Resolved Target

Source findings: F-01, F-02.

Claim:

For any in-domain local relative xref `R`, resolving the final SVG href from the
actual SVG file location reaches the same output document and fragment as
resolving `R` from the containing HTML page.

Algebra:

`Resolve(D / file.svg, SvgRel(Root(C, R))) = Resolve(C, R)`.

Discharge:

`Root(C, R)` is the output-root-relative target of `Resolve(C, R)`.
`SvgRel()` is a relative path from `D` to that same output-root-relative target.
Browser URL resolution of a relative path from `D / file.svg` therefore lands on
the target path by the definition of `relpath()`.

Status: discharged after PO-01 and PO-03.

## PO-05: Non-Relative SVG URLs Are Preserved

Source findings: F-03.

Claim:

SVG hrefs with a scheme, network location, or absolute path are not rewritten by
`fix_svg_relative_paths()`.

Discharge:

V2 checks `scheme or hostname or url.startswith('/')` before computing the
relative path.

Status: discharged by V2 source inspection.

## PO-06: PNG Frame Condition

Source findings: F-04.

Claim:

When `graphviz_output_format` is not SVG, inheritance diagram URLs remain the
resolved page-relative `refuri` or same-page `"#" + refid`.

Discharge:

The non-SVG branches in `html_visit_inheritance_diagram()` are unchanged from the
baseline behavior.

Status: discharged by diff inspection.

## PO-07: Public Compatibility

Source findings: F-04, F-05.

Claim:

No public directive signatures, node classes, builder methods, or extension setup
contracts change.

Discharge:

V2 edits only internal URL helper logic and SVG post-processing internals. No
function signature used by public callers is changed.

Status: discharged by diff inspection.

## Constructed K-Style Claim Sketch

This is a sketch of the machine-checkable shape that would be encoded in a
mini-URL K semantics. It is included here because K tooling cannot be run in this
task.

```k
// Claim PO-04, expressed over abstract URL functions.
claim
  <k> finalSvgHref(CURRENT, REFURI, IMAGEDIR)
      => relFrom(IMAGEDIR, rootResolve(CURRENT, REFURI)) ... </k>
  requires isLocalRelative(REFURI)
  ensures resolvesFrom(IMAGEDIR, relFrom(IMAGEDIR, rootResolve(CURRENT, REFURI)))
          ==K rootResolve(CURRENT, REFURI)
  [all-path]
```

Exact commands to machine-check a full K encoding later:

```sh
kompile fvk/mini-url-rewrite.k --backend haskell
kast --backend haskell fvk/inheritance-svg-spec.k
kprove fvk/inheritance-svg-spec.k
```

These commands were not run.
