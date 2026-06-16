# FVK Findings

Status: constructed, not machine-checked. Findings are derived from public
intent, source inspection, and symbolic path reasoning. No tests or project code
were run.

## F-01: V1 Did Not Fully Discharge SVG Asset-Relative Rewriting

Classification: code bug in V1; fixed in V2.

Evidence:

- Intent I2 in `fvk/SPEC.md`: SVG hrefs are resolved relative to the SVG file
  under the image directory.
- V1 changed inheritance diagram URLs to output-root-relative form before
  calling Graphviz.
- `fix_svg_relative_paths()` still computed its `relpath()` start from
  `path.join(builder.outdir, builder.imgpath)`.

Observed symbolic counterexample:

- Current document: `C = "my_package/index.html"`.
- SVG asset directory: `D = "_images"`.
- Builder page-relative image path while writing that document:
  `builder.imgpath = "../_images"`.
- Resolved class URI from Sphinx: `R =
  "my_class_1.html#my_package.MyClass1"`.
- V1 inheritance helper produced root-relative target
  `"my_package/my_class_1.html#my_package.MyClass1"`.
- The old Graphviz rewrite used start directory
  `outdir / "../_images"` rather than `outdir / "_images"`, so the final href was
  computed relative to a sibling of the output directory, not relative to the
  actual SVG location.

Expected:

`fix_svg_relative_paths()` must compute relative SVG hrefs from
`builder.imagedir`, the directory where `render_dot()` writes the SVG file.

Resolution:

V2 changes `fix_svg_relative_paths()` to compute
`posixpath.relpath(posixpath.normpath(url), builder.imagedir)`.

## F-02: V1 Correctly Removed the Fixed `"../"` Inheritance Prefix

Classification: V1 behavior confirmed and retained.

Evidence:

- Intent I1 and I2 require nested-page links to include the containing page's
  output directory before final image-directory rewriting.
- `make_refnode()` produces `refuri` relative to the current HTML page for
  cross-document class targets.

Counterexample to the legacy implementation:

- Current document: `my_package/index.html`.
- Class target from the page: `my_class_1.html#my_package.MyClass1`.
- Legacy SVG branch formed `../my_class_1.html#my_package.MyClass1`, omitting
  `my_package/`.

Resolution:

V2 keeps V1's `_render_target_uri()` helper and the SVG `refuri` branch in
`html_visit_inheritance_diagram()`.

## F-03: Absolute and Scheme URLs Are Not Relative SVG Paths

Classification: adjacent code bug found during proof; fixed in V2.

Evidence:

- Intent I6 and the `fix_svg_relative_paths()` docstring describe changing
  relative links.
- The old implementation skipped only URLs with a network location. It would
  still try to rewrite `mailto:...`, `data:...`, or `/absolute/path` values even
  though those are not local relative paths.

Resolution:

V2 skips URLs with a scheme, network location, or absolute path before applying
the relative path rewrite.

## F-04: PNG Output Must Remain Page-Relative

Classification: frame condition; confirmed.

Evidence:

- Intent I3 says the issue does not happen in default PNG mode.
- PNG image-map hrefs are embedded in the containing HTML page, so page-relative
  `refuri` and `#refid` are already in the correct base context.

Resolution:

No PNG branch changes were made.

## F-05: Missing Public Regression Coverage for Nested SVG Inheritance Diagrams

Classification: test gap; not edited because tests are fixed and hidden for this
task.

Evidence:

- Public tests check root-level inheritance SVG HTML wrapper output.
- Public Graphviz tests check root-level SVG href rewriting.
- The issue requires a nested document case.

Recommended test:

Add an HTML build fixture with `graphviz_output_format = "svg"`, an
`inheritance-diagram` in `my_package/index.rst`, and class targets under
`my_package/`. Inspect the generated SVG href and expect
`../my_package/my_class_1.html#...` rather than `../my_class_1.html#...`.

## F-06: Proof Is Constructed, Not Machine-Checked

Classification: proof status and residual risk.

Evidence:

The task forbids running K tooling. The proof artifacts record commands that
would be run later, but no `#Top` result exists in this session.

Resolution:

No tests are recommended for deletion. The FVK proof is a structured audit and
patch justification, not a machine-checked certificate.
