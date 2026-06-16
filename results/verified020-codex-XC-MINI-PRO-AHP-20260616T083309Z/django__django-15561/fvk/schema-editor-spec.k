requires "mini-schema-editor.k"

module SCHEMA-EDITOR-SPEC
  imports MINI-SCHEMA-EDITOR
  imports BOOL
  imports STRING

  // SPEC-PROVENANCE:
  // - from_prompt: "AlterField operation should be noop when adding/changing
  //   choices on SQLite." => SQLite ignores choices-only differences.
  // - from_prompt: global choices ignoring could regress third-party enum
  //   fields => base behavior still treats choices as alteration-relevant.
  // - from_code: V2 represents this as a private ignored-attribute tuple on
  //   BaseDatabaseSchemaEditor, extended only by sqlite3.DatabaseSchemaEditor.

  // Claim: BASE-CHOICES-STILL-ALTERS
  claim
    <k> shouldAlter(
          base,
          field(C:String, P:String, A:String, K:String, OLD_CHOICES:String),
          field(C:String, P:String, A:String, K:String, NEW_CHOICES:String)
        ) => true </k>
    requires OLD_CHOICES =/=String NEW_CHOICES
    [all-path]

  // Claim: SQLITE-CHOICES-NOOP
  claim
    <k> shouldAlter(
          sqlite,
          field(C:String, P:String, A:String, K:String, OLD_CHOICES:String),
          field(C:String, P:String, A:String, K:String, NEW_CHOICES:String)
        ) => false </k>
    requires OLD_CHOICES =/=String NEW_CHOICES
    [all-path]

  // Claim: SQLITE-SCHEMA-ATTR-STILL-ALTERS
  claim
    <k> shouldAlter(
          sqlite,
          field(C:String, P:String, A:String, OLD_K:String, OLD_CHOICES:String),
          field(C:String, P:String, A:String, NEW_K:String, NEW_CHOICES:String)
        ) => true </k>
    requires OLD_K =/=String NEW_K
    [all-path]

  // Claim: SQLITE-COLUMN-STILL-ALTERS
  claim
    <k> shouldAlter(
          sqlite,
          field(OLD_C:String, P:String, A:String, K:String, OLD_CHOICES:String),
          field(NEW_C:String, P:String, A:String, K:String, NEW_CHOICES:String)
        ) => true </k>
    requires OLD_C =/=String NEW_C
    [all-path]
endmodule
