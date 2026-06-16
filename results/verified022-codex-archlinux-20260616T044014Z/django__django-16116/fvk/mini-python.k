requires "domains.md"

module MINI-MAKEMIGRATIONS-SYNTAX
  imports BOOL
  imports INT

  syntax Cmd ::= handle(Bool, Bool, Bool, Bool, Bool, Bool, Bool)
               | afterInit(Bool, Bool, Bool, Bool, Bool, Bool)
               | writeFiles(Bool)
               | writeUpdate(Bool)
               | mergeWrite(Bool)
               | setExit(Int)
endmodule

module MINI-MAKEMIGRATIONS
  imports MINI-MAKEMIGRATIONS-SYNTAX
  imports BOOL
  imports INT

  configuration
    <k> $PGM:Cmd </k>
    <dryRun> false </dryRun>
    <writes> 0 </writes>
    <deletes> 0 </deletes>
    <exitCode> -1 </exitCode>

  // Abstracts Command.handle() option setup:
  // self.dry_run = options["dry_run"] or options["check_changes"].
  rule <k> handle(CHECK, DRYOPT, EMPTY, UPDATE, MERGE, CONFLICTS, CHANGES)
        => afterInit(EMPTY, UPDATE, MERGE, CONFLICTS, CHANGES, CHECK)
       </k>
       <dryRun> _ => DRYOPT orBool CHECK </dryRun>

  // Merge conflicts with --merge route to the merge writer before autodetection.
  rule <k> afterInit(EMPTY0, UPDATE0, true, true, CHANGES0, CHECK0)
        => mergeWrite(DRY) ~> setExit(0)
       </k>
       <dryRun> DRY </dryRun>

  // --empty reaches write_migration_files() after its own validation.
  rule <k> afterInit(true, UPDATE0, false, CONFLICTS0, CHANGES0, CHECK0)
        => writeFiles(DRY) ~> setExit(0)
       </k>
       <dryRun> DRY </dryRun>

  // Normal and update paths after autodetection.
  rule <k> afterInit(false, false, false, CONFLICTS0, true, true)
        => writeFiles(DRY) ~> setExit(1)
       </k>
       <dryRun> DRY </dryRun>

  rule <k> afterInit(false, true, false, CONFLICTS0, true, true)
        => writeUpdate(DRY) ~> setExit(1)
       </k>
       <dryRun> DRY </dryRun>

  rule <k> afterInit(false, false, false, CONFLICTS0, true, false)
        => writeFiles(DRY) ~> setExit(0)
       </k>
       <dryRun> DRY </dryRun>

  rule <k> afterInit(false, true, false, CONFLICTS0, true, false)
        => writeUpdate(DRY) ~> setExit(0)
       </k>
       <dryRun> DRY </dryRun>

  rule <k> afterInit(false, UPDATE0, false, CONFLICTS0, false, CHECK0)
        => setExit(0)
       </k>

  // The writer helpers. In dry-run/check mode they log only; in write mode they
  // perform abstract file writes, and update may delete a previous migration.
  rule <k> writeFiles(true) => .K ... </k>

  rule <k> writeFiles(false) => .K ... </k>
       <writes> W => W +Int 1 </writes>

  rule <k> writeUpdate(true) => .K ... </k>

  rule <k> writeUpdate(false) => .K ... </k>
       <writes> W => W +Int 1 </writes>
       <deletes> D => D +Int 1 </deletes>

  rule <k> mergeWrite(true) => .K ... </k>

  rule <k> mergeWrite(false) => .K ... </k>
       <writes> W => W +Int 1 </writes>

  rule <k> setExit(I) => .K ... </k>
       <exitCode> _ => I </exitCode>
endmodule
