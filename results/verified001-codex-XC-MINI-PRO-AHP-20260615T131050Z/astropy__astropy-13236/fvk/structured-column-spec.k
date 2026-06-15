requires "mini-astropy-table.k"

module STRUCTURED-COLUMN-SPEC
  imports MINI-ASTROPY-TABLE

  // SPEC-PROVENANCE:
  // - from_prompt: "structured `np.array` ... gets turned into an `NdarrayMixin`" is the defect.
  // - from_prompt: "the structured array will be added as a `Column`" is the required postcondition.
  // - from_hints: "create structured columns directly" and "Delete a few lines of code" select the immediate change.
  // - from_code: repo/astropy/table/table.py now has no structured-array view-to-mixin branch.
  claim <k> convert(plainStructuredNdarray)
        => columnResult(plainStructuredNdarray) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: the reported defect is the automatic conversion of plain structured arrays,
  //   not explicit user construction of an NdarrayMixin.
  // - from_code: _is_mixin_for_table still routes explicit mixins through the data_is_mixin branch.
  claim <k> convert(explicitNdarrayMixin)
        => mixinResult(explicitNdarrayMixin) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: astropy.table.__init__ imports NdarrayMixin from astropy.table.table.
  // - from_compatibility: public imports must keep resolving while behavior changes.
  claim <k> tableModuleNdarrayMixin
        => NdarrayMixinClass </k>
    [all-path]
endmodule
