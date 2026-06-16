# Intent Spec

Status: constructed from public evidence, not machine-checked.

## Scope

Target unit: `ModelAdmin.get_search_results()` in
`repo/django/contrib/admin/options.py`.

The audit covers the default admin search predicate construction and return
shape. It does not prove database backend execution, query planner behavior, or
total correctness of queryset evaluation.

## Public-intent obligations

I1. Admin search must split the submitted search query into words. Each word
must match at least one configured `search_fields` entry.

Evidence: Django admin docs say the admin "splits the search query into words"
and returns objects containing each word, "where each word must be in at least
one of `search_fields`."

I2. The Boolean predicate shape for multiple words is an AND across words, where
each word contributes an OR across configured search fields.

Evidence: the docs give the SQL shape:
`(first_name ILIKE '%john%' OR last_name ILIKE '%john%') AND
(first_name ILIKE '%lennon%' OR last_name ILIKE '%lennon%')`.

I3. Quoted phrases remain one search token after unescaping.

Evidence: the docs say the search query can contain quoted phrases with spaces,
for example `"john winston"` or `'john winston'`.

I4. Search fields may traverse related fields.

Evidence: the docs say `search_fields` can use lookup API follow notation such
as `foreign_key__related_fieldname`, and the issue's reproduction uses
`clientoffice__name` and `clientoffice__name2`.

I5. Multi-word admin search with related `search_fields` must not generate one
additional join chain per search word through a `qs = qs.filter(...)` loop.

Evidence: the issue identifies the root problem as "each word in the search
query leads to additional JOIN in final SQL query because of
`qs = qs.filter(...)` pattern" and reports admin stalls for multi-word search.

I6. `get_search_results()` must continue to return `(queryset,
may_have_duplicates)`, and duplicate handling must remain based on whether the
search lookup paths can duplicate rows.

Evidence: the method docstring says it returns a queryset and a boolean
indicating whether results may contain duplicates; existing admin changelist code
consumes that tuple.

## Default-domain assumptions

D1. The proof is partial correctness over finite `search_fields` and finite
search-token streams produced by `smart_split()`.

D2. A single `QuerySet.filter(*term_queries)` call is modeled as one ORM
`Query.add_q()` operation containing all term clauses, based on the current ORM
source path from `QuerySet.filter()` to `_filter_or_exclude_inplace()` to
`Query.add_q(Q(*args, **kwargs))`.

D3. The model treats Django's `Q` objects extensionally: nested AND nodes with
the same children denote the same Boolean predicate. The final V2 code avoids
the extra nested AND wrapper anyway by using `filter(*term_queries)`.
