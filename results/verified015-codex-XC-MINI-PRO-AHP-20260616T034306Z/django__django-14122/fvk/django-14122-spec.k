requires "mini-django-compiler.k"

module DJANGO-14122-SPEC
  imports MINI-DJANGO-COMPILER

  // SPEC-PROVENANCE:
  // - from_prompt: "Meta.ordering fields must not be included in GROUP BY clause"
  //   => grouped metadata-only queries must have no metadata ordering contributor.
  // - from_prompt: final ORDER BY was removed but GROUP BY still received metadata
  //   => metadata must be absent before get_extra_select() and get_group_by().
  // - from_code: Query.group_by uses None as the no-grouping sentinel.
  claim
    <k> compile(query(false, true, false, true, grouped, DISTINCT:Bool, DISTINCT_FIELDS:Bool))
      => result(noSource, false, false, false, false) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code/default-domain: model Meta.ordering is the default ordering for
  //   ordinary non-grouped queries.
  // - frame condition: the grouped-query fix must not remove this behavior.
  claim
    <k> compile(query(false, true, false, true, noGroup, DISTINCT:Bool, DISTINCT_FIELDS:Bool))
      => result(metaSource, true, DISTINCT andBool notBool DISTINCT_FIELDS, false, true) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: explicit query.order_by has precedence over metadata ordering.
  // - frame condition: explicit user ordering remains active for grouped queries.
  claim
    <k> compile(query(false, DEFAULT:Bool, true, META:Bool, grouped, DISTINCT:Bool, DISTINCT_FIELDS:Bool))
      => result(explicitSource, false, false, false, true) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: extra_order_by has highest precedence.
  // - frame condition: extra ordering remains active for grouped queries.
  claim
    <k> compile(query(true, DEFAULT:Bool, QUERY:Bool, META:Bool, grouped, DISTINCT:Bool, DISTINCT_FIELDS:Bool))
      => result(extraSource, false, false, false, true) </k>
    [all-path]
endmodule
