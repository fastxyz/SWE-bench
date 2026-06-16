requires "mini-postgresql-dbshell.k"

module POSTGRESQL-DBSHELL-SPEC
  imports MINI-POSTGRESQL-DBSHELL

  // SPEC-PROVENANCE:
  // - from_prompt: "dbshell additional parameters should be passed before dbname on PostgreSQL."
  //   => If NAME is provided, PARAMS must precede the positional dbname.
  // - from_prompt: "leaving the database name for the end of the args list."
  //   => The positional dbname must be the final argument after PARAMS.
  // - from_code: user/host/port options are constructed before PARAMS and are unchanged by V1.
  claim
    <k> build(HASUSER:Bool, HASHOST:Bool, HASPORT:Bool, true, HASSERVICE:Bool, PARAMS:List)
        => ListItem("psql")
           userOpt(HASUSER)
           hostOpt(HASHOST)
           portOpt(HASPORT)
           PARAMS
           ListItem("<dbname>")
      ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: PostgreSQL options must precede the database name if one is provided.
  // - from_code: when NAME and service are absent, Django selects the default "postgres"
  //   database, which is still a positional database argument.
  claim
    <k> build(HASUSER:Bool, HASHOST:Bool, HASPORT:Bool, false, false, PARAMS:List)
        => ListItem("psql")
           userOpt(HASUSER)
           hostOpt(HASHOST)
           portOpt(HASPORT)
           PARAMS
           ListItem("<postgres>")
      ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code and public tests: when a service is configured and NAME is absent,
  //   Django passes the service through PGSERVICE and does not add a positional dbname.
  // - frame condition: V1 must not invent a dbname in this branch.
  claim
    <k> build(HASUSER:Bool, HASHOST:Bool, HASPORT:Bool, false, true, PARAMS:List)
        => ListItem("psql")
           userOpt(HASUSER)
           hostOpt(HASHOST)
           portOpt(HASPORT)
           PARAMS
      ... </k>
    [all-path]
endmodule
