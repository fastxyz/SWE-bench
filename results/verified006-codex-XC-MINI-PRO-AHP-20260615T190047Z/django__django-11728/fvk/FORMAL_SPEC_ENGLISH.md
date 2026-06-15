# Formal Spec English

Status: paraphrase of the constructed K claims in `admindocs-regex-spec.k`.

## Claim `REPLACE-NAMED-TRAILING`

For any valid pattern containing a named group whose matching closing parenthesis
is the final character, `replaceNamedGroups` rewrites that complete span to the
group name. The absence of a following `/`, `$`, or literal character is not a
precondition.

## Claim `REPLACE-UNNAMED-TRAILING`

For any valid pattern containing an unnamed group whose matching closing
parenthesis is the final character, `replaceUnnamedGroups` rewrites that group
to `<var>`.

## Claim `UNNAMED-OUTERMOST`

For any valid pattern, `selectOutermost` keeps exactly the non-overlapping
outermost unnamed group spans. A span starting at the previous selected span's
end is kept, and a span starting before that end is skipped as nested.

## Claim `UNNAMED-RECONSTRUCT`

For sorted non-overlapping unnamed spans, reconstruction copies each text segment
outside selected spans exactly once and substitutes `<var>` for each selected
span.

## Claim `SIMPLIFY-ISSUE-CASE`

For the issue pattern, the public `simplifyRegex` composition produces
`/entries/<pk>/relationships/<related_field>`.

## Claim `COMPATIBILITY`

The changed implementation has the same callable surface as before: helper
function names, argument counts, return type, and the public wrapper call order
are unchanged.
