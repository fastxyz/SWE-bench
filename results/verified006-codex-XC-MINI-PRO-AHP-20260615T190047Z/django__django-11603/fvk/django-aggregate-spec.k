requires "mini-django-aggregate.k"

module DJANGO-AGGREGATE-SPEC
  imports MINI-DJANGO-AGGREGATE

  // SPEC-PROVENANCE:
  // - from_prompt: "Add DISTINCT support for Avg and Sum aggregates." =>
  //   Avg(..., distinct=True) is in-domain and must not raise merely because
  //   distinct is true.
  // - from_code: Aggregate.__init__ raises only when distinct is true and
  //   allow_distinct is false.
  claim <k> init(Avg, true) => Obj(true) </k> [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "Add DISTINCT support for Avg and Sum aggregates." =>
  //   Sum(..., distinct=True) is in-domain and must not raise merely because
  //   distinct is true.
  // - from_code: Aggregate.__init__ raises only when distinct is true and
  //   allow_distinct is false.
  claim <k> init(Sum, true) => Obj(true) </k> [all-path]

  // SPEC-PROVENANCE:
  // - from_docs: Aggregate.distinct "should be invoked for each distinct value"
  //   when the aggregate allows distinct.
  // - from_code: Aggregate.as_sql writes the distinct SQL context from
  //   self.distinct before delegating to Func.as_sql.
  claim <k> asSql("AVG", true, E:String) => Sql("AVG(DISTINCT " +String E +String ")") </k> [all-path]

  // SPEC-PROVENANCE:
  // - from_docs: Aggregate.distinct "should be invoked for each distinct value"
  //   when the aggregate allows distinct.
  // - from_code: Aggregate.as_sql writes the distinct SQL context from
  //   self.distinct before delegating to Func.as_sql.
  claim <k> asSql("SUM", true, E:String) => Sql("SUM(DISTINCT " +String E +String ")") </k> [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "could also be applied to Min and Max (although pointless)"
  //   is optional evidence, not a required behavior.
  // - from_code: unchanged aggregate subclasses inherit allow_distinct = false.
  claim <k> init(Max, true) => TypeError("does not allow distinct") </k> [all-path]
  claim <k> init(Min, true) => TypeError("does not allow distinct") </k> [all-path]
endmodule
