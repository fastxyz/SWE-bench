# Public Evidence Ledger

Status: constructed, not machine-checked.

| ID | Source | Quoted evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | "`Exists(...) & Q(...)` works, but `Q(...) & Exists(...)` raise a `TypeError`" | Left-hand `Q` combined with right-hand `Exists` is an in-domain operation and must not raise `TypeError`. | Encoded in `SPEC.md`, `q-combine-spec.k`, PO-1, PO-3, PO-5. |
| E2 | `benchmark/PROBLEM.md` | "The `&` (and `|`) operators should be commutative on Q-Exists pairs" | Both `AND` and `OR` connectors must accept the `Q`/`Exists` pair in either operand order at the logical filter level. | Encoded in `SPEC.md`, `q-combine-spec.k`, PO-3, PO-6. |
| E3 | `benchmark/PROBLEM.md` | Traceback points to `Q._combine()` raising when `other` is not a `Q`. | The root cause is the pre-fix type guard rejecting a conditional expression before wrapping it as a `Q`. | Finding F1; discharged by V1 lines 42-46. |
| E4 | Public hint in `benchmark/PROBLEM.md` | "Tests: ... `Employee.objects.filter(Q(salary__gte=30) & Exists(is_ceo))` ... `Q(salary__lt=15) | Exists(is_poc)`" | Non-empty `Q` left operands must combine with `Exists` for both connectors and remain query-filter-compatible. | Encoded in PO-3, PO-6, PO-8. |
| E5 | Existing source `Combinable.__and__()` / `__or__()` | It combines two `conditional` operands by returning `Q(self) & Q(other)` or `Q(self) | Q(other)`. | The internal expression contract is based on conditional boolean expressions, not only concrete `Q` instances. | Default-domain support for PO-2 and PO-3. |
| E6 | Existing source `Query.build_filter()` | It accepts `filter_expr` with `resolve_expression` only when `conditional` is true. | A resulting `Q` child containing `Exists` is compatible with query building. | Encoded in PO-8. |
| E7 | Existing public tests in `tests/queries/test_q.py` | `test_combine_not_q_object` expects non-`Q` plain objects to raise `TypeError`. | The fix must preserve rejection for non-conditional objects. | Encoded in PO-2. |

