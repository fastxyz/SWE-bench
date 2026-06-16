module MINI-ADMIN-EMPTY-LABEL-SYNTAX
  imports BOOL
  imports STRING

  syntax Label ::= defaultNoneText
                 | noEmptyChoice
                 | customLabel(String)
                 | emptyStringLabel

  syntax MaybeLabel ::= absent
                      | present(Label)

  syntax KItem ::= resolveRadioEmptyLabel(Bool, MaybeLabel)
endmodule

module MINI-ADMIN-EMPTY-LABEL
  imports MINI-ADMIN-EMPTY-LABEL-SYNTAX

  configuration <k> $PGM:K </k>

  // Abstract semantics for the admin radio ForeignKey empty_label branch.
  // Bool argument is db_field.blank. MaybeLabel models key presence in kwargs.
  rule <k> resolveRadioEmptyLabel(true, present(L:Label)) => L ... </k>
  rule <k> resolveRadioEmptyLabel(true, absent) => defaultNoneText ... </k>
  rule <k> resolveRadioEmptyLabel(false, _:MaybeLabel) => noEmptyChoice ... </k>
endmodule
