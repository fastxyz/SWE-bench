module MINI-DJANGO-DATETIME-SQL-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX
  imports STRING-SYNTAX

  syntax Backend ::= "mysql" | "oracle" | "sqlite"
  syntax SQL ::= raw(String)
               | mysqlConvert(SQL, String, String)
               | oracleConvert(SQL, String, String)
  syntax Wall ::= wall(Int, Int, Int, Int, Int, Int)
  syntax Date ::= date(Int, Int, Int)
  syntax Cmd ::= convert(Backend, Bool, SQL, String, String)
               | sqliteDate(Bool, Wall, String, String)
               | datePart(Wall) [function]
               | local(Wall, String, String) [function]

  syntax KResult ::= SQL | Date | Wall
endmodule

module MINI-DJANGO-DATETIME-SQL
  imports MINI-DJANGO-DATETIME-SQL-SYNTAX
  imports INT
  imports BOOL
  imports STRING

  configuration <k> $PGM:Cmd </k>

  rule <k> convert(B:Backend, false, F:SQL, SRC:String, TGT:String) => F </k>
  rule <k> convert(B:Backend, true, F:SQL, SRC:String, TGT:String) => F </k>
    requires SRC ==String TGT

  rule <k> convert(mysql, true, F:SQL, SRC:String, TGT:String)
        => mysqlConvert(F, SRC, TGT)
       </k>
    requires SRC =/=String TGT

  rule <k> convert(oracle, true, F:SQL, SRC:String, TGT:String)
        => oracleConvert(F, SRC, TGT)
       </k>
    requires SRC =/=String TGT

  rule datePart(wall(Y:Int, M:Int, D:Int, H:Int, MI:Int, S:Int))
    => date(Y, M, D)

  rule <k> sqliteDate(false, W:Wall, SRC:String, TGT:String)
        => datePart(W)
       </k>

  rule <k> sqliteDate(true, W:Wall, SRC:String, TGT:String)
        => datePart(W)
       </k>
    requires SRC ==String TGT

  rule <k> sqliteDate(true, W:Wall, SRC:String, TGT:String)
        => datePart(local(W, SRC, TGT))
       </k>
    requires SRC =/=String TGT
endmodule
