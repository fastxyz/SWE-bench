module MINI-PYTHON-DBSHELL-SYNTAX
  imports STRING-SYNTAX
  imports BOOL-SYNTAX
  imports LIST-SYNTAX
  imports MAP-SYNTAX

  syntax Command ::= runshellDb(String, String, String, String, String)
  syntax Event ::= setSigint(String) | run(List, Map, Bool)
  syntax Bool ::= validConnParams(String, String, String, String, String) [function]
                | noPgpassfileMutation(Map) [function]
  syntax List ::= makePostgresArgv(String, String, String, String, String) [function]
                | addUserArg(List, String) [function]
                | addHostArg(List, String) [function]
                | addPortArg(List, String) [function]
  syntax Map ::= makePostgresEnv(Map, String) [function]
endmodule

module MINI-PYTHON-DBSHELL
  imports MINI-PYTHON-DBSHELL-SYNTAX
  imports STRING
  imports BOOL
  imports LIST
  imports MAP

  configuration
    <k> $PGM:Command </k>
    <environ> .Map </environ>
    <sigint> "SIG_DFL" </sigint>
    <events> .List </events>

  rule validConnParams(_, _, _, _, _) => true
  rule noPgpassfileMutation(_) => true

  rule makePostgresArgv(EXE, DB, USER, HOST, PORT) =>
    addPortArg(addHostArg(addUserArg(ListItem(EXE), USER), HOST), PORT)
    ListItem(DB)

  rule addUserArg(L, "") => L
  rule addUserArg(L, USER) => L ListItem("-U") ListItem(USER)
    requires USER =/=String ""

  rule addHostArg(L, "") => L
  rule addHostArg(L, HOST) => L ListItem("-h") ListItem(HOST)
    requires HOST =/=String ""

  rule addPortArg(L, "") => L
  rule addPortArg(L, PORT) => L ListItem("-p") ListItem(PORT)
    requires PORT =/=String ""

  rule makePostgresEnv(ENV, "") => ENV
  rule makePostgresEnv(ENV, PASS) => ENV [ "PGPASSWORD" <- PASS ]
    requires PASS =/=String ""

  // Abstract source-level transition for DatabaseClient.runshell_db().
  // This mini semantics records the observable events relevant to the issue:
  // signal framing and the checked subprocess.run(argv, env) call.
  rule
    <k> runshellDb(DB, USER, PASS, HOST, PORT) => .K </k>
    <environ> ENV:Map => ENV </environ>
    <sigint> SIG0:String => SIG0 </sigint>
    <events> .List =>
      ListItem(setSigint("SIG_IGN"))
      ListItem(run(
        makePostgresArgv("psql", DB, USER, HOST, PORT),
        makePostgresEnv(ENV, PASS),
        true))
      ListItem(setSigint(SIG0))
    </events>
    requires validConnParams(DB, USER, PASS, HOST, PORT)
endmodule
