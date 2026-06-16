requires "mini-django-migrations.k"

module RENAME-MODEL-SPEC
  imports MINI-DJANGO-MIGRATIONS
  imports K-EQUAL
  imports INT
  imports BOOL

  // SPEC-PROVENANCE:
  // - from_prompt: "RenameModel with db_table should be a noop."
  // - from_prompt: reported PostgreSQL/SQLite side effects are unintended.
  // - from_code: SameTable abstracts old_db_table == new_db_table or backend case-insensitive equality.
  claim [RENAME-MODEL-NOOP-SAME-TABLE]:
    <k> renameModelForwards(true, true, R:Int, M:Int) => done </k>
    <dbops> OPS:Int => OPS </dbops>
    requires R >=Int 0 andBool M >=Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: allow_migrate_model() guards all database side effects.
  claim [RENAME-MODEL-NOOP-DISALLOWED]:
    <k> renameModelForwards(false, SAME:Bool, R:Int, M:Int) => done </k>
    <dbops> OPS:Int => OPS </dbops>
    requires R >=Int 0 andBool M >=Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: the related-object loop emits one alter_field operation per related object.
  claim [RELATED-COUNT]:
    <k> emitRelated(R:Int) => done </k>
    <dbops> OPS:Int => OPS +Int R </dbops>
    requires R >=Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: each applicable local M2M entry emits alter_db_table and alter_field.
  claim [M2M-COUNT]:
    <k> emitM2M(M:Int) => done </k>
    <dbops> OPS:Int => OPS +Int (2 *Int M) </dbops>
    requires M >=Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - from_public_tests: actual table renames repoint FKs/M2Ms and keep the migration behavior.
  // - from_code: V1 leaves the different-table branch structurally unchanged.
  claim [RENAME-MODEL-DIFFERENT-TABLE-PRESERVES-WORK]:
    <k> renameModelForwards(true, false, R:Int, M:Int) => done </k>
    <dbops> OPS:Int => OPS +Int 1 +Int R +Int (2 *Int M) </dbops>
    requires R >=Int 0 andBool M >=Int 0
    [all-path]
endmodule
