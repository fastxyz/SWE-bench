# Baseline Notes

## Root cause

Sphinx emits the `source-read` event when a source document is read through
`SphinxStandaloneReader.read_source()`. A file named in an `.. include::`
directive is read later by docutils' include directive path, which inserts the
raw file contents into the current state machine. That include read bypassed
Sphinx's `source-read` processing, so extensions could mutate the included file
when it was discovered and read as its own document, but those mutations were not
used for the content inserted into the including document.

## Files changed

`repo/sphinx/directives/other.py`

- Added a small context manager used by Sphinx's `Include` directive to
  temporarily wrap docutils' `FileInput` while the base include implementation is
  reading the include target.
- The wrapper emits Sphinx's `source-read` event with the included file's
  docname when the include target maps to a source document, otherwise with the
  current document name, and returns the possibly modified source text to
  docutils.
- Updated `Include.run()` to use this wrapper only for Sphinx-managed include
  paths. Docutils standard includes such as `<isonum.txt>` continue through the
  existing path unchanged.

## Assumptions and alternatives considered

- I assumed the intended behavior is that source-level transformations apply to
  source files inserted by `.. include::`, matching how transformations apply to
  top-level documents before parsing.
- I kept docutils' own include implementation responsible for options such as
  `:literal:`, `:code:`, line slicing, encodings, dependency recording, and
  insertion order. Reimplementing the full include directive in Sphinx was
  rejected because it would be broader and more fragile across supported
  docutils versions.
- I did not move `source-read` emission into the global Sphinx input class,
  because docutils include reads do not use that class directly and a broader
  change could alter unrelated file reads.
- I did not modify tests because the benchmark instructions require source-only
  changes and hidden tests. I also did not run tests or code, per the task
  constraints.
