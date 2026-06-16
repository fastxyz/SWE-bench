module MINI-TZNAME-SYNTAX
  imports STRING-SYNTAX

  syntax Sign ::= plus | minus
  syntax Delta ::= noDelta | delta(String, Sign, String)
  syntax Prepared ::= prepared(String)
  syntax SqliteMode ::= namedTimezone(String) | offsetTimezone(Sign, String, String)
  syntax KResult ::= Delta | Prepared | SqliteMode

  syntax KItem ::= split(String)
                 | pgPrepare(String)
                 | mysqlPrepare(String)
                 | oraclePrepare(String)
                 | sqliteClassify(String)
endmodule

module MINI-TZNAME
  imports MINI-TZNAME-SYNTAX
  imports STRING
  imports BOOL

  configuration <k> $PGM:K </k>

  syntax Bool ::= isOffsetTzname(String) [function]
  syntax String ::= offsetPrefix(String) [function]
  syntax Sign ::= offsetSign(String) [function]
  syntax String ::= offsetDigits(String) [function]
  syntax String ::= reverseSignString(Sign) [function]
  syntax String ::= signString(Sign) [function]
  syntax String ::= join3(String, String, String) [function]
  syntax String ::= join2(String, String) [function]

  // The implementation counterpart is the anchored regex
  // ^(UTC)?[+-]\d{2}(?::?\d{2})?$.
  rule <k> split(TZ:String) => delta(offsetPrefix(TZ), offsetSign(TZ), offsetDigits(TZ)) ... </k>
    requires isOffsetTzname(TZ)
  rule <k> split(TZ:String) => noDelta ... </k>
    requires notBool isOffsetTzname(TZ)

  rule <k> pgPrepare(TZ:String) => prepared(TZ) ... </k>
    requires notBool isOffsetTzname(TZ)
  rule <k> pgPrepare(TZ:String) => prepared(join3(offsetPrefix(TZ), reverseSignString(offsetSign(TZ)), offsetDigits(TZ))) ... </k>
    requires isOffsetTzname(TZ)

  rule <k> mysqlPrepare(TZ:String) => prepared(TZ) ... </k>
    requires notBool isOffsetTzname(TZ)
  rule <k> mysqlPrepare(TZ:String) => prepared(join2(signString(offsetSign(TZ)), offsetDigits(TZ))) ... </k>
    requires isOffsetTzname(TZ)

  rule <k> oraclePrepare(TZ:String) => prepared(TZ) ... </k>
    requires notBool isOffsetTzname(TZ)
  rule <k> oraclePrepare(TZ:String) => prepared(join2(signString(offsetSign(TZ)), offsetDigits(TZ))) ... </k>
    requires isOffsetTzname(TZ)

  rule <k> sqliteClassify(TZ:String) => namedTimezone(TZ) ... </k>
    requires notBool isOffsetTzname(TZ)
  rule <k> sqliteClassify(TZ:String) => offsetTimezone(offsetSign(TZ), offsetDigits(TZ), "UTC") ... </k>
    requires isOffsetTzname(TZ)
endmodule
