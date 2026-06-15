requires "mini-python-dbshell.k"

module POSTGRESQL-CLIENT-SPEC
  imports MINI-PYTHON-DBSHELL
  imports STRING
  imports BOOL
  imports LIST
  imports MAP

  // SPEC-PROVENANCE:
  // - SPEC E1/E2/E3: use subprocess.run with PGPASSWORD in a custom env.
  // - SPEC E4/E5: preserve psql argv construction.
  // - SPEC E7: preserve SIGINT ignore/restore.
  claim
    <k> runshellDb(DB:String, USER:String, PASS:String, HOST:String, PORT:String) => .K </k>
    <environ> ENV0:Map => ENV0 </environ>
    <sigint> SIG0:String => SIG0 </sigint>
    <events> .List =>
      ListItem(setSigint("SIG_IGN"))
      ListItem(run(
        makePostgresArgv("psql", DB, USER, HOST, PORT),
        makePostgresEnv(ENV0, PASS),
        true))
      ListItem(setSigint(SIG0))
    </events>
    requires validConnParams(DB, USER, PASS, HOST, PORT)
    ensures noPgpassfileMutation(ENV0)
    [all-path]
endmodule
