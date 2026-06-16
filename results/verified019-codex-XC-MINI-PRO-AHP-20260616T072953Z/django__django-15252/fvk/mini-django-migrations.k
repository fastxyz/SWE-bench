requires "domains.md"

module MINI-DJANGO-MIGRATIONS-SYNTAX
    imports BOOL-SYNTAX
    imports INT-SYNTAX

    syntax Action ::= ensureSchema
                    | appliedMigrations
                    | recordApplied
                    | recordUnapplied
                    | flushRecorder
                    | executorMigrate
endmodule

module MINI-DJANGO-MIGRATIONS
    imports MINI-DJANGO-MIGRATIONS-SYNTAX
    imports BOOL
    imports INT

    configuration
        <k> $PGM:Action </k>
        <allowed> true </allowed>
        <hasTable> false </hasTable>
        <planNonEmpty> false </planNonEmpty>
        <creates> 0 </creates>
        <reads> 0 </reads>
        <writes> 0 </writes>
        <deletes> 0 </deletes>
        <result> 0 </result>

    // Abstract model of MigrationRecorder.ensure_schema().
    rule <k> ensureSchema => .K </k>
         <allowed> false </allowed>

    rule <k> ensureSchema => .K </k>
         <allowed> true </allowed>
         <hasTable> true </hasTable>

    rule <k> ensureSchema => .K </k>
         <allowed> true </allowed>
         <hasTable> false => true </hasTable>
         <creates> C => C +Int 1 </creates>

    // Abstract model of MigrationRecorder.applied_migrations().
    rule <k> appliedMigrations => .K </k>
         <allowed> false </allowed>
         <result> _ => 0 </result>

    rule <k> appliedMigrations => .K </k>
         <allowed> true </allowed>
         <hasTable> false </hasTable>
         <result> _ => 0 </result>

    rule <k> appliedMigrations => .K </k>
         <allowed> true </allowed>
         <hasTable> true </hasTable>
         <reads> R => R +Int 1 </reads>
         <result> _ => 1 </result>

    // Abstract model of MigrationRecorder.record_applied().
    rule <k> recordApplied => .K </k>
         <allowed> false </allowed>

    rule <k> recordApplied => ensureSchema ~> recordApplied </k>
         <allowed> true </allowed>
      [owise]

    rule <k> recordApplied => .K </k>
         <allowed> true </allowed>
         <hasTable> true </hasTable>
         <writes> W => W +Int 1 </writes>

    // Abstract model of MigrationRecorder.record_unapplied().
    rule <k> recordUnapplied => .K </k>
         <allowed> false </allowed>

    rule <k> recordUnapplied => ensureSchema ~> recordUnapplied </k>
         <allowed> true </allowed>
      [owise]

    rule <k> recordUnapplied => .K </k>
         <allowed> true </allowed>
         <hasTable> true </hasTable>
         <deletes> D => D +Int 1 </deletes>

    // Abstract model of MigrationRecorder.flush().
    rule <k> flushRecorder => .K </k>
         <allowed> false </allowed>

    rule <k> flushRecorder => .K </k>
         <allowed> true </allowed>
         <hasTable> false </hasTable>

    rule <k> flushRecorder => .K </k>
         <allowed> true </allowed>
         <hasTable> true </hasTable>
         <deletes> D => D +Int 1 </deletes>

    // Abstract model of MigrationExecutor.migrate()'s eager recorder setup.
    rule <k> executorMigrate => .K </k>
         <planNonEmpty> false </planNonEmpty>

    rule <k> executorMigrate => ensureSchema </k>
         <planNonEmpty> true </planNonEmpty>
endmodule
