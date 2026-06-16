# Public Evidence Ledger

Status: constructed, not machine-checked.

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | "New template filter `escapeseq`" | Add a built-in filter with this public name. | Encoded in `SPEC.md`, `escapeseq-spec.k`, and implemented in `defaultfilters.py`. |
| E2 | `benchmark/PROBLEM.md` | "`{{ some_list|escapeseq|join:\",\" }}` where each item of some_list is escaped before applying the join operation." | `escapeseq` must transform sequence elements before `join` consumes them. | Encoded as PO-2 and PO-4. |
| E3 | `benchmark/PROBLEM.md` | "escape what safeseq is to safe" | Mirror `safeseq`'s sequence-map shape, but use `escape` semantics per element. | Encoded as PO-2 and PO-3. |
| E4 | `repo/docs/ref/templates/builtins.txt` | "`escape` ... only result in one round of escaping ... use `force_escape`" | `escapeseq` should not be `force_escape` for each element. | Encoded as PO-3. |
| E5 | `repo/docs/ref/templates/builtins.txt` | "`safeseq` ... applies the `safe` filter to each element of a sequence." | Preserve order/cardinality and per-element sequence mapping. | Encoded as PO-2. |
| E6 | `repo/django/template/defaultfilters.py` | `join(..., autoescape=False)` uses `arg.join(value)` and returns `mark_safe(data)`. | The issue example requires escaping before this branch executes. | Encoded as PO-4; no change to `join`. |
| E7 | `repo/django/template/library.py` | `register.filter` stores functions under their public filter names. | Decorating `escapeseq` registers the filter for template use. | Encoded as PO-1. |
| E8 | `repo/docs/ref/templates/builtins.txt` | Existing built-in filters have `.. templatefilter::` docs entries. | The new public built-in filter should have a docs entry. | Finding F-002; fixed by adding docs. |
