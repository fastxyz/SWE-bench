requires "mini-django-trunc.k"

module TRUNC-TZINFO-SPEC
  imports MINI-DJANGO-TRUNC

  // SPEC-PROVENANCE:
  // - from_docs: "It has no effect when USE_TZ is False." => no SQL timezone
  //   argument when timezone support is disabled.
  claim <k> getTzName(false, TZ:TzOpt, CURRENT:String)
        => selectedTz(noSqlTz()) </k>
        [all-path]

  // SPEC-PROVENANCE:
  // - from_docs: "If it's None, Django uses the current time zone." => current
  //   timezone fallback when no explicit tzinfo is supplied.
  claim <k> getTzName(true, noTzInfo(), CURRENT:String)
        => selectedTz(sqlTz(CURRENT)) </k>
        [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "`tzinfo` object to be used when converting TruncDate" =>
  //   explicit tzinfo overrides the current timezone.
  // - conflicts: legacy implementation used current timezone unconditionally;
  //   see fvk/FINDINGS.md F1 and F2.
  claim <k> getTzName(true, someTz(EXPLICIT:String), CURRENT:String)
        => selectedTz(sqlTz(EXPLICIT)) </k>
        [all-path]

  // SPEC-PROVENANCE:
  // - from_docs: TruncDate casts expression to date.
  // - from_docs: USE_TZ false has no timezone effect.
  claim <k> truncDateAsSql(false, TZ:TzOpt, CURRENT:String, LHS:String, PARAMS:String)
        => sqlResult(castDate(LHS, noSqlTz()), PARAMS) </k>
        [all-path]

  // SPEC-PROVENANCE:
  // - from_docs: absent tzinfo uses the current timezone.
  // - from_docs: TruncDate casts expression to date.
  claim <k> truncDateAsSql(true, noTzInfo(), CURRENT:String, LHS:String, PARAMS:String)
        => sqlResult(castDate(LHS, sqlTz(CURRENT)), PARAMS) </k>
        [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: TruncDate(..., tzinfo=tz) should use the explicit timezone.
  // - from_docs: TruncDate casts expression to date.
  claim <k> truncDateAsSql(true, someTz(EXPLICIT:String), CURRENT:String, LHS:String, PARAMS:String)
        => sqlResult(castDate(LHS, sqlTz(EXPLICIT)), PARAMS) </k>
        [all-path]

  // SPEC-PROVENANCE:
  // - from_docs: TruncTime casts expression to time.
  // - from_docs: USE_TZ false has no timezone effect.
  claim <k> truncTimeAsSql(false, TZ:TzOpt, CURRENT:String, LHS:String, PARAMS:String)
        => sqlResult(castTime(LHS, noSqlTz()), PARAMS) </k>
        [all-path]

  // SPEC-PROVENANCE:
  // - from_docs: absent tzinfo uses the current timezone.
  // - from_docs: TruncTime casts expression to time.
  claim <k> truncTimeAsSql(true, noTzInfo(), CURRENT:String, LHS:String, PARAMS:String)
        => sqlResult(castTime(LHS, sqlTz(CURRENT)), PARAMS) </k>
        [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "similar issue is happening in TruncTime" => same explicit
  //   timezone override applies to the time cast.
  // - from_docs: TruncTime casts expression to time.
  claim <k> truncTimeAsSql(true, someTz(EXPLICIT:String), CURRENT:String, LHS:String, PARAMS:String)
        => sqlResult(castTime(LHS, sqlTz(EXPLICIT)), PARAMS) </k>
        [all-path]
endmodule

