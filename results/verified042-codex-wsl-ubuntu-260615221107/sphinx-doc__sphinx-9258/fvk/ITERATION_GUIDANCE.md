# ITERATION GUIDANCE

## Decision

Keep V1 unchanged.  The audit found no unmet source obligation in
`repo/sphinx/domains/python.py`.

## Trace

- F-1 and PO-1 justify the existing V1 source edit: add pipe recognition to the
  Python-domain delimiter regex.
- F-2 with PO-5, PO-6, and PO-7 justifies not adding more field-specific code.
- F-3 with PO-8 justifies not editing `PyAttribute`.
- F-4 with PO-4, PO-9, and PO-10 justifies not moving the change into generic
  `TypedField` or other domains.
- F-5 records the quote-aware/full-parser limitation as outside this issue.
- F-6 and PO-11 require keeping the proof labeled constructed, not
  machine-checked.

## Suggested Public Tests For A Normal Development Pass

Do not modify tests in this benchmark task.  In a normal Sphinx development
pass, useful tests would assert that:

- `:type text: bytes | str` yields pending xrefs for `bytes` and `str` with
  literal pipe text between them;
- `:param bytes | str text:` takes the same path;
- `:vartype value: bytes | str` and `:rtype: bytes | str` take the same path;
- existing `str or int or None` and `Tuple[str, ...]` behavior is unchanged;
- substitution-style non-text content such as `|test|` remains untouched.

## Machine Check Follow-up

The FVK commands in `fvk/PROOF.md` should be run only in an environment with K
installed.  Until then, the proof remains constructed, not machine-checked, and
test removal is not recommended.
