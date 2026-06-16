# Proof Obligations

Status: constructed, not machine-checked.

## PO-1: parser accepts generated labels without source side effects

For each `ref in {genindex, modindex, search}`, when normal document lookup
fails and the standard-domain generated target exists, `parse_content` must:

* append `(title, ref)` to `toctree['entries']`;
* not append to `toctree['includefiles']`;
* not emit a nonexisting-document warning;
* not call `env.note_reread()`.

K claims: `PARSE-GENINDEX`, `PARSE-MODINDEX`, `PARSE-SEARCH`.

## PO-2: standard-domain target mapping is preserved

The generated target returned for `modindex` is `py-modindex`, and generated
display text defaults to the standard-domain label title unless the toctree entry
has an explicit title.

K claims: `RESOLVE-GENINDEX`, `RESOLVE-MODINDEX`, `RESOLVE-SEARCH`,
`RESOLVE-GENINDEX-EXPLICIT`.

## PO-3: old behavior remains for non-generated entries

Existing source documents still become source entries and includefiles. Unknown
non-generated documents still warn.

K claims: `SOURCE-DOC-WINS`, `UNKNOWN-STILL-WARNS`.

## PO-4: generated entries are not source doctrees in downstream consumers

Generated entries must be skipped by both section-number and figure-number
traversal. Neither traversal may require `env.tocs[ref]` or
`env.get_doctree(ref)` for generated entries.

K claims: `SECTION-SKIP-GENERATED`, `FIGURE-SKIP-GENERATED`.

## PO-5: compatibility and scope

No public method signature, directive option, or test file changes are required.
The helper is internal, and the special case is limited to the three public
labels named by the issue.
