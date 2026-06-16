# FVK Spec: SVG Inheritance Diagram Links

Status: constructed, not machine-checked. No tests, Python, or K tooling were run.

## Scope

The audit covers the observable URL behavior created by these functions:

- `sphinx.ext.inheritance_diagram.html_visit_inheritance_diagram`
- `sphinx.ext.inheritance_diagram._render_target_uri`
- `sphinx.ext.graphviz.fix_svg_relative_paths`
- `sphinx.ext.graphviz.render_dot_html`, only as the caller that embeds SVGs from
  the builder image directory.

## Public Intent Ledger

I1. Source: `benchmark/PROBLEM.md`

Evidence: "If the inheritance diagram is created in a file that is not in the
root directory, the links lead to a 404 page."

Obligation: SVG inheritance diagram class links must resolve to the same target
document and fragment regardless of whether the containing HTML page is at the
output root or in a subdirectory.

I2. Source: `benchmark/PROBLEM.md`

Evidence: "the links in the SVG file are relative to the SVG file (because it is
embedded using the object tag) however the rest of the link is written as if it
was relative to the file the SVG is embedded on."

Obligation: The final href stored inside the SVG must be relative to the SVG
asset location in the output image directory, not relative to the containing HTML
page.

I3. Source: `benchmark/PROBLEM.md`

Evidence: "This issue does not happen in the default (png?) mode."

Obligation: PNG image-map output must keep using page-relative `refuri` values
and same-page `#refid` links.

I4. Source: `repo/sphinx/util/nodes.py`

Evidence: `make_refnode()` uses `refid` for same-document targets and otherwise
sets `refuri` to `builder.get_relative_uri(fromdocname, todocname) + "#" +
targetid`.

Obligation: The inheritance diagram visitor must handle both resolved xref
forms: same-document `refid` and current-page-relative `refuri`.

I5. Source: `repo/sphinx/builders/html/__init__.py` and
`repo/sphinx/builders/dirhtml.py`

Evidence: HTML builders define target URLs through `get_target_uri()`; `dirhtml`
can return directory-style URLs such as `""` or `"pkg/"`.

Obligation: The fix must use builder target URIs instead of reconstructing
filenames from `current_docname + out_suffix`.

I6. Source: `repo/tests/test_ext_graphviz.py`

Evidence: existing public tests expect generated SVG local links such as
`"./_static/images/test.svg"` to be rewritten as `"../_static/images/test.svg"`
and fragment-only `"#graphviz"` as `"..#graphviz"`.

Obligation: Generic Graphviz SVG relative-link rewriting remains rooted at the
actual SVG asset directory. This is supporting evidence, not a complete oracle
for the bug.

## Formal Model

Let:

- `C` be `builder.get_target_uri(builder.current_docname)`, the output URL of
  the containing HTML page.
- `R` be a resolved xref `refuri`, already relative to `C`.
- `A` be a same-page `refid`.
- `D` be `builder.imagedir`, the output directory containing generated SVGs.
- `Root(C, R)` be the normalized output-root-relative URL obtained by resolving
  `R` against the directory part of `C`, preserving query and fragment.
- `SvgRel(U)` be `posixpath.relpath(posixpath.normpath(path(U)), D)` with the
  original query and fragment restored.
- `Resolve(Base, H)` be browser URL resolution of href `H` against base path
  `Base`.

For an SVG generated at output path `D / file.svg`, the required postconditions
are:

S1. For every local relative `refuri` `R`, the SVG href is `SvgRel(Root(C, R))`.
Resolving that href from `D / file.svg` reaches the same document and fragment as
resolving `R` from `C`.

S2. For every same-document `refid` `A`, the SVG href is `SvgRel(C + "#" + A)`.
Resolving that href from `D / file.svg` reaches fragment `A` in the current
document.

S3. For PNG output, `refuri` remains `R` and same-document `refid` remains
`"#" + A`, because the image map is embedded directly in the current HTML page.

S4. For generic Graphviz SVG output, `fix_svg_relative_paths()` rewrites only
local relative paths. URLs with a scheme, network location, or absolute path are
not relative and must be left unchanged.

S5. No public directive signature, node attribute contract, or builder API
signature changes.

## Adequacy Check

The formal model directly represents the property under test: path resolution of
SVG hrefs from the image directory versus page-relative HTML links. It preserves
the discriminating axis from the issue. A passing case and failing case are
distinguishable:

- Passing: `C = "my_package/index.html"`, `R =
  "my_class_1.html#my_package.MyClass1"`, final href =
  `"../my_package/my_class_1.html#my_package.MyClass1"`.
- Failing legacy case: same `C` and `R`, final href =
  `"../my_class_1.html#my_package.MyClass1"`, which resolves to the output root.

The spec does not claim total correctness for Graphviz execution, filesystem
copying, XML parser behavior, or browser/network serving behavior beyond normal
relative URL resolution.
