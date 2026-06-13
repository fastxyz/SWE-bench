// tzconvert.k — mini-X K semantics for django__django-11138 V1 fix
// =================================================================
// CONSTRUCTED, NOT MACHINE-CHECKED (FVK MVP: no kompile/kprove run here).
//
// The V1 fix changes four straight-line helpers that build the timezone
// conversion used by date/time lookups on the tz-unaware backends:
//
//   * mysql/operations.py  : _convert_field_to_tz   -> CONVERT_TZ(field, C, T)
//   * oracle/operations.py : _convert_field_to_tz   -> FROM_TZ(field, C) AT TIME ZONE T
//   * sqlite3/operations.py: _convert_tznames_to_sql -> passes (T, C) to the funcs
//   * sqlite3/base.py      : _sqlite_datetime_parse  -> reinterpret in C, convert to T
//
// None of these contain a loop or recursion, so there is NO circularity /
// loop-invariant claim in this kit (per reachability-and-circularities.md the
// circularity machinery is for loops/recursion). What we formalize instead is
// the *function contract* of each generator: the value the generated transform
// DENOTES must equal the intended re-expression of the stored instant in the
// active Django time zone.
//
// We therefore model the small timezone ALGEBRA the code relies on as a set of
// spec-only (uninterpreted) function symbols plus their governing axioms, and
// model each generator as a function returning either an SQL term or a Wall.

module TZCONVERT-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX
  imports STRING-SYNTAX

  // ---- Time-zone algebra (spec vocabulary) ----------------------------------
  // A Wall is a naive wall-clock reading (abstracted to Int: minutes-of-epoch).
  // A Zone is an IANA name, e.g. "UTC" or "Europe/Paris".
  syntax Zone ::= String

  // instant(W, Z): the absolute UTC instant denoted by wall-clock W read in Z.
  // wallOf(I, Z): the wall-clock reading of instant I when viewed in zone Z.
  // These are total functions (every wall-clock has an instant; DST edge cases
  // are abstracted away — see FINDINGS for the one place that abstraction bites).
  syntax Inst ::= instant ( Int , Zone )   [function, functional]
  syntax Int  ::= wallOf  ( Inst , Zone )  [function, functional]

  // instReplace(W, Z): the instant produced by Python's
  //   datetime(...).replace(tzinfo=pytz.timezone(Z))
  // i.e. attaching a pytz zone WITHOUT localising. For "UTC" this equals
  // instant(W,"UTC"); for a named non-UTC zone it uses pytz's LMT offset and so
  // generally DIFFERS from instant(W, Z). This difference IS the SQLite finding.
  syntax Inst ::= instReplace ( Int , Zone ) [function, functional]

  // ---- SQL surface terms emitted by the backends ----------------------------
  // `field` is the raw stored column (a wall-clock in the connection zone C).
  // `convert(S, From, To)` models BOTH MySQL CONVERT_TZ(S, From, To) and
  // Oracle CAST(FROM_TZ(S, From) AT TIME ZONE To AS TIMESTAMP): identical
  // denotation, different surface syntax.
  syntax Sql ::= "field"
               | convert ( Sql , Zone , Zone )

  // denote(S, F, C): the Wall the database computes for SQL term S, given the
  // raw column holds stored wall-clock F in connection zone C.
  syntax Int ::= denote ( Sql , Int , Zone ) [function]

  // ---- The four generators under test ---------------------------------------
  // gen(USE, C, T): the SQL backends' _convert_field_to_tz (MySQL & Oracle have
  // identical control flow and denotation, so one model covers both).
  syntax Sql ::= gen ( Bool , Zone , Zone ) [function]

  // parse(F, C, T): the SQLite _sqlite_datetime_parse in-process computation,
  // returning the Wall that .date()/.time()/extract then read. USE_TZ=False is
  // modelled by C = "" (the NULL sentinel), USE_TZ=True by a real zone.
  syntax Int ::= parse ( Int , Zone , Zone ) [function]
endmodule

module TZCONVERT
  imports TZCONVERT-SYNTAX
  imports INT
  imports BOOL
  imports STRING

  // ===========================================================================
  // Time-zone algebra axioms (the only facts about zones the proof needs).
  // ===========================================================================

  // (RT) Round-trip: viewing an instant in the SAME zone it was read in returns
  //      the original wall-clock. Holds for every zone.
  rule wallOf(instant(W:Int, Z:Zone), Z) => W            [simplification]

  // (UTC) `.replace(tzinfo=UTC)` is exact: UTC has a fixed 0 offset, no LMT.
  rule instReplace(W:Int, "UTC") => instant(W, "UTC")    [simplification]

  // NOTE: there is deliberately NO general rule reducing instReplace(W, Z) to
  // instant(W, Z). For a named non-UTC Z they differ by pytz's LMT delta; that
  // missing rewrite is exactly what blocks a clean SQLite proof for that case
  // (see PROOF_OBLIGATIONS VC-S2 and FINDINGS F1).

  // ===========================================================================
  // Denotation of the SQL terms.
  // ===========================================================================

  // The raw column reads back the stored wall-clock F (a wall in zone C).
  rule denote(field, F:Int, _C:Zone) => F

  // CONVERT_TZ / FROM_TZ..AT TIME ZONE: re-express the inner value's instant
  // (read in `From`) as a wall-clock in `To`.
  rule denote(convert(S:Sql, From:Zone, To:Zone), F:Int, C:Zone)
    => wallOf(instant(denote(S, F, C), From), To)

  // ===========================================================================
  // The generators (the code under audit).
  // ===========================================================================

  // _convert_field_to_tz (MySQL & Oracle):
  //   USE_TZ and C != T   -> convert(field, C, T)
  //   USE_TZ and C == T   -> field                 (no CONVERT_TZ when equal)
  //   not USE_TZ          -> field
  rule gen(true,  C:Zone, T:Zone) => convert(field, C, T) requires C =/=String T
  rule gen(true,  C:Zone, T:Zone) => field               requires C  ==String T
  rule gen(false, _:Zone, _:Zone) => field

  // _sqlite_datetime_parse (SQLite), USE_TZ branch (C is a real zone):
  //   C == T : skip localtime, return stored wall F (re-tagged, wall preserved)
  //   C != T : localtime(replace(F, C), T) = wallOf(instReplace(F, C), T)
  rule parse(F:Int, C:Zone, T:Zone) => F
       requires C ==String T andBool C =/=String ""
  rule parse(F:Int, C:Zone, T:Zone) => wallOf(instReplace(F, C), T)
       requires C =/=String T andBool C =/=String ""
  // not USE_TZ (C = "" sentinel): no conversion, value returned naive.
  rule parse(F:Int, "", _:Zone) => F
endmodule
