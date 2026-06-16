# Formal Spec In English

The K claims in `aggregate-default-spec.k` mean the following.

## TERMINAL-DEFAULT-AFTER-ANNOTATE-VALID

If an aggregate is resolved as a terminal aggregate, has a `default`, and the queryset already has annotations so aggregation planning uses an inner subquery plus an outer aggregate query, the planned query is valid. In the model, valid means the resolved expression is marked summary and is therefore moved to the outer aggregate query instead of leaving the outer `SELECT` empty.

## NONTERMINAL-DEFAULT-NOT-SUMMARY

If an aggregate with `default` is resolved outside a terminal `aggregate()` call, the generated `Coalesce` wrapper is not marked as a terminal summary expression.

## TERMINAL-NO-DEFAULT-VALID

If an aggregate is resolved as terminal and has no `default`, it remains a summary expression and aggregation planning is valid. This is the frame condition that the fix preserves existing non-default aggregate behavior.

## PREFIX-REGRESSION-SHAPE

The pre-fix behavior, modeled as resolving a defaulted aggregate to a `Coalesce` wrapper with `is_summary = false`, produces an invalid plan in the annotated terminal aggregate path. This claim localizes the reported `SELECT FROM (...)` symptom to loss of the summary flag on the wrapper.

No loops or recursive functions are present in the modeled slice, so there are no circularity claims.
