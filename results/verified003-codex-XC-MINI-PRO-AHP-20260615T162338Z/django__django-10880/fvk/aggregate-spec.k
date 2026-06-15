requires "mini-django-aggregate.k"

module AGGREGATE-SPEC
  imports MINI-DJANGO-AGGREGATE

  // SPEC-PROVENANCE:
  // - from_prompt: "A Count annotation containing both a Case condition and a distinct=True param produces a query error" => distinct aggregate SQL must remain syntactically valid when the expression starts with CASE.
  // - from_prompt: "A space is missing at least (... COUNT(DISTINCTCASE WHEN ...)" => expected separator between DISTINCT and the following expression.
  // - from_code: Aggregate.template is "%(function)s(%(distinct)s%(expressions)s)" and Func.as_sql interpolates this template after compiler.compile(arg).
  claim
    <k> aggregateSql(true, "COUNT", "CASE WHEN P THEN X ELSE NULL END")
      => "COUNT(DISTINCT CASE WHEN P THEN X ELSE NULL END)" </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: when self.distinct is false, Aggregate.as_sql supplies the empty distinct marker.
  // - from_compatibility: non-distinct aggregate SQL should keep the existing template shape, with no newly inserted space after "(".
  claim
    <k> aggregateSql(false, "COUNT", "CASE WHEN P THEN X ELSE NULL END")
      => "COUNT(CASE WHEN P THEN X ELSE NULL END)" </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: on backends without FILTER support, Aggregate.as_sql rewrites filter= into Case(When(filter, then=first_expression)) and calls Func.as_sql with the same extra_context.
  // - from_prompt: the issue applies "whatever the db backend", so the fallback path must also place a separator after DISTINCT.
  claim
    <k> filterFallbackSql(true, "COUNT", "X", "P")
      => "COUNT(DISTINCT CASE WHEN P THEN X ELSE NULL END)" </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: on backends with FILTER support, Aggregate.as_sql wraps the base aggregate template with "%s FILTER (WHERE ...)".
  // - from_prompt: distinct=True remains valid in combination with conditional aggregation.
  claim
    <k> aggregateFilterSql(true, "COUNT", "X", "P")
      => "COUNT(DISTINCT X) FILTER (WHERE P)" </k>
    [all-path]
endmodule
