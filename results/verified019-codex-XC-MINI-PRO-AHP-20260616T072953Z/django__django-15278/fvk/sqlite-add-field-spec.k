requires "mini-django-schema.k"

module SQLITE-ADD-FIELD-SPEC
  imports MINI-DJANGO-SCHEMA
  imports BOOL

  // SPEC-PROVENANCE:
  // - from_prompt: "Adding nullable OneToOneField crashes on SQLite" and
  //   "Cannot add a UNIQUE column" => nullable unique fields must not use the
  //   SQLite BaseAdd path.
  // - from_code: OneToOneField sets unique=True, Field.unique returns
  //   _unique or primary_key, and BaseDatabaseSchemaEditor emits inline UNIQUE.
  claim <k> addField(field(true, false, true)) => Remake ... </k> [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt/code: the issue is caused by UNIQUE, so every unique field is
  //   routed away from BaseAdd regardless of null/default.
  claim
    <k> addField(field(NULL:Bool, HASDEFAULT:Bool, true)) => Remake ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_existing_sqlite_code: non-null fields already use _remake_table()
  //   because SQLite cannot later drop an ADD COLUMN default/constraint shape.
  claim
    <k> addField(field(false, HASDEFAULT:Bool, UNIQUE:Bool)) => Remake ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_existing_sqlite_code: fields with an effective default already use
  //   _remake_table() because DROP DEFAULT is unsupported.
  claim
    <k> addField(field(NULL:Bool, true, UNIQUE:Bool)) => Remake ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - frame condition: the supported fast path remains available only when a
  //   field is nullable, has no effective default, and is not unique.
  claim <k> addField(field(true, false, false)) => BaseAdd ... </k> [all-path]
endmodule
