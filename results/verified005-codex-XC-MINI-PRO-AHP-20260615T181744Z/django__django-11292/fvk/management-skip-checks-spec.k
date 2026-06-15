requires "mini-django-management.k"

module MINI-DJANGO-MANAGEMENT-SPEC
  imports MINI-DJANGO-MANAGEMENT

  // SPEC-PROVENANCE:
  // - from_prompt: "Add --skip-checks option to management commands." =>
  //   command-line skip flag must be observable by commands that perform
  //   system checks.
  // - from_prompt: "This would allow users to skip checks when running a
  //   command from the command line." => skip flag suppresses system checks.
  // - from_code: BaseCommand.execute() performs automatic checks when
  //   requires_system_checks and not skip_checks.
  claim <k> run(auto, false) => done </k>
        <checks> N:Int => N +Int 1 </checks>
        [all-path]

  claim <k> run(auto, true) => done </k>
        <checks> N:Int => N </checks>
        [all-path]

  // SPEC-PROVENANCE:
  // - from_code/comment: runserver disables automatic checks because
  //   "Validation is called explicitly each time the server is reloaded."
  // - from_prompt: the explicit runserver system check is still a system check
  //   users must be able to skip from the command line.
  claim <k> run(runserver, false) => done </k>
        <checks> N:Int => N +Int 1 </checks>
        [all-path]

  claim <k> run(runserver, true) => done </k>
        <checks> N:Int => N </checks>
        [all-path]

  // SPEC-PROVENANCE:
  // - from_code: testserver reaches system checks only by delegating to
  //   runserver through call_command().
  // - from_finding: V1 let call_command() inject skip_checks=True for this
  //   delegation, causing command-line testserver to skip checks by default.
  // - obligation: testserver must pass the caller's skip flag through.
  claim <k> run(testserver, false) => done </k>
        <checks> N:Int => N +Int 1 </checks>
        [all-path]

  claim <k> run(testserver, true) => done </k>
        <checks> N:Int => N </checks>
        [all-path]

  // SPEC-PROVENANCE:
  // - from_code: commands that do not perform automatic or explicit system
  //   checks have no check-count effect in this issue slice.
  claim <k> run(nocheck, S:Bool) => done </k>
        <checks> N:Int => N </checks>
        [all-path]
endmodule
