requires "domains.md"

module MINI-PYTHON-MARKS-SYNTAX
  imports INT-SYNTAX
  imports STRING-SYNTAX

  syntax Class ::= "testDings" | "fooClass" | "barClass" | "baseClass" | "objectClass" | "subClass"
  syntax MarkName ::= "fooMark" | "barMark" | "baseMark" | "subMark" | "badMark"

  syntax MarkList ::= ".Marks" | MarkName "," MarkList
  syntax ClassList ::= ".Classes" | Class "," ClassList
  syntax ClassMarks ::= ".ClassMarks" | Class "|->" MarkList ";" ClassMarks

  syntax Bool ::= hasOwn(Class, ClassMarks) [function]
  syntax MarkList ::= own(Class, ClassMarks) [function]
  syntax MarkList ::= appendMarks(MarkList, MarkList) [function]
  syntax MarkList ::= marksFromMro(ClassList, ClassMarks) [function]
  syntax MarkList ::= storeDirect(Class, MarkName, ClassMarks) [function]
  syntax MarkList ::= getClassMarks(ClassList, ClassMarks) [function]
endmodule

module MINI-PYTHON-MARKS
  imports MINI-PYTHON-MARKS-SYNTAX
  imports BOOL

  configuration <k> $PGM:MarkList </k>

  rule hasOwn(C, .ClassMarks) => false
  rule hasOwn(C, C |-> ML ; CM) => true
  rule hasOwn(C, D |-> ML ; CM) => hasOwn(C, CM) requires C =/=K D

  rule own(C, .ClassMarks) => .Marks
  rule own(C, C |-> ML ; CM) => ML
  rule own(C, D |-> ML ; CM) => own(C, CM) requires C =/=K D

  rule appendMarks(.Marks, ML) => ML
  rule appendMarks(M , MS, ML) => M , appendMarks(MS, ML)

  rule marksFromMro(.Classes, CM) => .Marks
  rule marksFromMro(C , CS, CM) => appendMarks(own(C, CM), marksFromMro(CS, CM))

  rule getClassMarks(CS, CM) => marksFromMro(CS, CM)

  // Models V1 store_mark(..., consider_mro=False): append to direct marks only.
  rule storeDirect(C, M, CM) => appendMarks(own(C, CM), M , .Marks)
endmodule
