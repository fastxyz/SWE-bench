requires "mini-ddl-references.k"

module SCHEMA-UNIQUE-SPEC
  imports MINI-DDL-REFERENCES

  // SPEC-PROVENANCE:
  // - from_prompt: "_create_unique_sql makes references_column always false"
  //   => explicit-name unique statements must still identify unique columns.
  // - from_prompt: "Table is passed as an argument to Columns when a string is expected"
  //   => columnsPart must store raw(T), not wrapped(T).
  claim
    <k> stmtReferencesColumn(createUniqueV2(T:String, col(C:String, CS:Cols), explicitName), raw(T), C)
        => true
    </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: same unique-statement reference obligation.
  // - from_code: generated names use IndexName over the same unique columns.
  claim
    <k> stmtReferencesColumn(createUniqueV2(T:String, col(C:String, CS:Cols), generatedName), raw(T), C)
        => true
    </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: legacy behavior is the bug, not desired behavior.
  // - from_code: explicit names are quoted strings, so only Columns can carry the column reference.
  claim
    <k> stmtReferencesColumn(createUniqueV1(T:String, col(C:String, CS:Cols), explicitName), raw(T), C)
        => false
    </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: SQL rendering still needs a Table-like table placeholder.
  // - from_neighbor: _create_index_sql wraps the raw table name only for the rendered table part.
  claim
    <k> renderedTableKey(createUniqueV2(T:String, CS:Cols, explicitName))
        => raw(T)
    </k>
    [all-path]
endmodule

