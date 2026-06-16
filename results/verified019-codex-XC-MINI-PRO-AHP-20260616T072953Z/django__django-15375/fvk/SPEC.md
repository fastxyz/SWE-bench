# FVK Spec

Status: constructed, not machine-checked.

## Scope

This FVK pass audits the V1 change in `repo/django/db/models/aggregates.py`, specifically `Aggregate.resolve_expression()` when an aggregate has a `default` and is internally wrapped in `Coalesce`.

The observable under verification is whether aggregation planning has a non-empty outer aggregate select when existing annotations force a subquery. The model keeps only the state needed to distinguish the bug:

- whether the aggregate is terminal (`summarize=True`);
- whether `default` creates a `Coalesce` wrapper;
- whether existing annotations force the subquery aggregation path;
- whether the resolved expression is marked `is_summary`;
- whether the plan is valid or invalid.

## Public Intent Ledger

### E1: Reported failing call

- Source: prompt
- Evidence: `Book.objects.annotate(idx=F("id")).aggregate(Sum("id", default=0))`
- Obligation: a defaulted terminal aggregate must work after prior annotations force a subquery.
- Status: encoded by `TERMINAL-DEFAULT-AFTER-ANNOTATE-VALID`.

### E2: Invalid SQL symptom

- Source: prompt
- Evidence: `SELECT FROM (SELECT ... COALESCE(SUM(...), ?) AS "id__sum" FROM "core_book") subquery`
- Obligation: the outer aggregate query must select the defaulted aggregate rather than being empty.
- Status: encoded as `plan(true, resolve(true, terminal)) => valid`.

### E3: Explicit Coalesce workaround

- Source: prompt
- Evidence: `aggregate(x=Coalesce(Sum("id"), 0))` works.
- Obligation: the implicit `Coalesce` created by `Aggregate.default` must be treated as the terminal aggregate expression.
- Status: encoded by summary preservation on `resolve(true, terminal)`.

### E4: Field independence

- Source: public hint
- Evidence: "The crash happens whether or not the aggregate uses the annotated field."
- Obligation: the fix must address expression classification, not column selection.
- Status: the model abstracts away field identity and aliases.

### E5: Location of responsibility

- Source: public hint
- Evidence: "`Aggregate.default` generates a `Coalesce` internally."
- Obligation: repair the wrapper creation in `Aggregate.resolve_expression()`.
- Status: V1 changes only that function.

### E6: Meaning of `summarize`

- Source: source code and comments
- Evidence: `BaseExpression.resolve_expression()` says `summarize` is "a terminal aggregate clause" and sets `c.is_summary = summarize`.
- Obligation: the replacement wrapper returned by `Aggregate.resolve_expression()` should preserve the resolved aggregate's summary state.
- Status: encoded by `NONTERMINAL-DEFAULT-NOT-SUMMARY` and supports V1's `coalesce.is_summary = c.is_summary`.

## Contract

For all in-scope aggregate-resolution states:

1. If `default` is present and the aggregate is terminal, resolving the aggregate returns a wrapper whose summary state is true.
2. If existing annotations force a subquery, a terminal defaulted aggregate is moved to the outer aggregate query and produces a valid aggregate plan.
3. If `default` is present but the aggregate is not terminal, resolving the aggregate returns a wrapper whose summary state remains false.
4. If `default` is absent, existing aggregate planning behavior is preserved.

## Formal Files

- `mini-django-aggregate.k`: minimal K fragment for the summary/default/subquery planning axis.
- `aggregate-default-spec.k`: K reachability claims for the terminal defaulted path, non-terminal frame condition, non-default frame condition, and pre-fix regression witness.

## No Loop Obligations

The audited source slice has no loop or recursive function in the behavior being changed. There are no circularity claims.
