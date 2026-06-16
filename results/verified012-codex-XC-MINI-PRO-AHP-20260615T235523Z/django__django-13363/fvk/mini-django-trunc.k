module MINI-DJANGO-TRUNC-SYNTAX
  imports BOOL-SYNTAX
  imports STRING-SYNTAX

  syntax TzOpt ::= noTzInfo() | someTz(String)
  syntax TzArg ::= noSqlTz() | sqlTz(String)
  syntax Kind ::= dateKind() | timeKind()
  syntax SQL ::= castDate(String, TzArg) | castTime(String, TzArg)
  syntax Result ::= selectedTz(TzArg) | sqlResult(SQL, String)

  syntax Exp ::= getTzName(Bool, TzOpt, String)
               | truncDateAsSql(Bool, TzOpt, String, String, String)
               | truncTimeAsSql(Bool, TzOpt, String, String, String)

  syntax KResult ::= Result
endmodule

module MINI-DJANGO-TRUNC
  imports MINI-DJANGO-TRUNC-SYNTAX
  imports BOOL
  imports STRING

  configuration <k> $PGM:Exp </k>

  // TimezoneMixin.get_tzname().
  rule <k> getTzName(false, TZ:TzOpt, CURRENT:String) => selectedTz(noSqlTz()) </k>
  rule <k> getTzName(true, noTzInfo(), CURRENT:String) => selectedTz(sqlTz(CURRENT)) </k>
  rule <k> getTzName(true, someTz(EXPLICIT:String), CURRENT:String) => selectedTz(sqlTz(EXPLICIT)) </k>

  // TruncDate.as_sql(), abstracting compiler.compile(self.lhs) as (LHS, PARAMS)
  // and backend SQL rendering as castDate(LHS, TZARG).
  rule <k> truncDateAsSql(false, TZ:TzOpt, CURRENT:String, LHS:String, PARAMS:String)
        => sqlResult(castDate(LHS, noSqlTz()), PARAMS) </k>
  rule <k> truncDateAsSql(true, noTzInfo(), CURRENT:String, LHS:String, PARAMS:String)
        => sqlResult(castDate(LHS, sqlTz(CURRENT)), PARAMS) </k>
  rule <k> truncDateAsSql(true, someTz(EXPLICIT:String), CURRENT:String, LHS:String, PARAMS:String)
        => sqlResult(castDate(LHS, sqlTz(EXPLICIT)), PARAMS) </k>

  // TruncTime.as_sql(), with the same timezone-selection contract and an
  // abstract backend castTime(LHS, TZARG).
  rule <k> truncTimeAsSql(false, TZ:TzOpt, CURRENT:String, LHS:String, PARAMS:String)
        => sqlResult(castTime(LHS, noSqlTz()), PARAMS) </k>
  rule <k> truncTimeAsSql(true, noTzInfo(), CURRENT:String, LHS:String, PARAMS:String)
        => sqlResult(castTime(LHS, sqlTz(CURRENT)), PARAMS) </k>
  rule <k> truncTimeAsSql(true, someTz(EXPLICIT:String), CURRENT:String, LHS:String, PARAMS:String)
        => sqlResult(castTime(LHS, sqlTz(EXPLICIT)), PARAMS) </k>
endmodule

