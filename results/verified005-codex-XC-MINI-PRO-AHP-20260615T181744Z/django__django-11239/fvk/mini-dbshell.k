// Constructed abstract K semantics for the PostgreSQL dbshell proof.
// This is a property-complete model of the observable behavior under audit:
// psql args, subprocess environment, and SIGINT restoration. It is not a full
// Python semantics and has not been machine-checked in this session.

module MINI-DBSHELL-SYNTAX
  imports STRING-SYNTAX
  imports BOOL-SYNTAX
  imports MAP-SYNTAX
  imports LIST-SYNTAX

  syntax Program ::= runShellDb(Map, Map)
  syntax Result ::= result(List, Map, Bool)
  syntax List ::= buildArgs(Map) [function]
  syntax Map ::= buildEnv(Map, Map) [function]
  syntax Bool ::= restoredSigint() [function]
endmodule

module MINI-DBSHELL
  imports MINI-DBSHELL-SYNTAX
  imports MAP
  imports LIST
  imports BOOL
  imports STRING

  configuration
    <k> $PGM:Program </k>
    <args> .List </args>
    <env> .Map </env>
    <sigintRestored> false </sigintRestored>

  // SPEC MODEL:
  // runShellDb(CP, ENV0) performs the observable work of Django's
  // DatabaseClient.runshell_db(): build args, build subprocess env, and restore SIGINT.
  rule
    <k> runShellDb(CP:Map, ENV0:Map) => .K </k>
    <args> _ => buildArgs(CP) </args>
    <env> _ => buildEnv(CP, ENV0) </env>
    <sigintRestored> _ => restoredSigint() </sigintRestored>

  // The detailed equations for buildArgs/buildEnv are stated as proof obligations
  // and claims in postgresql-dbshell-spec.k, where each equation is tied to public
  // intent provenance.
endmodule
