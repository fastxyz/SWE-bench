# Spec Audit

Status: constructed, not machine-checked.

| Formal clause | Intent coverage | Result |
| --- | --- | --- |
| `TERMINAL-DEFAULT-AFTER-ANNOTATE-VALID` | Matches E1, E2, and E3: defaulted terminal aggregate after `annotate()` must produce a valid aggregate plan equivalent to explicit `Coalesce`. | Pass |
| `NONTERMINAL-DEFAULT-NOT-SUMMARY` | Matches E6: `summarize` is the terminal aggregate marker, so non-terminal annotations should not be marked as terminal reductions. | Pass |
| `TERMINAL-NO-DEFAULT-VALID` | Matches E1's control example where non-default terminal aggregate after annotation works. | Pass |
| `PREFIX-REGRESSION-SHAPE` | Matches E2 and localizes the reported empty outer `SELECT` to the non-summary wrapper. | Pass |

## Adequacy decision

The formal model intentionally abstracts away SQL strings, fields, aliases, database backends, and aggregate numeric values. That abstraction is adequate for this issue because the reported failure is caused before numeric evaluation: `Query.get_aggregation()` decides whether the aggregate expression is removed from the inner subquery by reading `expression.is_summary`. The model preserves the discriminator for both passing and failing instances:

- Passing instance: `resolve(true, terminal)` has `isSummary == true`, so `plan(true, ...) == valid`.
- Failing pre-fix instance: `resolveBefore(true, terminal)` has `isSummary == false`, so `plan(true, ...) == invalid`.

No required behavior is marked fail or ambiguous.
