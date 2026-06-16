requires "mini-management.k"

module MANAGEMENT-PREPARSE-SPEC
  imports MINI-MANAGEMENT

  // SPEC-PROVENANCE:
  // - from_issue: "Instead, it should refer to self.prog_name." =>
  //   the early ManagementUtility parser receives the explicit argv-derived
  //   program name, regardless of the process-global sys.argv[0].
  claim
    <k> mgmtPreparse(ARGV_PROG:String, SYS_PROG:String) => .K </k>
    <parserProg> none => some(mgmtProg(ARGV_PROG)) </parserProg>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_issue: caller-supplied argv should avoid global sys.argv[0]
  //   exceptions.
  // - from_source_docstring: get_command_line_option() returns an option value
  //   "from an argument list" =>
  //   the helper pre-parser receives a program name derived from that argument
  //   list, not from the process-global sys.argv[0].
  claim
    <k> optionPreparse(ARGV_PROG:MaybeString, SYS_PROG:String) => .K </k>
    <parserProg> none => some(helperProg(ARGV_PROG)) </parserProg>
    [all-path]
endmodule
