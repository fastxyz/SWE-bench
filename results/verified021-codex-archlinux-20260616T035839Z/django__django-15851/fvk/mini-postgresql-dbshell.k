module MINI-POSTGRESQL-DBSHELL-SYNTAX
  imports BOOL-SYNTAX
  imports LIST-SYNTAX

  syntax Arg ::= "psql"
               | "-U" | "<user>"
               | "-h" | "<host>"
               | "-p" | "<port>"
               | "<dbname>"
               | "<postgres>"

  // build(hasUser, hasHost, hasPort, hasName, hasService, parameters)
  syntax Cmd ::= build(Bool, Bool, Bool, Bool, Bool, List)

  syntax KResult ::= List
endmodule

module MINI-POSTGRESQL-DBSHELL
  imports MINI-POSTGRESQL-DBSHELL-SYNTAX
  imports BOOL
  imports LIST

  configuration <k> $PGM:Cmd </k>

  syntax List ::= userOpt(Bool) [function]
                | hostOpt(Bool) [function]
                | portOpt(Bool) [function]
                | dbArg(Bool, Bool) [function]

  rule userOpt(true)  => ListItem("-U") ListItem("<user>")
  rule userOpt(false) => .List

  rule hostOpt(true)  => ListItem("-h") ListItem("<host>")
  rule hostOpt(false) => .List

  rule portOpt(true)  => ListItem("-p") ListItem("<port>")
  rule portOpt(false) => .List

  // Mirrors Django's PostgreSQL client behavior: a configured database name is
  // positional, no name plus no service defaults to "postgres", and a service
  // with no name has no positional database argument.
  rule dbArg(true,  _:Bool) => ListItem("<dbname>")
  rule dbArg(false, false)  => ListItem("<postgres>")
  rule dbArg(false, true)   => .List

  // The audited V1 behavior: configured connection options first, extra
  // dbshell parameters next, and any positional database argument last.
  rule <k> build(HASUSER:Bool, HASHOST:Bool, HASPORT:Bool, HASNAME:Bool, HASSERVICE:Bool, PARAMS:List)
        => ListItem("psql")
           userOpt(HASUSER)
           hostOpt(HASHOST)
           portOpt(HASPORT)
           PARAMS
           dbArg(HASNAME, HASSERVICE)
       ... </k>
endmodule
