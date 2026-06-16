# Baseline Notes

## Root Cause

Glossary terms were registered in the standard domain with
`termtext.lower()` as the object name. The duplicate-object check in
`StandardDomain.note_object()` uses that object name as part of its key, so
two real glossary entries that only differ by case, such as `MySQL` and
`mysql`, collapsed to the same `('term', 'mysql')` key and emitted a duplicate
term warning.

The `:term:` role also lowercased its target before resolution, which meant
that even if term registration became case-sensitive, the original spelling of
the reference target would already be lost by the time the standard domain tried
to resolve it.

## Files Changed

`repo/sphinx/domains/std.py`

- Register glossary terms under their visible term text instead of a lowercased
  key so `MySQL` and `mysql` remain distinct standard-domain objects.
- Stop lowercasing `:term:` role targets during role parsing so exact-case term
  references can resolve to the corresponding exact-case glossary entry.
- Add a term-specific resolver that first tries an exact match, then falls back
  to a case-insensitive match only when all matching entries point to the same
  target. This preserves existing tolerant behavior for unambiguous references
  and translated glossary terms without reintroducing the collision for distinct
  case variants.
- Update `:any:` standard-domain term lookup to use the same term-specific
  resolution path.

## Assumptions and Alternatives

I assumed the issue means glossary term identity should be case-sensitive, so
case-only variants are valid distinct entries and should not trigger duplicate
warnings.

I also assumed existing case-insensitive reference behavior should be preserved
when it is not ambiguous, because Sphinx already had lowercased `:term:` targets
and the i18n transform can register translated term spellings for the same
anchor. The fallback only resolves when matching entries collapse to one target;
with separate `MySQL` and `mysql` entries, a non-exact `MYSQL` reference is left
unresolved rather than choosing incorrectly.

I considered only suppressing the duplicate warning while keeping lowercased
object keys, but rejected that because one entry would still overwrite the other
in the standard-domain object inventory. I also considered making all term
lookup strictly case-sensitive with no fallback, but that would unnecessarily
break existing unambiguous references and translated glossary terms.
