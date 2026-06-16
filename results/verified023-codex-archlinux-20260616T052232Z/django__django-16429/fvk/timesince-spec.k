requires "mini-timesince.k"

module MINI-TIMESINCE-SPEC
  imports MINI-TIMESINCE
  imports INT
  imports BOOL

  // SPEC-PROVENANCE:
  // - from_prompt: "pivot ... does not take into account the datetime object's tzinfo"
  //   => the month/year pivot must preserve the start datetime's timezone awareness.
  // - from_code: V1 passes tzinfo=d.tzinfo to datetime.datetime(...).
  // - from_default_domain: for Django-supported timezone-aware datetimes, copying
  //   tzinfo preserves the aware/naive subtraction class relevant to Python's
  //   "can't subtract offset-naive and offset-aware datetimes" TypeError.
  claim
    <k> pivotV1(dt(DY:Int, DM:Int, DD:Int, DH:Int, DMin:Int, DS:Int, TZ:TzState), PY:Int, PM:Int)
      => dt(PY, PM, clampDay(PM, DD), DH, DMin, DS, TZ) </k>
    requires 1 <=Int DM andBool DM <=Int 12
     andBool 1 <=Int PM andBool PM <=Int 12
     andBool 1 <=Int DD andBool DD <=Int 31
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "calling timesince() with a datetime object that's one month
  //   (or more) in the past and USE_TZ=True results in ... TypeError"
  //   => if the original now-d subtraction is well-defined, the remaining-time
  //   now-pivot subtraction must also be well-defined on the month/year branch.
  // - from_code: remaining_time = (now - pivot).total_seconds().
  claim
    <k> remainingV1(
          dt(NY:Int, NM:Int, ND:Int, NH:Int, NMin:Int, NS:Int, TZ:TzState),
          dt(DY:Int, DM:Int, DD:Int, DH:Int, DMin:Int, DS:Int, TZ),
          PY:Int,
          PM:Int
        )
      => ok </k>
    requires 1 <=Int NM andBool NM <=Int 12
     andBool 1 <=Int DM andBool DM <=Int 12
     andBool 1 <=Int PM andBool PM <=Int 12
     andBool 1 <=Int ND andBool ND <=Int 31
     andBool 1 <=Int DD andBool DD <=Int 31
    [all-path]
endmodule
