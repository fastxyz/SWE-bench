# Constructed Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`,
Python, or tests were run.

## What Is Proved

For the HTML writer formatting pipeline, if a `formats` entry names an output
column, the writer installs that format before it asks Astropy's existing
`info.iter_str_vals()` machinery for data-cell strings. Columns without a
format entry are unchanged. Multicolumn temporary split columns inherit the
source column's active format before their cell strings are generated.

## Proof Sketch

1. `ascii.write` stores the public `formats` keyword on `writer.data.formats`.
2. In V1, `HTML.write` binds the selected HTML output columns to
   `self.data.cols`.
3. `HTML.write` then calls `self.data._set_col_formats()`.
4. By the definition of `BaseData._set_col_formats()`, every column whose
   `info.name` appears in `self.data.formats` has `info.format` set to that
   entry, and every other column is left unchanged.
5. The one-dimensional HTML path constructs cell-string iterators by calling
   `col.info.iter_str_vals()`. Since step 3 precedes iterator construction,
   that iterator observes the supplied format.
6. The multidimensional HTML path first splits a source column into temporary
   columns. V1 copies `col.info.format` to `new_col.info.format` before calling
   `new_col.info.iter_str_vals()`, so the split path observes the same active
   format as the source column.
7. Existing fill-value and raw-HTML handling are framed around the iterator:
   fill-value replacement still wraps the iterator, and the escape or
   bleach-cleaning branch is unchanged.

Therefore V1 satisfies O1 through O6 for the specified domain.

## Constructed K Artifacts

- `mini-python-html-format.k` defines a property-complete mini-semantics for
  the format propagation pipeline.
- `html-format-spec.k` states the reachability claims corresponding to O1,
  O3, and O5. O2 and O4 are frame/delegation obligations explained in this
  proof, and O6 is handled by `PUBLIC_COMPATIBILITY_AUDIT.md`.

## Machine-Check Commands Not Run

These are the commands to run later in an environment with K installed:

```sh
cd fvk
kompile mini-python-html-format.k --backend haskell
kast --backend haskell html-format-spec.k
kprove html-format-spec.k
```

Expected machine-check result if the mini-semantics and claims parse as written:
`#Top`.

## Residual Risk

This is a partial-correctness proof over a focused abstraction. It does not
prove termination, full Python callable semantics, XML escaping internals, or
the complete Astropy table writer registry. Those behaviors are outside this
issue's property and should remain covered by existing tests.

## Test Guidance

Do not remove tests from this repository. If the K commands above are
successfully machine-checked later, unit tests that only assert in-domain
`formats` propagation for HTML data cells become candidates for proof-subsumed
redundancy. Integration tests for HTML structure, raw HTML cleaning, fill
values, file writing, and public registry dispatch should be kept.
