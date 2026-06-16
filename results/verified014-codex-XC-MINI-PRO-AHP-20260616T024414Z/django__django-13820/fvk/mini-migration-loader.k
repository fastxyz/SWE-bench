module MINI-MIGRATION-LOADER-SYNTAX
  syntax FileState ::= "fileMissing" | "fileSet"
  syntax PathKind ::= "pathAbsent" | "pathList" | "pathOther"
  syntax Action ::= "unmigrated" | "scan"
  syntax Cmd ::= "decide" "(" FileState "," PathKind ")"
  syntax KResult ::= Action
endmodule

module MINI-MIGRATION-LOADER
  imports MINI-MIGRATION-LOADER-SYNTAX

  configuration <k> $PGM:Cmd </k>

  rule <k> decide(fileMissing, pathAbsent) => unmigrated </k>
  rule <k> decide(fileMissing, pathOther) => unmigrated </k>
  rule <k> decide(fileMissing, pathList) => scan </k>
  rule <k> decide(fileSet, pathAbsent) => unmigrated </k>
  rule <k> decide(fileSet, pathList) => scan </k>
  rule <k> decide(fileSet, pathOther) => scan </k>
endmodule
