// Specification claims for django__django-12143.
// Constructed, not machine-checked.

requires "mini-admin-post.k"

module ADMIN-OPTIONS-SPEC
  imports MINI-ADMIN-POST
  imports BOOL

  syntax Values ::= literalSelectedValues(Entries, String, String) [function]

  // SPEC-PROVENANCE:
  // - E1/E2: prefix may contain regex metacharacters and must be literal.
  // - E3: public issue identifies re.escape() as the intended literalization.
  // - E4: generated key shape is prefix-index-pk_name.
  claim
    <k> escapedPkRegexMatches(KEY, PREFIX, PK)
     => literalPkFieldName(KEY, PREFIX, PK) ... </k>
    [all-path]

  claim
    <k> literalPkFieldName(KEY, PREFIX, PK)
     => escapedPkRegexMatches(KEY, PREFIX, PK) ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E5: _get_edited_object_pks() filters request.POST.items() by the regex.
  // - O4/O5/O6: output is exactly matching values, in input order.
  claim
    <k> selectPks(POST, PREFIX, PK)
     => literalSelectedValues(POST, PREFIX, PK) ... </k>
    [all-path]
endmodule
