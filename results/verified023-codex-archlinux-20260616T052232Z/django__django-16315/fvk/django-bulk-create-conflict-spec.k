requires "mini-django-upsert.k"

module DJANGO-BULK-CREATE-CONFLICT-SPEC
  imports MINI-DJANGO-UPSERT

  // SPEC-PROVENANCE:
  // - from_prompt: expected conflict target "BlacklistID" for unique field
  //   name "blacklistid".
  // - from_docs_or_code: Field.column is db_column when db_column is set.
  claim
    <k>
      compilerFields(
        update,
        queryFields(
          update,
          "blacklistid" |-> field("blacklistid", "BlacklistID"),
          ListItem("blacklistid")
        )
      )
    => ListItem("BlacklistID")
    </k>

  // SPEC-PROVENANCE:
  // - from_prompt: expected update assignment "SectorID" for update field
  //   name "sectorid".
  // - from_docs_or_code: Field.column is db_column when db_column is set.
  claim
    <k>
      compilerFields(
        update,
        queryFields(
          update,
          "sectorid" |-> field("sectorid", "SectorID"),
          ListItem("sectorid")
        )
      )
    => ListItem("SectorID")
    </k>

  // SPEC-PROVENANCE:
  // - from_compatibility_audit: non-upsert paths must not newly resolve
  //   otherwise unused option values.
  claim
    <k> queryFields(none, .Map, ListItem("nonexistent")) => ListItem("nonexistent") </k>

  // SPEC-PROVENANCE:
  // - from_compatibility_audit: ignore-conflicts paths must not newly resolve
  //   otherwise unused option values.
  claim
    <k> compilerFields(ignore, ListItem("field_name")) => ListItem("field_name") </k>
endmodule
