requires "mini-tzname.k"

module MINI-TZNAME-SPEC
  imports MINI-TZNAME
  imports K-EQUAL

  // SPEC-PROVENANCE:
  // - E1/E3: `Etc/GMT-10` is a signed IANA timezone name, not a numeric offset.
  // Claim: SPLIT-NAMED-SIGNED.
  claim <k> split("Etc/GMT-10") => noDelta ... </k>
    requires notBool isOffsetTzname("Etc/GMT-10")
    [all-path]

  // SPEC-PROVENANCE:
  // - E2: fixed offsets such as +10 remain in the numeric-offset family.
  // Claim: SPLIT-OFFSET-BARE.
  claim <k> split("+10") => delta("", plus, "10") ... </k>
    requires isOffsetTzname("+10")
     andBool offsetPrefix("+10") ==String ""
     andBool offsetSign("+10") ==K plus
     andBool offsetDigits("+10") ==String "10"
    [all-path]

  // SPEC-PROVENANCE:
  // - Existing fixed-offset datetime strings are represented as UTC+HH:MM.
  // Claim: SPLIT-OFFSET-UTC.
  claim <k> split("UTC+05:00") => delta("UTC", plus, "05:00") ... </k>
    requires isOffsetTzname("UTC+05:00")
     andBool offsetPrefix("UTC+05:00") ==String "UTC"
     andBool offsetSign("UTC+05:00") ==K plus
     andBool offsetDigits("UTC+05:00") ==String "05:00"
    [all-path]

  // SPEC-PROVENANCE:
  // - E1: PostgreSQL must not reverse a sign embedded in an IANA name.
  // Claim: PG-NAMED-PRESERVE.
  claim <k> pgPrepare(TZ:String) => prepared(TZ) ... </k>
    requires notBool isOffsetTzname(TZ)
    [all-path]

  // SPEC-PROVENANCE:
  // - E2: PostgreSQL keeps its offset-literal sign reversal behavior.
  // Claim: PG-OFFSET-REVERSE.
  claim <k> pgPrepare(TZ:String) => prepared(join3(offsetPrefix(TZ), reverseSignString(offsetSign(TZ)), offsetDigits(TZ))) ... </k>
    requires isOffsetTzname(TZ)
    [all-path]

  // SPEC-PROVENANCE:
  // - E3/E4: MySQL must preserve signed IANA names as timezone names.
  // Claim: MYSQL-NAMED-PRESERVE.
  claim <k> mysqlPrepare(TZ:String) => prepared(TZ) ... </k>
    requires notBool isOffsetTzname(TZ)
    [all-path]

  // SPEC-PROVENANCE:
  // - E2: MySQL strips an optional UTC prefix for numeric fixed offsets.
  // Claim: MYSQL-ORACLE-OFFSET-STRIP-UTC.
  claim <k> mysqlPrepare(TZ:String) => prepared(join2(signString(offsetSign(TZ)), offsetDigits(TZ))) ... </k>
    requires isOffsetTzname(TZ)
    [all-path]

  // SPEC-PROVENANCE:
  // - E4: Oracle follows the named-zone path for signed IANA names.
  // Claim: ORACLE-NAMED-PRESERVE.
  claim <k> oraclePrepare(TZ:String) => prepared(TZ) ... </k>
    requires notBool isOffsetTzname(TZ)
    [all-path]

  // SPEC-PROVENANCE:
  // - E2: Oracle strips an optional UTC prefix for numeric fixed offsets.
  // Claim: MYSQL-ORACLE-OFFSET-STRIP-UTC.
  claim <k> oraclePrepare(TZ:String) => prepared(join2(signString(offsetSign(TZ)), offsetDigits(TZ))) ... </k>
    requires isOffsetTzname(TZ)
    [all-path]

  // SPEC-PROVENANCE:
  // - E5: SQLite must not split non-offset signed timezone names.
  // Claim: SQLITE-NAMED-NO-OFFSET.
  claim <k> sqliteClassify(TZ:String) => namedTimezone(TZ) ... </k>
    requires notBool isOffsetTzname(TZ)
    [all-path]

  // SPEC-PROVENANCE:
  // - E5: SQLite applies offset adjustment only for fixed-offset strings.
  // Claim: SQLITE-OFFSET-APPLY.
  claim <k> sqliteClassify(TZ:String) => offsetTimezone(offsetSign(TZ), offsetDigits(TZ), "UTC") ... </k>
    requires isOffsetTzname(TZ)
    [all-path]
endmodule
