# FVK Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`,
Python, or test command was executed.

## Claims Proved

The constructed proof covers the obligations in `fvk/PROOF_OBLIGATIONS.md`:

- PO-01: `_render_target_uri()` converts local page-relative class links into
  output-root-relative links.
- PO-02: same-document class links use `builder.get_target_uri()`.
- PO-03: `fix_svg_relative_paths()` rewrites SVG hrefs from the actual generated
  SVG directory.
- PO-04: the composition of PO-01 and PO-03 preserves the browser-resolved class
  target.
- PO-05: non-relative SVG URLs are preserved.
- PO-06: PNG output is unchanged.
- PO-07: public extension compatibility is preserved.

## Symbolic Counterexample for V1

This is the proof-derived failing state that caused the V2 edit.

Let:

- current HTML URI `C = "my_package/index.html"`;
- generated SVG directory `D = "_images"`;
- builder image path while writing `C`: `builder.imgpath = "../_images"`;
- class `refuri` from Sphinx: `R =
  "my_class_1.html#my_package.MyClass1"`.

V1 inheritance logic produced:

```text
Root(C, R) = "my_package/my_class_1.html#my_package.MyClass1"
```

That part is correct. But V1 still used the old Graphviz rewrite start:

```text
start = path.join(outdir, builder.imgpath)
      = path.join(outdir, "../_images")
```

That start directory is not where the SVG file is written. `render_dot()` writes
the SVG under:

```text
path.join(outdir, builder.imagedir, fname)
```

Therefore V1's final href was relative to the wrong base. It did not prove
PO-03 and could not prove PO-04.

## V2 Proof Sketch

### PO-01

`_render_target_uri()` parses the current-page-relative `refuri`.

For in-domain local relative paths:

1. It obtains the current output URI from `builder.get_target_uri()`.
2. If the target URI has a path, it joins that path against the current URI's
   directory using POSIX URL path operations.
3. It normalizes the resulting path and restores query and fragment.

For the issue case:

```text
C = "my_package/index.html"
R = "my_class_1.html#my_package.MyClass1"
dirname(C) = "my_package"
Root(C, R) = "my_package/my_class_1.html#my_package.MyClass1"
```

This discharges PO-01.

### PO-02

Same-document resolved xrefs use `refid`, not `refuri`. V2 forms:

```text
builder.get_target_uri(builder.current_docname) + "#" + refid
```

This is already output-root-relative for the current document. It also supports
directory-style builders because it uses the builder target API. This discharges
PO-02.

### PO-03

V2 rewrites generated SVG local hrefs with:

```text
posixpath.relpath(posixpath.normpath(url), builder.imagedir)
```

`builder.imagedir` is the same directory component used by `render_dot()` for the
SVG output file. Therefore the calculated href is relative to the actual SVG file
location. For the issue target:

```text
url = "my_package/my_class_1.html#my_package.MyClass1"
builder.imagedir = "_images"
relpath("my_package/my_class_1.html", "_images")
  = "../my_package/my_class_1.html"
```

Restoring the fragment yields:

```text
"../my_package/my_class_1.html#my_package.MyClass1"
```

This discharges PO-03.

### PO-04

By PO-01, `Root(C, R)` is the output-root-relative document path that the
containing HTML page intends. By PO-03, the SVG href is the relative path from
the SVG directory to that same root-relative target. Resolving that href from the
SVG file therefore lands on `Root(C, R)`, which is equal to resolving `R` from
`C`. This discharges PO-04.

### PO-05

V2 checks `scheme or hostname or url.startswith('/')` before rewriting. Those
cases are not local relative URLs, so they remain unchanged. This discharges
PO-05.

### PO-06

The PNG branches still return `child.get('refuri')` and `"#" + child.get('refid')`.
Because PNG image maps are embedded in the current HTML page, these page-relative
values remain correct. This discharges PO-06.

### PO-07

The diff changes no public function signatures, directive names, node classes, or
builder methods. It adds one private helper and modifies internals. This
discharges PO-07.

## Adequacy and Coverage

The proof covers the full reported defect mechanism:

1. Sphinx resolves class xrefs relative to the current document.
2. Inheritance diagrams pass those URLs into Graphviz.
3. SVG output stores links in a separate image file.
4. Browsers resolve those links relative to the SVG file.

The proof does not cover:

- Graphviz subprocess execution;
- XML parser correctness;
- browser behavior beyond ordinary relative URL resolution;
- link targets not represented in resolved xrefs;
- generated SVGs that omit `xlink:href` entirely.

## Machine-Check Commands

The intended K commands for a full encoding are:

```sh
kompile fvk/mini-url-rewrite.k --backend haskell
kast --backend haskell fvk/inheritance-svg-spec.k
kprove fvk/inheritance-svg-spec.k
```

They were not run in this task.

## Test Guidance

No tests should be removed. Existing root-level SVG tests are not redundant
because the proof is not machine-checked and public coverage lacks the nested
inheritance case. Add the nested SVG inheritance regression described in F-05
when editing tests is allowed.
