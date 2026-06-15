requires "mini-rename-contenttype.k"

module RENAME-CONTENTTYPE-SPEC
  imports MINI-RENAME-CONTENTTYPE
  imports MAP
  imports STRING
  imports BOOL

  // SPEC-PROVENANCE:
  // - from_prompt: save the content type on schema_editor.connection.alias.
  // - from_code: V1 passes using=DB to content_type.save().
  // - from_code: Model.save(using=DB) skips router.db_for_write fallback.
  claim
    <k> renameContentType(APP:String, OLD:String, NEW:String, DB:String) => .K </k>
    <allowMigrate> DB |-> true </allowMigrate>
    <contentTypes> ctKey(DB, APP, OLD) |-> OLD => ctKey(DB, APP, OLD) |-> NEW </contentTypes>
    <savedDb> "" => DB </savedDb>
    <cacheCleared> false => true </cacheCleared>
    <status> "pending" => "saved" </status>
    requires OLD =/=String NEW
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: router.allow_migrate_model(db, ContentType) false returns immediately.
  claim
    <k> renameContentType(APP:String, OLD:String, NEW:String, DB:String) => .K </k>
    <allowMigrate> DB |-> false </allowMigrate>
    <savedDb> "" => "" </savedDb>
    <cacheCleared> false => false </cacheCleared>
    <status> "pending" => "skipped-disallowed" </status>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: ContentType.DoesNotExist is caught and ignored.
  claim
    <k> renameContentType(APP:String, OLD:String, NEW:String, DB:String) => .K </k>
    <allowMigrate> DB |-> true </allowMigrate>
    <contentTypes> .Map </contentTypes>
    <savedDb> "" => "" </savedDb>
    <cacheCleared> false => false </cacheCleared>
    <status> "pending" => "missing" </status>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: pre-fix code saved on the router/default database.
  // - from_code: save(update_fields=...) supplies no using argument.
  claim
    <k> renameContentTypePreFix(APP:String, OLD:String, NEW:String, DB:String) => .K </k>
    <allowMigrate> DB |-> true </allowMigrate>
    <routerWrite> "ContentType" |-> ROUTED_DB:String </routerWrite>
    <contentTypes> ctKey(DB, APP, OLD) |-> OLD => ctKey(DB, APP, OLD) |-> NEW </contentTypes>
    <savedDb> "" => ROUTED_DB </savedDb>
    <cacheCleared> false => true </cacheCleared>
    <status> "pending" => "saved" </status>
    requires ROUTED_DB =/=String DB
    [all-path]
endmodule
