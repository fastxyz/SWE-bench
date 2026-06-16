module MINI-CATEGORY-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX

  syntax Warning ::= "deprecatedNumeric"
  syntax LogMsg  ::= "allConvertible"
  syntax Status  ::= "ok" | "typeError"

  // convert(N, AllNumlike, UpdateAccepts)
  syntax Pgm ::= "convert" "(" Int "," Bool "," Bool ")"
               | "update" "(" Int "," Bool ")"

  syntax KResult ::= Int | Bool | Warning | LogMsg | Status
endmodule

module MINI-CATEGORY
  imports MINI-CATEGORY-SYNTAX
  imports INT
  imports BOOL
  imports LIST

  configuration
    <k> $PGM:Pgm </k>
    <warnings> .List </warnings>
    <logs> .List </logs>
    <resultSize> 0 </resultSize>
    <status> ok </status>

  // Non-empty numeric-like data follows the deprecated numeric pass-through.
  rule
    <k> convert(N:Int, true, UPDATEOK:Bool) => .K </k>
    <warnings> WS => ListItem(deprecatedNumeric) WS </warnings>
    <resultSize> _ => N </resultSize>
    <status> _ => ok </status>
    requires N >Int 0

  // Empty data falls through categorical conversion and produces an empty
  // converted result. UPDATEOK is true for the empty sequence because no
  // element can fail UnitData.update validation.
  rule
    <k> convert(0, true, true) => .K </k>
    <resultSize> _ => 0 </resultSize>
    <status> _ => ok </status>

  rule
    <k> convert(0, false, true) => .K </k>
    <resultSize> _ => 0 </resultSize>
    <status> _ => ok </status>

  // Non-empty categorical data accepted by UnitData.update maps one output per
  // input and emits no numeric pass-through warning.
  rule
    <k> convert(N:Int, false, true) => .K </k>
    <resultSize> _ => N </resultSize>
    <status> _ => ok </status>
    requires N >Int 0

  // Invalid non-empty categorical data is still rejected by UnitData.update.
  rule
    <k> convert(N:Int, false, false) => .K </k>
    <status> _ => typeError </status>
    requires N >Int 0

  // Empty update must not log "all convertible" merely by vacuous truth.
  rule
    <k> update(0, true) => .K </k>
    <status> _ => ok </status>

  rule
    <k> update(0, false) => .K </k>
    <status> _ => ok </status>

  // Non-empty all-convertible update preserves the existing informational log.
  rule
    <k> update(N:Int, true) => .K </k>
    <logs> LS => ListItem(allConvertible) LS </logs>
    <status> _ => ok </status>
    requires N >Int 0

  rule
    <k> update(N:Int, false) => .K </k>
    <status> _ => ok </status>
    requires N >Int 0
endmodule
