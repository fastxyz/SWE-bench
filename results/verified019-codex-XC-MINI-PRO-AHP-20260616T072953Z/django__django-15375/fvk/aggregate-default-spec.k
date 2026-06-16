requires "mini-django-aggregate.k"

module AGGREGATE-DEFAULT-SPEC
  imports MINI-DJANGO-AGGREGATE

  // SPEC-PROVENANCE:
  // - from_prompt: "annotate(...) then aggregate(Sum(..., default=0))" crashes with
  //   an empty outer SELECT.
  // - from_prompt: explicit Coalesce(Sum(...), 0) works.
  // - from_code: QuerySet.aggregate() passes is_summary=True for terminal aggregate clauses.
  claim <k> plan(true, resolve(true, terminal)) => valid </k>
    [all-path, label(TERMINAL-DEFAULT-AFTER-ANNOTATE-VALID)]

  // SPEC-PROVENANCE:
  // - from_code: BaseExpression.resolve_expression() defines summarize as the terminal
  //   aggregate marker and copies it to is_summary.
  // - frame condition: resolving a defaulted aggregate as a normal annotation must not
  //   make it a terminal aggregate reduction.
  claim <k> isSummary(resolve(true, nonTerminal)) => false </k>
    [all-path, label(NONTERMINAL-DEFAULT-NOT-SUMMARY)]

  // SPEC-PROVENANCE:
  // - from_prompt: annotate(...) then aggregate(Sum("id")) works without default.
  // - frame condition: the fix must preserve non-default terminal aggregate planning.
  claim <k> plan(true, resolve(false, terminal)) => valid </k>
    [all-path, label(TERMINAL-NO-DEFAULT-VALID)]

  // SPEC-PROVENANCE:
  // - from_prompt: reported SQL is "SELECT FROM (... COALESCE(SUM(...), ?) ...)".
  // - from_code: get_aggregation() moves only expressions with expression.is_summary.
  // - regression witness: the pre-fix wrapper has is_summary=false and is not moved.
  claim <k> plan(true, resolveBefore(true, terminal)) => invalid </k>
    [all-path, label(PREFIX-REGRESSION-SHAPE)]
endmodule
