# FVK Notes

## Decision

V1 stands unchanged. The FVK pass did not identify a source-level gap that is
supported by the public issue and not already addressed by V1.

## Trace to findings and obligations

F1 traces to O1, O2, O3, O4, and O5. The reported bug is that a formset prefix
can contain regex metacharacters but was interpolated into a regex without
escaping. V1 uses `re.escape(prefix)` in the regex construction, so the prefix
matches as literal field-name text. V1 also escapes the primary-key field name;
this is not required by the issue but is consistent with O2 because that value
is also interpolated as literal regex text.

F2 traces to O8. A source search found no other same-pattern
`re.compile/search/match(...format(...))` occurrence under the allowed
`repo/django` tree, so no multi-file production edit is justified by this audit.

F3 traces to O6 and O7. V1 preserves the list comprehension, return order,
helper signature, internal caller, and queryset validation path. Because the
only changed behavior is literalizing regex fragments, no compatibility edit is
needed.

F4 records the proof status. The FVK artifacts include a mini K model and
commands to run later, but the benchmark forbids executing K tooling, Python,
Django, or tests. This limits proof confidence to "constructed, not
machine-checked"; it does not surface a code change.

## Source edits in this phase

No files under `repo/` were changed during the FVK phase. The only new files are
FVK artifacts under `fvk/` and this report.

