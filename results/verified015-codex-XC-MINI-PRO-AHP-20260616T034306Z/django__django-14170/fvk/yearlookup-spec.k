requires "mini-django-yearlookup.k"

module MINI-DJANGO-YEARLOOKUP-SPEC
  imports MINI-DJANGO-YEARLOOKUP
  imports INT

  // SPEC-PROVENANCE:
  // - from_prompt: "__iso_year" filters return wrong data because BETWEEN used
  //   calendar-year bounds.
  // - obligation: iso-year lookup routing must produce ISO week-year bounds.
  claim
    <k> route(date, isoYear, Y:Int) => dateBounds(isoStart(Y), isoEnd(Y)) </k>
    requires 1 <=Int Y andBool Y <Int 9999
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: same issue applies to DateTimeField filters.
  // - obligation: datetime iso-year lookup must use the same ISO date interval,
  //   lifted to the first and last representable instants of that interval.
  claim
    <k> route(datetime, isoYear, Y:Int) =>
        datetimeBounds(dtStartOf(isoStart(Y)), dtEndOf(isoEnd(Y))) </k>
    requires 1 <=Int Y andBool Y <Int 9999
    [all-path]

  // SPEC-PROVENANCE:
  // - from_default_domain: Python/Django date and datetime years are bounded by
  //   datetime.MAXYEAR == 9999.
  // - obligation: computing an ISO end bound must not require year 10000.
  claim
    <k> route(date, isoYear, 9999) =>
        dateBounds(isoStart(9999), maxDate) </k>
    [all-path]

  claim
    <k> route(datetime, isoYear, 9999) =>
        datetimeBounds(dtStartOf(isoStart(9999)), maxDateTime) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code_frame: existing __year behavior is not part of the bug and must
  //   keep its calendar-year bounds.
  claim
    <k> route(date, year, Y:Int) => dateBounds(jan1(Y), dec31(Y)) </k>
    requires 1 <=Int Y andBool Y <=Int 9999
    [all-path]

  claim
    <k> route(datetime, year, Y:Int) =>
        datetimeBounds(dtStartOf(jan1(Y)), dtEndOf(dec31(Y))) </k>
    requires 1 <=Int Y andBool Y <=Int 9999
    [all-path]
endmodule
