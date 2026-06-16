requires "mini-django-migrations.k"

module MIGRATION-RECORDER-SPEC
    imports MINI-DJANGO-MIGRATIONS

    // SPEC-PROVENANCE:
    // - IE-1, IE-2: routers must prevent django_migrations table creation
    //   on aliases where the internal Migration model is not allowed.
    claim <k> ensureSchema => .K </k>
          <allowed> false </allowed>
          <hasTable> H => H </hasTable>
          <creates> C => C </creates>

    // SPEC-PROVENANCE:
    // - IE-2: when the recorder model is allowed, existing legacy behavior is
    //   preserved: a missing recorder table is created.
    claim <k> ensureSchema => .K </k>
          <allowed> true </allowed>
          <hasTable> false => true </hasTable>
          <creates> C => C +Int 1 </creates>

    // SPEC-PROVENANCE:
    // - IE-3, IE-4: disallowed recorder reads must not query the table and must
    //   report no applied migrations.
    claim <k> appliedMigrations => .K </k>
          <allowed> false </allowed>
          <reads> R => R </reads>
          <result> _ => 0 </result>

    // SPEC-PROVENANCE:
    // - IE-3: record_applied must not create or write django_migrations when
    //   routers disallow the recorder model.
    claim <k> recordApplied => .K </k>
          <allowed> false </allowed>
          <hasTable> H => H </hasTable>
          <creates> C => C </creates>
          <writes> W => W </writes>

    // SPEC-PROVENANCE:
    // - IE-4: record_unapplied must not create or delete django_migrations when
    //   routers disallow the recorder model.
    claim <k> recordUnapplied => .K </k>
          <allowed> false </allowed>
          <hasTable> H => H </hasTable>
          <creates> C => C </creates>
          <deletes> D => D </deletes>

    // SPEC-PROVENANCE:
    // - IE-4 plus API consistency: flush is also a recorder write path and must
    //   not delete on a router-disallowed alias.
    claim <k> flushRecorder => .K </k>
          <allowed> false </allowed>
          <deletes> D => D </deletes>

    // SPEC-PROVENANCE:
    // - IE-5: an empty migration plan has no migration records to write, so the
    //   executor must not eagerly create django_migrations only for bookkeeping.
    claim <k> executorMigrate => .K </k>
          <planNonEmpty> false </planNonEmpty>
          <allowed> A => A </allowed>
          <hasTable> H => H </hasTable>
          <creates> C => C </creates>

    // SPEC-PROVENANCE:
    // - IE-5 and legacy behavior: a non-empty migration plan still performs the
    //   eager schema check, which creates the recorder table only if allowed.
    claim <k> executorMigrate => .K </k>
          <planNonEmpty> true </planNonEmpty>
          <allowed> false </allowed>
          <hasTable> H => H </hasTable>
          <creates> C => C </creates>
endmodule
