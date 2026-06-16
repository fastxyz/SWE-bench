# Spec Audit

Status: adequacy gate comparing `INTENT_SPEC.md` to `FORMAL_SPEC_ENGLISH.md`.

| Formal claim | Intent obligation | Result | Notes |
| --- | --- | --- | --- |
| NO-LASTMOD | O1 | Pass | Matches the optional absence behavior. |
| ATTRIBUTE-LASTMOD | O2 | Pass | Matches the documented attribute branch. |
| CALLABLE-EMPTY-LASTMOD | O4 | Pass | Directly covers the reported empty-items `ValueError` case and expects `None`. |
| CALLABLE-LASTMOD | O3, O4, O5 | Pass | General callable result: latest for comparable values, `None` for empty, `None` for modeled `TypeError`. |
| CALLABLE-NONEMPTY-COMPARABLE | O3 | Pass | Encodes the documented maximum over all items. |
| CALLABLE-TYPEERROR | O5 | Pass | Preserves the existing `TypeError` frame behavior. |
| Frame/compatibility | O6 and frame conditions | Pass | No public signature or dispatch shape changed; sitemap index already consumes `None`. |

## Adequacy Verdict

The formal English is neither weaker nor stronger than the public intent for the audited function. It does not use the pre-fix `ValueError` behavior as a specification. It also rejects the broader alternative of catching all `ValueError`s, because the public hint identifies `max(default=...)` as sufficient for the empty iterable case.
