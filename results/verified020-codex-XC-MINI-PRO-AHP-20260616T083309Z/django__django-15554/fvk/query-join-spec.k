// Abstract K claims for the FilteredRelation join reuse fix.
// Constructed for FVK audit; not machine-checked in this session.

requires "mini-django-query.k"

module QUERY-JOIN-SPEC
  imports MINI-DJANGO-QUERY
  imports BOOL
  imports MAP
  imports SET

  // SPEC-PROVENANCE:
  // - from_prompt: "Using multiple FilteredRelation with different filters but
  //   for same relation is ignored." => strong-distinct filtered aliases must
  //   not reuse the first alias in normal query construction.
  claim
    <k>
      choose(
        "relation_zone" |-> join("nested_table", "parent", "nested_fk",
          fr("relation_zone", "myrelation__nested", "zone=outer.zone")),
        join("nested_table", "parent", "nested_fk",
          fr("relation_all", "myrelation__nested", "is_all=True")),
        allAliases,
        normal
      )
      => create(join("nested_table", "parent", "nested_fk",
          fr("relation_all", "myrelation__nested", "is_all=True")))
    </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_docs: "FilteredRelation ... create an ON clause when a JOIN is
  //   performed" => while compiling that ON condition, relation lookups must
  //   reuse the filtered path alias.
  claim
    <k>
      choose(
        "relation_zone" |-> join("nested_table", "parent", "nested_fk",
          fr("relation_zone", "myrelation__nested", "zone=outer.zone")),
        join("nested_table", "parent", "nested_fk", noFR),
        aliases(SetItem("relation_zone")),
        filteredCondition
      )
      => reuse("relation_zone")
    </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_implementation: FilteredRelation.as_sql() supplies
  //   reuse=set(self.path) => weak equality is scoped to that path.
  claim
    <k>
      choose(
        "other_alias" |-> join("nested_table", "parent", "nested_fk",
          fr("other_alias", "myrelation__nested", "other=True")),
        join("nested_table", "parent", "nested_fk", noFR),
        aliases(SetItem("relation_zone")),
        filteredCondition
      )
      => create(join("nested_table", "parent", "nested_fk", noFR))
    </k>
    [all-path]
endmodule

