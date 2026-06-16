module MINI-PYTHON-DBSHELL-SYNTAX
  imports BOOL-SYNTAX
  imports MAP-SYNTAX
  imports STRING-SYNTAX

  syntax Value ::= "none" | String
  syntax EnvResult ::= "NoEnv" | "Env" "(" Map ")"
  syntax ProcEnv ::= "Inherit" | "Explicit" "(" Map ")"
  syntax Exp ::= "pgEnv" "(" Value "," Value "," Value "," Value "," Value "," Value "," Value ")"
               | "normalizeEnv" "(" Map ")"
               | "runshellEnv" "(" EnvResult "," Map ")"
               | "overlay" "(" Map "," Map ")" [function]
  syntax Map ::= "buildPgEnv" "(" Value "," Value "," Value "," Value "," Value "," Value "," Value ")" [function]
               | "addIfTruthy" "(" Value "," String "," Map ")" [function]
  syntax KResult ::= Value | EnvResult | ProcEnv | Map
endmodule

module MINI-PYTHON-DBSHELL
  imports MINI-PYTHON-DBSHELL-SYNTAX
  imports BOOL
  imports MAP
  imports STRING

  configuration <k> $PGM:Exp </k>

  // Truthiness fragment used by this issue: absent values are falsey and strings are truthy.
  syntax Bool ::= truthy(Value) [function]
  rule truthy(none) => false
  rule truthy(S:String) => true requires S =/=String ""

  // Helper used by the PostgreSQL client after conditionally populating env.
  rule <k> normalizeEnv(.Map) => NoEnv ... </k>
  rule <k> normalizeEnv(M:Map) => Env(M) ... </k> requires M =/=K .Map

  // PostgreSQL env construction. This mirrors the source's family of
  // add-if-truthy branches and then normalizes the resulting map.
  rule buildPgEnv(PW:Value, SERVICE:Value, SSLMODE:Value, SSLROOTCERT:Value, SSLCERT:Value, SSLKEY:Value, PASSFILE:Value)
    => addIfTruthy(PASSFILE, "PGPASSFILE",
       addIfTruthy(SSLKEY, "PGSSLKEY",
       addIfTruthy(SSLCERT, "PGSSLCERT",
       addIfTruthy(SSLROOTCERT, "PGSSLROOTCERT",
       addIfTruthy(SSLMODE, "PGSSLMODE",
       addIfTruthy(SERVICE, "PGSERVICE",
       addIfTruthy(PW, "PGPASSWORD", .Map)))))))
  rule addIfTruthy(none, KEY:String, M:Map) => M
  rule addIfTruthy(V:String, KEY:String, M:Map) => M [ KEY <- V ]
    requires truthy(V)

  rule <k> pgEnv(PW:Value, SERVICE:Value, SSLMODE:Value, SSLROOTCERT:Value, SSLCERT:Value, SSLKEY:Value, PASSFILE:Value)
      => normalizeEnv(buildPgEnv(PW, SERVICE, SSLMODE, SSLROOTCERT, SSLCERT, SSLKEY, PASSFILE)) ... </k>

  // BaseDatabaseClient.runshell() subprocess environment handoff.
  rule <k> runshellEnv(NoEnv, OS:Map) => Inherit ... </k>
  rule <k> runshellEnv(Env(.Map), OS:Map) => Inherit ... </k>
  rule <k> runshellEnv(Env(M:Map), OS:Map) => Explicit(overlay(OS, M)) ... </k>
    requires M =/=K .Map
endmodule
