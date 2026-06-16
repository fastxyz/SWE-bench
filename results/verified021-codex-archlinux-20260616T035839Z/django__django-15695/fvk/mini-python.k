requires "domains.md"

module MINI-PYTHON-SYNTAX
  imports STRING-SYNTAX
  imports BOOL-SYNTAX

  syntax Fields ::= fields(String, String)
  syntax Model ::= model(String, String, Fields)
  syntax Db ::= db(String) | error(String)
  syntax KItem ::= forwardOldFields(Model, String, Bool)
                 | reverseOldFields(Model, String, Bool)

  syntax String ::= generatedIdxName(String, Fields) [function]
  syntax Db ::= renameDb(Db, String, String) [function]
endmodule

module MINI-PYTHON
  imports MINI-PYTHON-SYNTAX
  imports STRING
  imports BOOL

  configuration <k> $PGM:K </k>
                <db> db("") </db>

  // Model of schema_editor.rename_index() on the only observable needed here:
  // which index name exists in the database.
  rule renameDb(db(OLD), OLD, NEW) => db(NEW)
  rule renameDb(db(CURRENT), OLD, NEW) => error("missing-old-index")
    requires CURRENT =/=K OLD
  rule renameDb(error(E), _OLD, _NEW) => error(E)

  // Forward old_fields path after state_forwards(): unnamed index -> new name.
  rule <k> forwardOldFields(model(TABLE, _MODEL, FIELDS), NEW, true) => .K </k>
       <db> DB => renameDb(DB, generatedIdxName(TABLE, FIELDS), NEW) </db>

  // Backward old_fields path in V1: new name -> generated old index name.
  rule <k> reverseOldFields(model(TABLE, _MODEL, FIELDS), NEW, true) => .K </k>
       <db> DB => renameDb(DB, NEW, generatedIdxName(TABLE, FIELDS)) </db>

  // allow_migrate_model() false: preserve existing database state.
  rule <k> forwardOldFields(_MODEL, _NEW, false) => .K </k>
  rule <k> reverseOldFields(_MODEL, _NEW, false) => .K </k>
endmodule
