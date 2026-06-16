# Intent Spec

Status: constructed from public issue text and repository source; not machine-checked.

## Scope

This FVK pass audits the V1/V2 fix for the issue "source-read event does not
modify include'd files source". The audited production units are:

- `sphinx.directives.other.Include.run`
- the private helper `_emit_source_read_on_include`
- `sphinx.ext.duration.on_source_read`, because it is a public in-tree listener
  for the event whose firing pattern changes.

The rest of Sphinx is treated as context. No tests or executable tooling were
run.

## Required behaviors

I1. For a Sphinx-managed `.. include:: file` directive, the file contents that
docutils inserts into the including document must be the result of applying
Sphinx's `source-read` event to the included file contents.

I2. A `source-read` handler may replace the entire source text by assigning
`source[0]`; the include path must use that replacement text.

I3. In the reproduction, both the included file's `&REPLACE_ME;` and the
including document's `&REPLACE_ME;` must render as `REPLACED`; the included one
must not remain as `&amp;REPLACE_ME;`.

I4. The Sphinx include directive's existing path handling and docutils include
features must be preserved. Sphinx-managed paths still go through
`env.relfn2path`, included source documents are still registered with
`env.note_included`, and docutils remains responsible for include options such
as literal/code mode, encoding, line slicing, dependency recording, and
insertion.

I5. Docutils standard include names such as `<isonum.txt>` must remain on the
existing docutils path and must not be reinterpreted as Sphinx source-directory
paths.

I6. The patch must not leave docutils' input class globally replaced after the
include read completes, even if include processing exits through an exception.

I7. The `source-read` event docname for an included source file should be the
included file's source docname when one can be derived; otherwise the containing
document remains the best available Sphinx docname.

I8. Built-in listeners should remain compatible with the new event firing
pattern. In particular, `sphinx.ext.duration` should measure the document read
from the first `source-read` event in that document read, not reset the timer
when include files emit additional `source-read` events.
