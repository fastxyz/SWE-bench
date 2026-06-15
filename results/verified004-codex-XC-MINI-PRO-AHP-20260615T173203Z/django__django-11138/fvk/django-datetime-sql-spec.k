requires "mini-django-datetime-sql.k"

module DJANGO-DATETIME-SQL-SPEC
  imports MINI-DJANGO-DATETIME-SQL

  // SPEC-PROVENANCE:
  // - E5/E6: When USE_TZ is false, timezone conversion has no effect.
  claim
    <k> convert(mysql, false, F:SQL, SRC:String, TGT:String) => F </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E2/E3: Conversion from a timezone to itself is a no-op.
  // - This is the MySQL behavior required by the issue's Paris-to-Paris case.
  claim
    <k> convert(mysql, true, F:SQL, SRC:String, SRC:String) => F </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E2/E5: Conversion source is the database connection timezone, not
  //   hardcoded UTC.
  claim
    <k> convert(mysql, true, F:SQL, SRC:String, TGT:String)
      => mysqlConvert(F, SRC, TGT)
    </k>
    requires SRC =/=String TGT
    [all-path]

  // SPEC-PROVENANCE:
  // - E2/E3/E5: Oracle has the same source-to-target and no-op obligation.
  claim
    <k> convert(oracle, true, F:SQL, SRC:String, SRC:String) => F </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E2/E5: Oracle conversion source is the database connection timezone.
  claim
    <k> convert(oracle, true, F:SQL, SRC:String, TGT:String)
      => oracleConvert(F, SRC, TGT)
    </k>
    requires SRC =/=String TGT
    [all-path]

  // SPEC-PROVENANCE:
  // - E5/E6: SQLite date casting does not convert when USE_TZ is false.
  claim
    <k> sqliteDate(false, W:Wall, SRC:String, TGT:String) => datePart(W) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E2/E3: Equal SQLite source/target timezone leaves wall-clock date
  //   unchanged.
  claim
    <k> sqliteDate(true, W:Wall, SRC:String, SRC:String) => datePart(W) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E2/E5/E6: Different SQLite source/target timezone converts from
  //   connection timezone to requested timezone before returning date.
  claim
    <k> sqliteDate(true, W:Wall, SRC:String, TGT:String)
      => datePart(local(W, SRC, TGT))
    </k>
    requires SRC =/=String TGT
    [all-path]
endmodule
