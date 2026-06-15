requires "mini-dbshell.k"

module POSTGRESQL-DBSHELL-SPEC
  imports MINI-DBSHELL
  imports K-EQUAL
  imports MAP
  imports LIST
  imports STRING
  imports BOOL

  // SPEC-PROVENANCE:
  // - E1/E2/E3: issue requires dbshell support for sslmode, server certificate,
  //   client certificate, and client key.
  // - E4: get_connection_params() forwards OPTIONS into conn_params.
  // - E5: existing args/password behavior is preserved as a frame condition.
  //
  // Constructed, not machine-checked. The helper functions expectedArgs and
  // expectedEnv are abstract spec functions whose equations are enumerated in
  // PROOF_OBLIGATIONS.md.
  syntax List ::= expectedArgs(Map) [function]
  syntax Map ::= expectedEnv(Map, Map) [function]

  claim [DBSHELL-SSL-ENV]:
    <k> runShellDb(CP:Map, ENV0:Map) => .K </k>
    <args> .List => expectedArgs(CP) </args>
    <env> .Map => expectedEnv(CP, ENV0) </env>
    <sigintRestored> false => true </sigintRestored>
    requires true
    [all-path]

  // Expected environment equations, mirrored from PROOF_OBLIGATIONS.md:
  // - if CP["password"] is present/non-empty, expectedEnv has PGPASSWORD=str(CP["password"])
  // - if CP["sslmode"] is present/non-empty, expectedEnv has PGSSLMODE=str(CP["sslmode"])
  // - if CP["sslrootcert"] is present/non-empty, expectedEnv has PGSSLROOTCERT=str(CP["sslrootcert"])
  // - if CP["sslcert"] is present/non-empty, expectedEnv has PGSSLCERT=str(CP["sslcert"])
  // - if CP["sslkey"] is present/non-empty, expectedEnv has PGSSLKEY=str(CP["sslkey"])
  // - all unrelated environment bindings are framed from ENV0.

  // Expected argument equations, mirrored from PROOF_OBLIGATIONS.md:
  // expectedArgs(CP) = ["psql"] ++ optional ["-U", user] ++ optional ["-h", host]
  //                  ++ optional ["-p", str(port)] ++ [database].
endmodule
