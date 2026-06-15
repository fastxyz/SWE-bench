# Public Evidence Ledger

| ID | Source | Evidence | Obligation | Spec status |
| -- | -- | -- | -- | -- |
| I-001 | `benchmark/PROBLEM.md` | "Composed queries cannot change the list of columns when values()/values_list() is evaluated multiple times" | Repeated outer values selections on composed queries are independent. | Encoded in `SPEC.md`, PO-3. |
| I-002 | `benchmark/PROBLEM.md` | The second `values_list('order')` still prints `('a', 2)` | Treat that result as observed buggy legacy behavior; expected selected list is only `order`. | Encoded in F-001. |
| I-003 | `repo/django/db/models/query.py` | `_values()` clones the queryset and then calls `clone.query.set_values(fields)` | Field-list changes belong to the current clone, not to reusable query inputs. | Encoded in PO-2. |
| I-004 | `repo/django/db/models/query.py` | `_combinator_query()` stores child query objects in `combined_queries` | Child queries are reusable inputs to compiler construction. | Encoded in PO-2, PO-5. |
| I-005 | `repo/django/db/models/sql/compiler.py` | Existing compiler comment says limited columns must be set on all combined queries if not already set | Preserve single-compilation child column alignment. | Encoded in PO-1. |
| I-006 | V1 diff | `query.clone().get_compiler(...)` | Compiler-time child mutations are isolated to child compiler clones. | Confirmed by PO-2, PO-3. |

No hidden tests, evaluator output, internet sources, or upstream patch
knowledge were used.
