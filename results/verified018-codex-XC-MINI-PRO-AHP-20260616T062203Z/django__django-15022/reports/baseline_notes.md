# Baseline Notes

## Root cause

`ModelAdmin.get_search_results()` built one `Q` object for each search token and
immediately applied it with `queryset = queryset.filter(or_queries)` inside the
token loop. For admin searches that include related fields in `search_fields`,
each chained `filter()` call gives the ORM another opportunity to allocate join
aliases for the same relationship path. Multi-word searches therefore generated
additional joins proportional to the number of words, which is the behavior
reported in the issue.

## Files changed

`repo/django/contrib/admin/options.py`

- Changed `ModelAdmin.get_search_results()` to collect the per-token OR clauses
  first.
- Applied those clauses together as one ANDed `Q` expression in a single
  `queryset.filter()` call.
- Left lookup construction, quoted phrase handling, and duplicate detection
  unchanged.

## Assumptions and alternatives considered

- I treated the documented admin search behavior as the contract: split the
  query into words, require each word to match at least one configured
  `search_fields` entry, and preserve quoted phrases as a single token.
- I kept the existing `lookup_spawns_duplicates()` check because the change only
  affects how the search predicate is submitted to the ORM, not which lookup
  paths can duplicate rows.
- I considered leaving the chained filters in place and trying to optimize only
  related lookups, but that would keep the issue's root pattern for common
  searches and require more invasive query-shape special cases.
- I considered changing the duplicate-handling logic in the changelist, but the
  excessive joins originate before that path, in the admin search predicate
  construction.
- Tests were not run because the task instructions explicitly prohibit running
  tests or project code in this workspace.
