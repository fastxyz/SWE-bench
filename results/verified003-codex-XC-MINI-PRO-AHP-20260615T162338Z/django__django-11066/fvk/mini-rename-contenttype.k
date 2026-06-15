module MINI-RENAME-CONTENTTYPE-SYNTAX
  imports STRING-SYNTAX
  imports BOOL-SYNTAX

  syntax CKey ::= ctKey(String, String, String)
  syntax Command ::= renameContentType(String, String, String, String)
                   | renameContentTypePreFix(String, String, String, String)
                   | saveUsing(String, CKey, String)
                   | saveViaRouter(CKey, String)
                   | conflict
                   | clearCache
endmodule

module MINI-RENAME-CONTENTTYPE
  imports MINI-RENAME-CONTENTTYPE-SYNTAX
  imports STRING
  imports BOOL
  imports MAP

  configuration
    <k> $PGM:Command </k>
    <contentTypes> .Map </contentTypes>
    <allowMigrate> .Map </allowMigrate>
    <routerWrite> .Map </routerWrite>
    <savedDb> "" </savedDb>
    <cacheCleared> false </cacheCleared>
    <status> "pending" </status>

  // Migration disallowed: no lookup, no save.
  rule
    <k> renameContentType(APP, OLD, NEW, DB) => .K </k>
    <allowMigrate> ... DB |-> false ... </allowMigrate>
    <savedDb> _ => "" </savedDb>
    <status> _ => "skipped-disallowed" </status>

  // Missing old row on the migration database: no-op.
  rule
    <k> renameContentType(APP, OLD, NEW, DB) => .K </k>
    <allowMigrate> ... DB |-> true ... </allowMigrate>
    <contentTypes> CTS </contentTypes>
    <savedDb> _ => "" </savedDb>
    <status> _ => "missing" </status>
    requires notBool (ctKey(DB, APP, OLD) in_keys(CTS))

  // V1 successful path: explicit save target is DB.
  rule
    <k> renameContentType(APP, OLD, NEW, DB) => saveUsing(DB, ctKey(DB, APP, OLD), NEW) ~> clearCache </k>
    <allowMigrate> ... DB |-> true ... </allowMigrate>
    <contentTypes> CTS </contentTypes>
    requires ctKey(DB, APP, OLD) in_keys(CTS)

  rule
    <k> saveUsing(DB, KEY, NEW) => .K </k>
    <contentTypes> CTS => CTS [ KEY <- NEW ] </contentTypes>
    <savedDb> _ => DB </savedDb>
    <status> _ => "saved" </status>

  rule
    <k> clearCache => .K </k>
    <cacheCleared> _ => true </cacheCleared>

  // Conflict path, abstracting the database IntegrityError as a command.
  rule
    <k> conflict => .K </k>
    <status> _ => "conflict-restored-old-model" </status>

  // Pre-fix path: save target comes from routerWrite instead of DB.
  rule
    <k> renameContentTypePreFix(APP, OLD, NEW, DB) => saveViaRouter(ctKey(DB, APP, OLD), NEW) ~> clearCache </k>
    <allowMigrate> ... DB |-> true ... </allowMigrate>
    <contentTypes> CTS </contentTypes>
    requires ctKey(DB, APP, OLD) in_keys(CTS)

  rule
    <k> saveViaRouter(KEY, NEW) => .K </k>
    <routerWrite> ... "ContentType" |-> ROUTED_DB:String ... </routerWrite>
    <contentTypes> CTS => CTS [ KEY <- NEW ] </contentTypes>
    <savedDb> _ => ROUTED_DB </savedDb>
    <status> _ => "saved" </status>
endmodule
