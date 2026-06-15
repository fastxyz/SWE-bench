module MINI-MODEL-FORM-SYNTAX
  imports BOOL-SYNTAX
  imports ID-SYNTAX

  syntax Val ::= empty | nonEmpty
  syntax Action ::= skip
                  | assign "(" Id "," Val ")"
                  | queueFile "(" Id "," Val ")"

  // field(name, editable, isAuto, inCleaned, fieldsAllowed, excluded,
  //       hasDefault, omittedFromData, cleanedEmpty, isFile, cleanedValue)
  syntax FieldState ::= field "(" Id "," Bool "," Bool "," Bool "," Bool "," Bool ","
                             Bool "," Bool "," Bool "," Bool "," Val ")"

  syntax KItem ::= decide "(" FieldState ")"
  syntax KResult ::= Action
endmodule

module MINI-MODEL-FORM
  imports MINI-MODEL-FORM-SYNTAX
  imports BOOL

  configuration <k> $PGM:K </k>

  rule <k> decide(field(N, false, AUTO, INCD, FOK, EXCL, DEF, OMIT, EMP, FILE, V)) => skip ... </k>
  rule <k> decide(field(N, true, true, INCD, FOK, EXCL, DEF, OMIT, EMP, FILE, V)) => skip ... </k>
  rule <k> decide(field(N, true, false, false, FOK, EXCL, DEF, OMIT, EMP, FILE, V)) => skip ... </k>
  rule <k> decide(field(N, true, false, true, false, EXCL, DEF, OMIT, EMP, FILE, V)) => skip ... </k>
  rule <k> decide(field(N, true, false, true, true, true, DEF, OMIT, EMP, FILE, V)) => skip ... </k>

  // V1 default-preservation rule:
  // only the conjunction hasDefault && omittedFromData && cleanedEmpty skips.
  rule <k> decide(field(N, true, false, true, true, false, true, true, true, FILE, V)) => skip ... </k>

  rule <k> decide(field(N, true, false, true, true, false, DEF, OMIT, EMP, false, V))
        => assign(N, V) ... </k>
    requires notBool (DEF andBool OMIT andBool EMP)

  rule <k> decide(field(N, true, false, true, true, false, DEF, OMIT, EMP, true, V))
        => queueFile(N, V) ... </k>
    requires notBool (DEF andBool OMIT andBool EMP)
endmodule
