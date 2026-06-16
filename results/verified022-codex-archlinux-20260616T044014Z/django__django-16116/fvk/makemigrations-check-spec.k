requires "mini-python.k"

module MAKEMIGRATIONS-CHECK-SPEC
  imports MINI-MAKEMIGRATIONS

  // SPEC-PROVENANCE:
  // - E3: "--check" alone should no longer need explicit "--dry-run".
  // - E6: self.dry_run is the command's existing no-write switch.
  claim
    <k> handle(true, DRYOPT:Bool, false, false, false, false, false) => .K </k>
    <dryRun> false => true </dryRun>
    <writes> 0 => 0 </writes>
    <deletes> 0 => 0 </deletes>
    <exitCode> -1 => 0 </exitCode>
    [all-path]

  // SPEC-PROVENANCE:
  // - E5: detected missing migrations must exit non-zero.
  // - E2: check mode must not create migration files.
  // - E8: write_migration_files() writes only when dryRun is false.
  claim
    <k> handle(true, false, false, false, false, false, true) => .K </k>
    <dryRun> false => true </dryRun>
    <writes> 0 => 0 </writes>
    <deletes> 0 => 0 </deletes>
    <exitCode> -1 => 1 </exitCode>
    [all-path]

  // SPEC-PROVENANCE:
  // - E2: update mode is a migration-making path and must be no-write under
  //   check mode once update-specific validation reaches the writer.
  // - E8: write_migration_files() guards both writes and update deletes by
  //   self.dry_run.
  claim
    <k> handle(true, false, false, true, false, false, true) => .K </k>
    <dryRun> false => true </dryRun>
    <writes> 0 => 0 </writes>
    <deletes> 0 => 0 </deletes>
    <exitCode> -1 => 1 </exitCode>
    [all-path]

  // SPEC-PROVENANCE:
  // - E7: public tests support success when no changes exist.
  // - E2: check mode must not make migrations even on success.
  claim
    <k> handle(true, false, false, false, false, false, false) => .K </k>
    <dryRun> false => true </dryRun>
    <writes> 0 => 0 </writes>
    <deletes> 0 => 0 </deletes>
    <exitCode> -1 => 0 </exitCode>
    [all-path]

  // SPEC-PROVENANCE:
  // - E2: "without making migrations" covers the --empty writer path.
  // - Exact status here is implementation-derived and not used as public-intent
  //   evidence; the no-write postcondition is the relevant claim.
  claim
    <k> handle(true, false, true, false, false, false, false) => .K </k>
    <dryRun> false => true </dryRun>
    <writes> 0 => 0 </writes>
    <deletes> 0 => 0 </deletes>
    <exitCode> -1 => 0 </exitCode>
    [all-path]

  // SPEC-PROVENANCE:
  // - E2: "without making migrations" covers merge migration files.
  // - E9: handle_merge() writes only when dryRun is false.
  claim
    <k> handle(true, false, false, false, true, true, false) => .K </k>
    <dryRun> false => true </dryRun>
    <writes> 0 => 0 </writes>
    <deletes> 0 => 0 </deletes>
    <exitCode> -1 => 0 </exitCode>
    [all-path]

  // SPEC-PROVENANCE:
  // - I5: ordinary non-check behavior is framed as unchanged.
  claim
    <k> handle(false, false, false, false, false, false, true) => .K </k>
    <dryRun> false => false </dryRun>
    <writes> 0 => 1 </writes>
    <deletes> 0 => 0 </deletes>
    <exitCode> -1 => 0 </exitCode>
    [all-path]
endmodule
