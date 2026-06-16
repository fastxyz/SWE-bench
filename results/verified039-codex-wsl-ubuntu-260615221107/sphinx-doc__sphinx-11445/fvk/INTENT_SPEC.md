# INTENT SPEC

Status: intent-only; written before accepting the V1 implementation as correct.

1. `rst_prolog` must be included at the beginning of every reStructuredText
   source file that is read.
2. Existing leading docinfo fields remain before `rst_prolog`, because Sphinx
   treats a field list near the top of a file as document metadata.
3. A section title must remain adjacent to its underline. `rst_prolog` insertion
   must not place prolog text or generated blank lines between title text and the
   underline.
4. A first heading that starts with an inline domain role, such as
   `:mod:`mypackage2``, is still a heading when followed by a section underline.
5. Section underline recognition for this repair follows the local Sphinx
   documentation: underline with a punctuation character at least as long as the
   title text.
6. If `rst_prolog` is not set, `prepend_prolog()` has no insertion work to do and
   should leave the content unchanged.
7. The repair should not change public parser APIs, `prepend_prolog()`'s
   signature, `append_epilog()`, or test files.

