module MINI-DJANGO-SAVE-SYNTAX
  imports BOOL-SYNTAX

  syntax Query ::= "update" | "insert" | "duplicate"
  syntax Queries ::= ".Queries" | Query Queries [right]
  syntax SaveInput ::= "saveTable" "(" Bool "," Bool "," Bool "," Bool "," Bool "," Bool ")"
  syntax Decision ::= "decide" "(" Bool "," Bool "," Bool ")"
  syntax Outcome ::= "saved" "(" Bool "," Queries ")"
  syntax KResult ::= Outcome
endmodule

module MINI-DJANGO-SAVE
  imports MINI-DJANGO-SAVE-SYNTAX
  imports BOOL

  configuration <k> $PGM:SaveInput </k>

  // saveTable(Raw, ForceInsertIn, Adding, HasPkDefault, PkSet, RowExists)
  // models the _save_table() branch relevant to django__django-12209.
  rule <k> saveTable(Raw:Bool, ForceInsertIn:Bool, Adding:Bool, HasPkDefault:Bool, PkSet:Bool, RowExists:Bool)
        => decide(
             PkSet,
             ForceInsertIn orBool (
               (notBool Raw) andBool
               (notBool ForceInsertIn) andBool
               Adding andBool
               HasPkDefault
             ),
             RowExists
           )
       </k>

  rule <k> decide(true, false, true) => saved(true, update .Queries) </k>
  rule <k> decide(true, false, false) => saved(false, update insert .Queries) </k>
  rule <k> decide(true, true, true) => saved(false, duplicate .Queries) </k>
  rule <k> decide(true, true, false) => saved(false, insert .Queries) </k>
  rule <k> decide(false, IgnoredForce:Bool, IgnoredRow:Bool) => saved(false, insert .Queries) </k>
endmodule
