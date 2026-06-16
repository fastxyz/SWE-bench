## Root cause

The `linkcheck` builder classified every non-empty, non-anchor, non-HTTP(S)
URI as `local` and returned without validating it. That meant a reference such
as `doesntexist` was reported as local but never checked against Sphinx's known
documents or against files under the source tree. The builder also returned an
empty target URI for all Sphinx documents, so resolved cross-document links did
not carry enough information for a local-link check.

## Changed files

`repo/sphinx/builders/linkcheck.py`

- Added HTML-style target URI generation for the `linkcheck` builder using the
  configured HTML link suffix. This gives resolved Sphinx document references a
  concrete local URI such as `other.html`.
- Built a map of generated Sphinx document URIs during `prepare_writing()`.
- Added local-link validation for non-HTTP(S) `refuri` values. Local links now
  remain `local` when they point to a known Sphinx document or to an existing
  source-tree file, and become `broken` with `local file not found` when the
  target is checkable but missing.
- Kept uncheckable local schemes and paths outside the source tree as `local`
  to avoid false positives for deployment-specific files.
- Added `linkcheck_local_links`, enabled by default, so projects can opt out of
  local-link validation if they intentionally add files outside Sphinx.
- Added a separate `_has_broken` flag so local broken links fail the build
  without storing relative local URIs in the external-link cache. The same
  relative URI can resolve differently from different source documents.

## Assumptions and alternatives

I assumed the issue's `doesntexist` example should fail under the default
`make linkcheck` behavior, so local-link validation is enabled by default.

I treated known Sphinx documents and existing files under the source directory
as valid local targets. This keeps the fix useful for both generated document
links and local file references without requiring an HTML build output to exist.

I did not validate local `#anchor` fragments. Sphinx already validates normal
resolved internal references during reference resolution, and checking arbitrary
local file anchors would require parsing generated output that the linkcheck
builder does not produce.

I considered checking all local paths against the eventual HTML output
directory, but rejected that because `linkcheck` does not build those output
files. I also considered marking absolute or source-tree-escaping paths as
broken, but rejected that because the issue discussion notes that deployment
scripts may add files Sphinx cannot know about.
