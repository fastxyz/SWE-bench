requires "mini-django-schema.k"

module DJANGO-15629-SPEC
  imports MINI-DJANGO-SCHEMA

  // SPEC-PROVENANCE:
  // - from_prompt: "COLLATE should also be present in the ... account_id ...
  //   modification statements" => FK column SQL must include target collation.
  // - from_prompt: "The collation of the pk must match the collation of the fk"
  //   => FK params carry the target field collation.
  claim
    <k> fkParams(field("varchar(22)", false, false, false, true,
        params("varchar(22)", false, collation("utf8_bin"))))
      => params("varchar(22)", false, collation("utf8_bin")) ... </k>

  // SPEC-PROVENANCE:
  // - from_prompt: expected create/alter FK column definitions include COLLATE.
  // - from_code: BaseDatabaseSchemaEditor._iter_column_sql emits db_params
  //   collation if present.
  claim
    <k> createColumnSql(field("varchar(22)", false, false, false, true,
        fkParams(field("varchar(22)", false, true, true, true,
          params("varchar(22)", false, collation("utf8_bin"))))))
      => columnSql("varchar(22)", collation("utf8_bin"), false) ... </k>

  // SPEC-PROVENANCE:
  // - from_prompt/hint: changing/adding/removing target db_collation must be
  //   reflected on FK fields and constraints.
  // - from_code: _alter_field now treats type or collation change on retained
  //   primary key/unique target as requiring incoming FK handling.
  claim
    <k> dropIncomingFks(
        field("varchar(22)", false, true, true, true,
          params("varchar(22)", false, noCollation())),
        field("varchar(22)", false, true, true, true,
          params("varchar(22)", false, collation("utf8_bin"))))
      => true ... </k>

  // SPEC-PROVENANCE:
  // - from_prompt: nullable and non-null FK columns must both carry the target
  //   collation during ALTER.
  // - from_code: related alter path passes the new relation collation to the
  //   existing backend type-alter helper, preserving nullability.
  claim
    <k> relatedAlterSql(field("varchar(22)", true, false, false, true,
        params("varchar(22)", false, collation("utf8_bin"))))
      => alterSql("varchar(22)", collation("utf8_bin"), true) ... </k>
endmodule
