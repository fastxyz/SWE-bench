requires "mini-django-delete.k"

module DJANGO-DELETE-SPEC
  imports MINI-DJANGO-DELETE
  imports INT
  imports BOOL

  // SPEC-PROVENANCE:
  // - E1/E2/E3/E4: Model.objects.all().delete() must emit direct DELETE FROM
  //   rather than DELETE WHERE pk IN (SELECT pk FROM same table).
  // - E6: an uninitialized query must first count the base alias.
  claim <k> deleteShape(0, 0) => direct </k> [all-path]

  // SPEC-PROVENANCE:
  // - E5: "single alias" deletes should avoid the fallback.
  claim <k> deleteShape(1, 0) => direct </k> [all-path]

  // SPEC-PROVENANCE:
  // - E5: only single-alias deletes are direct; multi-alias deletes stay on
  //   the existing fallback path.
  claim <k> deleteShape(A:Int, 0) => fallback </k>
    requires A >=Int 2
    [all-path]

  // SPEC-PROVENANCE:
  // - E7: extra_tables are not represented by _as_sql(), so direct delete is
  //   not a valid branch when they are present.
  claim <k> deleteShape(A:Int, E:Int) => fallback </k>
    requires A >=Int 0 andBool E >Int 0
    [all-path]
endmodule
