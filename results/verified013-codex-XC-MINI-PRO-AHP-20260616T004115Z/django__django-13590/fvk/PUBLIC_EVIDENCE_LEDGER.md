# Public Evidence Ledger

| ID | Source | Quoted evidence | Obligation |
| --- | --- | --- | --- |
| IE1 | `benchmark/PROBLEM.md` | "named 2-tuples as arguments to range queryset filters" | Named two-field tuple range values are in domain. |
| IE2 | `benchmark/PROBLEM.md` | "works fine on 2.2" / "causes ... TypeError" | The error is the bug, not the expected behavior. |
| IE3 | `benchmark/PROBLEM.md` | "goes into the tuple elements to resolve lookups" | Recursively resolve container elements. |
| IE4 | `benchmark/PROBLEM.md` | "preserves the type (the named tuple)" | Preserve named tuple type when reconstructing. |
| IE5 | `benchmark/PROBLEM.md` | "The fix is to * expand the contents of the iterator into the constructor." | Use positional expansion for named tuple construction. |
| IE6 | `repo/django/db/models/lookups.py` | `get_prep_lookup()` iterates `self.rhs`; `Range` is a two-value iterable lookup. | Keep a two-value ordered iterable RHS. |
| IE7 | `repo/django/db/models/sql/query.py` | Existing list/tuple branch used `type(value)(iterable)`. | Preserve non-named container frame behavior. |
