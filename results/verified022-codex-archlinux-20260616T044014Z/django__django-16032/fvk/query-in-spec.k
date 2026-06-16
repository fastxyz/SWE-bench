requires "mini-django-query.k"

module QUERY-IN-SPEC
  imports MINI-DJANGO-QUERY

  // SPEC-PROVENANCE:
  // - prompt: "__in doesn't clear selected fields on the RHS when
  //   QuerySet.alias() is used after annotate()." => annotate+alias without
  //   values() must still be treated as an undefined RHS select list.
  // - prompt: "__in lookup ... automatically limit selected fields to the pk
  //   when Query is on the right-side and the selected fields are undefined."
  //   => In.get_prep_lookup() must narrow this RHS to pkSelect.
  claim
    <k> annotate ; aliasAfterAnnotate ; inPrep => .K ... </k>
    <q> query(false, defaultCols, maskNone)
     => query(false, pkSelect, maskEmpty)
    </q>
    [all-path]

  // SPEC-PROVENANCE:
  // - prompt: automatic pk narrowing applies "when ... selected fields are
  //   undefined" => explicit values-style selection must not be overwritten.
  // - code: Query.set_values() is the values()/values_list() selection path.
  claim
    <k> setValues(explicit) ; inPrep => .K ... </k>
    <q> query(false, defaultCols, maskNone)
     => query(true, explicitSelect, maskEmpty)
    </q>
    [all-path]

  // SPEC-PROVENANCE:
  // - prompt: RelatedIn must "go through Query.set_values instead of calling
  //   clear_select_clause and add_fields" => relation-specific target fields
  //   must survive the base In.get_prep_lookup() delegation.
  claim
    <k> relatedInPrep(false, false) => .K ... </k>
    <q> query(false, defaultCols, maskNone)
     => query(true, targetSelect, maskEmpty)
    </q>
    [all-path]

  // SPEC-PROVENANCE:
  // - prompt: Query.clone carries has_select_fields as shallow state.
  // - code: Query.clone() copies __dict__, where set_values() stores the
  //   instance-level has_select_fields = True.
  claim
    <k> setValues(explicit) ; clone ; inPrep => .K ... </k>
    <q> query(false, defaultCols, maskNone)
     => query(true, explicitSelect, maskEmpty)
    </q>
    [all-path]

  // SPEC-PROVENANCE:
  // - code/public API: Exact.get_prep_lookup() uses the same has_select_fields
  //   discriminator for a sliced one-row RHS Query.
  // - prompt: annotation masks are not explicit selected fields.
  claim
    <k> annotate ; aliasAfterAnnotate ; exactPrepOne => .K ... </k>
    <q> query(false, defaultCols, maskNone)
     => query(false, pkSelect, maskEmpty)
    </q>
    [all-path]
endmodule
