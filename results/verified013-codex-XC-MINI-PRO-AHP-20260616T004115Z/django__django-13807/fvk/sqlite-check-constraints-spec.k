requires "mini-sqlite-check-constraints.k"

module SQLITE-CHECK-CONSTRAINTS-SPEC
  imports MINI-SQLITE-CHECK-CONSTRAINTS

  // SPEC-PROVENANCE:
  // - from_prompt: "PRAGMA foreign_key_check(order)" raises a syntax error.
  // - obligation: a raw SQL keyword table name reproduces the pre-fix failure.
  claim <k> preNoViolation(kw) => ERR </k>
    [all-path, label(PRE_FIX_REPRODUCES_BUG)]

  // SPEC-PROVENANCE:
  // - from_prompt: "loaddata crashes on SQLite when table names are SQL keywords."
  // - from_hint: "yes, self.ops.quote_name(table_name)"
  // - obligation: V1's specific-table foreign_key_check path accepts any name class.
  claim <k> v1NoViolation(N:Name) => OK </k>
    [all-path, label(V1_FK_CHECK_KEYWORD_SAFE)]

  // SPEC-PROVENANCE:
  // - from_prompt: the issue also points to PRAGMA foreign_key_list(%s).
  // - from_proof_finding: the diagnostic SELECT must not reintroduce raw identifiers.
  // - obligation: V1's violation-reporting path quotes table and column identifiers.
  claim <k> v1WithViolation(T:Name, PK:Name, FK:Name) => OK </k>
    [all-path, label(V1_VIOLATION_KEYWORD_SAFE)]

  // SPEC-PROVENANCE:
  // - from_compatibility: existing non-keyword table names should retain valid SQL.
  // - obligation: V1 preserves the no-violation path for non-keyword names.
  claim <k> v1NoViolation(nonkw) => OK </k>
    [all-path, label(V1_NONKEYWORD_PRESERVED)]
endmodule
