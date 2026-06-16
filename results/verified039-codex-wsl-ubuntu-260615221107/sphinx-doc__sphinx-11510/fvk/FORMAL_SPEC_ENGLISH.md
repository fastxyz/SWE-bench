# Formal Spec In English

Status: constructed, not machine-checked.

## CLAIM-MANAGED-INCLUDE

For every Sphinx-managed include file `FILE` with raw source `SRC`, current
document `CUR`, and derived include docname `DOC`, running `Include.run()` must
cause docutils to insert `sourceRead(DOC, SRC)`. The include-side event list must
record that `source-read` was emitted for `DOC` with `SRC`. The docutils
`FileInput` binding is restored afterward.

## CLAIM-MANAGED-INCLUDE-FALLBACK-DOC

For every Sphinx-managed include file that has no source docname, running
`Include.run()` must emit `source-read` using the containing document `CUR` and
insert `sourceRead(CUR, SRC)`.

## CLAIM-STANDARD-INCLUDE-FRAME

For every include argument that is a docutils standard include name, Sphinx does
not wrap docutils input or emit the include-side `source-read`; docutils receives
the directive unchanged.

## CLAIM-DIRECT-FILEINPUT-COVERAGE

If the docutils implementation resolves `FileInput` from a direct global in
`BaseInclude.run` rather than through the `docutils.io` module, the wrapper still
intercepts the include read and restores that direct global afterward.

## CLAIM-DURATION-FIRST-SOURCE-READ

For a document read, the first `duration.on_source_read()` call records the
start timestamp. Later source-read calls in the same document read leave that
timestamp unchanged.
