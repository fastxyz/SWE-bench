# Baseline Notes

## Root cause

The toctree directive treats each non-URL entry as a source document name. During
parsing it warns when that source document is not present in `env.found_docs`,
and during resolution it looks up the same entry in `env.tocs`. The generated
HTML pages `genindex`, `py-modindex`, and `search` are not source documents, even
though the standard domain exposes the public labels `genindex`, `modindex`, and
`search` for `:ref:` links. As a result, putting `genindex`, `modindex`, or
`search` directly in a toctree was rejected before the HTML builder had a chance
to link to the generated pages.

## Changed files

* `repo/sphinx/directives/other.py`: when a normal document lookup fails, the
  parser now accepts the standard generated-page labels `genindex`, `modindex`,
  and `search` as toctree entries instead of warning. These entries are kept out
  of `includefiles` because they are not source documents and should not affect
  rebuild dependencies or document relations.
* `repo/sphinx/environment/adapters/toctree.py`: added a small helper for
  resolving the generated-page labels through the standard domain, and taught
  toctree resolution to render those entries as internal links using the label
  target and title. This maps `modindex` to the existing `py-modindex` target and
  leaves final URI generation to the builder's normal relative URI pass.
* `repo/sphinx/environment/collectors/toctree.py`: skipped generated-page
  toctree entries during figure-number traversal so `numfig` does not try to
  load non-source doctrees for these generated pages.

## Assumptions and alternatives

I treated only the three built-in standard-domain labels named in the issue as
valid generated toctree targets. I rejected supporting arbitrary labels in
toctrees because toctree entries are document-oriented, and broadening them to
all labels would change existing semantics.

I kept real source documents ahead of generated labels. If a project has an
actual source document such as `genindex.rst`, the existing document behavior is
preserved and the generated-page special case is only considered after the
normal source lookup fails.

I did not add these generated pages to `includefiles`. They do not have source
doctrees, and including them there would incorrectly affect relation building,
rebuild tracking, and non-HTML builders that inline source toctrees.

I did not run tests or project code, per the task constraints.
