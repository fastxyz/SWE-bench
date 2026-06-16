module MINI-PYTHON-FORMSET-SYNTAX
  imports INT
  imports BOOL
  imports SET

  syntax Index ::= noneIndex() | someIndex(Int)
  syntax Field ::= deleteField()
  syntax Exception ::= noException | typeError

  syntax KItem ::= addFieldsDelete(Bool, Bool, Index, Int)
  syntax Bool ::= shouldAddDelete(Bool, Bool, Index, Int) [function, total]
endmodule

module MINI-PYTHON-FORMSET
  imports MINI-PYTHON-FORMSET-SYNTAX
  imports INT
  imports BOOL
  imports SET

  configuration
    <k> $PGM:K </k>
    <fields> .Set </fields>
    <exception> noException </exception>

  // This is the V1 source condition:
  // self.can_delete and (
  //     self.can_delete_extra
  //     or (index is not None and index < initial_form_count)
  // )
  rule shouldAddDelete(false, _, _, _) => false
  rule shouldAddDelete(true, true, _, _) => true
  rule shouldAddDelete(true, false, noneIndex(), _) => false
  rule shouldAddDelete(true, false, someIndex(I), N) => I <Int N

  rule <k> addFieldsDelete(CD, CDE, IDX, N) => .K </k>
       <fields> FS => FS SetItem(deleteField()) </fields>
       <exception> _ => noException </exception>
    requires shouldAddDelete(CD, CDE, IDX, N)

  rule <k> addFieldsDelete(CD, CDE, IDX, N) => .K </k>
       <fields> FS => FS </fields>
       <exception> _ => noException </exception>
    requires notBool shouldAddDelete(CD, CDE, IDX, N)
endmodule
