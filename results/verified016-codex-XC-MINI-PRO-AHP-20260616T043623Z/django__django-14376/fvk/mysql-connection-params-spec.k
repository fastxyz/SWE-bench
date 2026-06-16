requires "mini-python-dict.k"

module MYSQL-CONNECTION-PARAMS-SPEC
  imports MINI-PYTHON-DICT
  imports STRING
  imports BOOL
  imports MAP
  imports K-EQUAL

  // SPEC-PROVENANCE:
  // - from_prompt: "MySQL backend uses deprecated 'db' and 'passwd' kwargs."
  //   => Django-generated standard settings must not use those aliases.
  // - from_prompt: "in favor of 'database' and 'password' respectively"
  //   => NAME maps to database and PASSWORD maps to password.
  // - from_code: get_connection_params() performs straight-line dict updates
  //   and then merges OPTIONS after removing isolation_level.
  // Claim: STANDARD-CANONICAL-NAMES
  claim
    <k>
      getConnectionParams(
        "NAME" |-> val(DB:String)
        "PASSWORD" |-> val(PW:String)
        "USER" |-> none
        "HOST" |-> none
        "PORT" |-> none
        "OPTIONS" |-> options(.Map)
      )
      => PARAMS:Map
    </k>
    ensures
      valueAt(PARAMS, "database") ==K val(DB)
      andBool valueAt(PARAMS, "password") ==K val(PW)
      andBool notBool hasKey(PARAMS, "db")
      andBool notBool hasKey(PARAMS, "passwd")
    requires DB =/=String "" andBool PW =/=String ""
    [all-path]

  // SPEC-PROVENANCE:
  // - from_docs: "Connection settings are used in this order: OPTIONS, NAME,
  //   USER, PASSWORD, HOST, PORT" => canonical OPTIONS values take precedence.
  // - from_code: kwargs.update(options) occurs after standard settings mapping.
  // Claim: CANONICAL-OPTIONS-PRECEDENCE
  claim
    <k>
      getConnectionParams(
        "NAME" |-> val(DB:String)
        "PASSWORD" |-> val(PW:String)
        "USER" |-> none
        "HOST" |-> none
        "PORT" |-> none
        "OPTIONS" |->
          options("database" |-> val(ODB:String)
                  "password" |-> val(OPW:String))
      )
      => PARAMS:Map
    </k>
    ensures
      valueAt(PARAMS, "database") ==K val(ODB)
      andBool valueAt(PARAMS, "password") ==K val(OPW)
    requires DB =/=String "" andBool PW =/=String ""
     andBool ODB =/=String "" andBool OPW =/=String ""
    [all-path]

  // SPEC-PROVENANCE:
  // - from_docs: "Several other MySQLdb connection options may be useful"
  //   => OPTIONS is pass-through.
  // - from_intent_audit: rewriting user-supplied legacy aliases is broader than
  //   the public issue, which identifies Django-generated kwargs.
  // Claim: LEGACY-OPTIONS-PASSTHROUGH
  claim
    <k>
      getConnectionParams(
        "NAME" |-> val(DB:String)
        "PASSWORD" |-> val(PW:String)
        "USER" |-> none
        "HOST" |-> none
        "PORT" |-> none
        "OPTIONS" |->
          options("db" |-> val(ODB:String)
                  "passwd" |-> val(OPW:String))
      )
      => PARAMS:Map
    </k>
    ensures
      valueAt(PARAMS, "database") ==K val(DB)
      andBool valueAt(PARAMS, "password") ==K val(PW)
      andBool valueAt(PARAMS, "db") ==K val(ODB)
      andBool valueAt(PARAMS, "passwd") ==K val(OPW)
    requires DB =/=String "" andBool PW =/=String ""
     andBool ODB =/=String "" andBool OPW =/=String ""
    [all-path]
endmodule
