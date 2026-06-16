requires "mini-python-formset.k"

module FORMSET-ADD-FIELDS-SPEC
  imports MINI-PYTHON-FORMSET
  imports INT
  imports BOOL
  imports SET

  // SPEC-PROVENANCE:
  // - E3/E6: empty_form and hook docs make index=None in-domain.
  // - E4: can_delete_extra=False removes deletion from extra forms.
  // - E1/E2: the reported bug is comparing None with initial_form_count.
  claim <k> addFieldsDelete(true, false, noneIndex(), N:Int) => .K </k>
        <fields> .Set => .Set </fields>
        <exception> noException => noException </exception>
    requires N >=Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - E5: initial indexed forms keep DELETE when extra deletion is disabled.
  claim <k> addFieldsDelete(true, false, someIndex(I:Int), N:Int) => .K </k>
        <fields> .Set => SetItem(deleteField()) </fields>
        <exception> noException => noException </exception>
    requires N >=Int 0 andBool I >=Int 0 andBool I <Int N
    [all-path]

  // SPEC-PROVENANCE:
  // - E4/E5: indexed extra forms omit DELETE when extra deletion is disabled.
  claim <k> addFieldsDelete(true, false, someIndex(I:Int), N:Int) => .K </k>
        <fields> .Set => .Set </fields>
        <exception> noException => noException </exception>
    requires N >=Int 0 andBool I >=Int N
    [all-path]

  // SPEC-PROVENANCE:
  // - E4 plus default can_delete_extra=True behavior: extra deletion remains enabled.
  claim <k> addFieldsDelete(true, true, IDX:Index, N:Int) => .K </k>
        <fields> .Set => SetItem(deleteField()) </fields>
        <exception> noException => noException </exception>
    requires N >=Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - can_delete=False means the deletion feature is disabled.
  claim <k> addFieldsDelete(false, CDE:Bool, IDX:Index, N:Int) => .K </k>
        <fields> .Set => .Set </fields>
        <exception> noException => noException </exception>
    requires N >=Int 0
    [all-path]
endmodule
