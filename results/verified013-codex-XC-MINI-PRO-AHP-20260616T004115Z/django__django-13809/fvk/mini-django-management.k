module MINI-DJANGO-MANAGEMENT-SYNTAX
  imports BOOL-SYNTAX

  syntax Cmd ::= "createRunserverParser"
               | "innerRun" "(" Bool ")"

  syntax Arg ::= "argAddrPort"
               | "argIPv6"
               | "argNoThreading"
               | "argNoReload"
               | "argSkipChecks"

  syntax Event ::= "eventRaiseLastException"
                 | "eventSystemCheck"
                 | "eventMigrationCheck"
                 | "eventServe"

  syntax KResult ::= Bool
endmodule

module MINI-DJANGO-MANAGEMENT
  imports MINI-DJANGO-MANAGEMENT-SYNTAX
  imports BOOL
  imports LIST

  configuration
    <k> $PGM:Cmd </k>
    <parser> .List </parser>
    <events> .List </events>

  // Models runserver.Command.add_arguments(parser) for the command-specific
  // options relevant to this issue.
  rule
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

  // Models the check-scheduling prefix of runserver.Command.inner_run().
  rule
    <k> innerRun(false) => .K </k>
    <events>
      .List
      =>
      ListItem(eventRaiseLastException)
      ListItem(eventSystemCheck)
      ListItem(eventMigrationCheck)
      ListItem(eventServe)
    </events>

  rule
    <k> innerRun(true) => .K </k>
    <events>
      .List
      =>
      ListItem(eventRaiseLastException)
      ListItem(eventMigrationCheck)
      ListItem(eventServe)
    </events>
endmodule
