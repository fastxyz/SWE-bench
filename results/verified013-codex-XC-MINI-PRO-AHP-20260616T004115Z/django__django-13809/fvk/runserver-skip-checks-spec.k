requires "mini-django-management.k"

module RUNSERVER-SKIP-CHECKS-SPEC
  imports MINI-DJANGO-MANAGEMENT

  // SPEC-PROVENANCE:
  // - E1: "Add --skip-checks option to the runserver command."
  // - E2: "consistent with other management commands performing system checks"
  // - E4: runserver validates explicitly on each reload, so it needs a local option.
  // Claim: RUNSERVER-PARSER-HAS-SKIP-CHECKS
  claim
    <k> createRunserverParser => .K </k>
    <parser>
      .List
      =>
      ListItem(argAddrPort)
      ListItem(argIPv6)
      ListItem(argNoThreading)
      ListItem(argNoReload)
      ListItem(argSkipChecks)
    </parser>
    <events> .List </events>
    [all-path]

  // SPEC-PROVENANCE:
  // - E3: skip flag must target the reload/start path.
  // - E4: inner_run is where runserver performs explicit validation.
  // - E6: migration checks remain separate and enabled.
  // Claim: INNERRUN-NO-SKIP-CHECKS
  claim
    <k> innerRun(false) => .K </k>
    <parser> .List </parser>
    <events>
      .List
      =>
      ListItem(eventRaiseLastException)
      ListItem(eventSystemCheck)
      ListItem(eventMigrationCheck)
      ListItem(eventServe)
    </events>
    [all-path]

  // SPEC-PROVENANCE:
  // - E1: --skip-checks must have an observable effect.
  // - E3: skip checks avoids the repeated development system-check cost.
  // - E6: migration checks are not system checks and remain enabled.
  // Claim: INNERRUN-SKIP-CHECKS
  claim
    <k> innerRun(true) => .K </k>
    <parser> .List </parser>
    <events>
      .List
      =>
      ListItem(eventRaiseLastException)
      ListItem(eventMigrationCheck)
      ListItem(eventServe)
    </events>
    [all-path]
endmodule
