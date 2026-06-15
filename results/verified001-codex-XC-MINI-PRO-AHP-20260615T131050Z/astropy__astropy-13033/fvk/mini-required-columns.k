module MINI-REQUIRED-COLUMNS-SYNTAX
  imports BOOL-SYNTAX
  imports INT-SYNTAX
  imports STRING-SYNTAX

  syntax Cols ::= ".Cols"
                | String "::" Cols

  syntax ReqOpt ::= "none"
                  | "some" "(" Cols ")"

  syntax Result ::= "ok" "(" Bool ")"
                  | "error" "(" String ")"

  syntax Exp ::= "check" "(" String "," Bool "," ReqOpt "," Bool "," Cols ")"

  syntax Cols ::= "activeReq" "(" Cols "," Bool "," Cols ")" [function]
                | "take" "(" Cols "," Int ")" [function]

  syntax Int ::= "size" "(" Cols ")" [function]

  syntax String ::= "head" "(" Cols ")" [function]
                  | "colsString" "(" Cols ")" [function]
                  | "colsTailString" "(" Cols ")" [function]
                  | "singleNoColumns" "(" String "," String ")" [function]
                  | "multiNoColumns" "(" String "," Cols ")" [function]
                  | "singleFound" "(" String "," String "," String ")" [function]
                  | "multiFound" "(" String "," Cols "," Cols ")" [function]

  syntax KResult ::= Result
endmodule

module MINI-REQUIRED-COLUMNS
  imports MINI-REQUIRED-COLUMNS-SYNTAX
  imports BOOL
  imports INT
  imports K-EQUAL
  imports STRING

  configuration <k> $PGM:Exp </k>

  rule activeReq(REQ, false, COLS) => REQ
  rule activeReq(REQ, true, COLS) => take(REQ, size(COLS))

  rule size(.Cols) => 0
  rule size(COL :: REST) => 1 +Int size(REST)

  rule take(.Cols, N) => .Cols requires N <=Int 0
  rule take(COL :: REST, N) => .Cols requires N <=Int 0
  rule take(.Cols, N) => .Cols requires N >Int 0
  rule take(COL :: REST, N) => COL :: take(REST, N -Int 1) requires N >Int 0

  rule head(COL :: REST) => COL

  rule colsString(.Cols) => "[]"
  rule colsString(COL :: REST)
    => "['" +String COL +String "'" +String colsTailString(REST) +String "]"

  rule colsTailString(.Cols) => ""
  rule colsTailString(COL :: REST)
    => ", '" +String COL +String "'" +String colsTailString(REST)

  rule singleNoColumns(C, REQ)
    => C +String " object is invalid - expected '" +String REQ
       +String "' as the first column but time series has no columns"

  rule multiNoColumns(C, REQ)
    => C +String " object is invalid - required " +String colsString(REQ)
       +String " as the first columns but time series has no columns"

  rule singleFound(C, REQ, FOUND)
    => C +String " object is invalid - expected '" +String REQ
       +String "' as the first column but found '" +String FOUND +String "'"

  rule multiFound(C, REQ, FOUND)
    => C +String " object is invalid - required " +String colsString(REQ)
       +String " as the first columns but found " +String colsString(FOUND)

  rule <k> check(C, false, REQ, RELAX, COLS) => ok(RELAX) </k>
  rule <k> check(C, true, none, RELAX, COLS) => ok(RELAX) </k>

  rule <k> check(C, true, some(REQ), false, .Cols)
        => error(singleNoColumns(C, head(REQ))) </k>
    requires size(REQ) ==Int 1

  rule <k> check(C, true, some(REQ), false, .Cols)
        => error(multiNoColumns(C, REQ)) </k>
    requires size(REQ) >Int 1

  rule <k> check(C, true, some(REQ), RELAX, COLS)
        => error(singleFound(C, head(activeReq(REQ, RELAX, COLS)), head(COLS))) </k>
    requires size(activeReq(REQ, RELAX, COLS)) ==Int 1
     andBool take(COLS, size(activeReq(REQ, RELAX, COLS))) =/=K activeReq(REQ, RELAX, COLS)

  rule <k> check(C, true, some(REQ), RELAX, COLS)
        => error(multiFound(C, activeReq(REQ, RELAX, COLS),
                            take(COLS, size(activeReq(REQ, RELAX, COLS))))) </k>
    requires size(activeReq(REQ, RELAX, COLS)) >Int 1
     andBool take(COLS, size(activeReq(REQ, RELAX, COLS))) =/=K activeReq(REQ, RELAX, COLS)

  rule <k> check(C, true, some(REQ), RELAX, COLS)
        => ok(RELAX andBool notBool (REQ ==K take(COLS, size(REQ)))) </k>
    requires take(COLS, size(activeReq(REQ, RELAX, COLS))) ==K activeReq(REQ, RELAX, COLS)
     andBool notBool (notBool RELAX andBool size(COLS) ==Int 0)
endmodule
