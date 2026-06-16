requires "mini-python-dbshell.k"

module DBSHELL-ENV-SPEC
  imports MINI-PYTHON-DBSHELL
  imports MAP
  imports STRING

  // SPEC-PROVENANCE:
  // - E2: "postgresql client returns empty dict instead of None for env"
  //   => no PostgreSQL env overrides must produce NoEnv/Python None.
  claim
    <k> pgEnv(none, none, none, none, none, none, none) => NoEnv </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E3/E8: PostgreSQL env settings must still be returned when present.
  claim
    <k> pgEnv(PW:String, none, none, none, none, none, none)
      => Env("PGPASSWORD" |-> PW) </k>
    requires PW =/=String ""
    [all-path]

  // SPEC-PROVENANCE:
  // - E3/E8: the full PostgreSQL env family is normalized uniformly.
  claim
    <k> pgEnv(PW:Value, SERVICE:Value, SSLMODE:Value, SSLROOTCERT:Value, SSLCERT:Value, SSLKEY:Value, PASSFILE:Value)
      => Env(buildPgEnv(PW, SERVICE, SSLMODE, SSLROOTCERT, SSLCERT, SSLKEY, PASSFILE)) </k>
    requires buildPgEnv(PW, SERVICE, SSLMODE, SSLROOTCERT, SSLCERT, SSLKEY, PASSFILE) =/=K .Map
    [all-path]

  // SPEC-PROVENANCE:
  // - E1/E3: backend NoEnv must let subprocess inherit os.environ.
  claim
    <k> runshellEnv(NoEnv, OS:Map) => Inherit </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E1/E3/E7: backend Env(.Map) must not be passed to subprocess as
  //   an explicit empty environment.
  claim
    <k> runshellEnv(Env(.Map), OS:Map) => Inherit </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E4/E7: non-empty env overrides are merged into os.environ.
  claim
    <k> runshellEnv(Env(M:Map), OS:Map) => Explicit(overlay(OS, M)) </k>
    requires M =/=K .Map
    [all-path]
endmodule
