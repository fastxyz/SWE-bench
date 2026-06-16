# FVK Notes

The V1 functional implementation in `repo/django/template/defaultfilters.py`
stands unchanged. Finding F-001 discharges PO-1 through PO-4: the filter is
registered, preserves sequence order/cardinality, applies `conditional_escape()`
per item, and feeds escaped items into `join` before the `autoescape=False`
branch concatenates and marks the result safe.

I added one V2 non-test repo change:
`repo/docs/ref/templates/builtins.txt` now documents `escapeseq`. This is traced
to Finding F-002 and PO-6: the FVK public compatibility audit treats a new
built-in template filter as public surface that should appear in the built-in
filter reference.

I kept `conditional_escape()` rather than switching to `escape()` because F-003
and PO-3 require the new filter to mirror Django's existing `escape` filter,
which conditionally preserves already-safe values instead of force-escaping
them. I also left `join` unchanged because PO-4 and PO-5 localize the issue to a
missing pre-join sequence filter, not to separator handling or `join`'s existing
autoescape contract.

I did not add non-iterable handling because F-004 keeps the domain aligned with
the prompt's sequence/list example and the nearby `safeseq` behavior. I did not
modify tests or run tests, Python, or K tooling; F-005 and PO-7 label the proof
constructed, not machine-checked, and keep all future test-removal claims
conditional on an actual `kprove` run.
