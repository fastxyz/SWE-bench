module MINI-DJANGO-PARENT-LINKS-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX
  imports MAP-SYNTAX

  // field(Name, RelatedModelKey, IsOneToOne, ParentLink)
  syntax Field ::= field(Int, Int, Bool, Bool)
  syntax Fields ::= ".Fields"
                  | Field ";" Fields [right]
  syntax Exp ::= collect(Fields)
               | collectAcc(Fields, Map)
  syntax KResult ::= Map
endmodule

module MINI-DJANGO-PARENT-LINKS
  imports MINI-DJANGO-PARENT-LINKS-SYNTAX
  imports INT
  imports BOOL
  imports MAP

  configuration <k> $PGM:Exp </k>

  rule <k> collect(FS:Fields) => collectAcc(FS, .Map) ... </k>
  rule <k> collectAcc(.Fields, M:Map) => M ... </k>

  // V2 behavior: only explicit parent links update the parent_links map.
  rule <k> collectAcc(field(N:Int, R:Int, true, true) ; FS, M:Map)
        => collectAcc(FS, M [R <- N])
        ... </k>
  rule <k> collectAcc(field(N:Int, R:Int, true, false) ; FS, M:Map)
        => collectAcc(FS, M)
        ... </k>
  rule <k> collectAcc(field(N:Int, R:Int, false, PL:Bool) ; FS, M:Map)
        => collectAcc(FS, M)
        ... </k>
endmodule
