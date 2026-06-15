requires "mini-django-query.k"

module QUERY-OUTPUT-FIELD-SPEC
  imports MINI-DJANGO-QUERY

  // SPEC-PROVENANCE:
  // - E-004: selected Col output must use target, not field/output_field.
  // - E-005: Col.target and Col.field can differ for ForeignKey selections.
  // CLAIM: QUERY-OUTPUT-FIELD-TARGET
  claim
    <k>
      outputField(query(
        oneSelect(col(foreignKey("C.owner", concreteField("User.id")), concreteField("User.id"))),
        noAnn()
      ))
      => foreignKey("C.owner", concreteField("User.id"))
    </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E-006: Subquery._resolve_output_field delegates to Query.output_field.
  // CLAIM: SUBQUERY-DELEGATES
  claim
    <k>
      subqueryOutput(query(
        oneSelect(col(foreignKey("C.owner", concreteField("User.id")), concreteField("User.id"))),
        noAnn()
      ))
      => foreignKey("C.owner", concreteField("User.id"))
    </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E-003/E-007: relation exact lookups normalize lazy model instances.
  // CLAIM: RELATED-EXACT-NORMALIZES-LAZY
  claim
    <k>
      prepExact(
        foreignKey("C.owner", concreteField("User.id")),
        lazyModel(concreteField("User.id"), PK:Int)
      )
      => prepared(PK)
    </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - F-001 counterexample: the concrete field path raises the reported type error.
  // CLAIM: CONCRETE-FIELD-LAZY-COUNTEREXAMPLE
  claim
    <k>
      prepExact(
        concreteField("User.id"),
        lazyModel(concreteField("User.id"), PK:Int)
      )
      => typeError()
    </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - INT-004: non-relational columns where target == output_field are framed.
  // CLAIM: SAME-TARGET-FIELD-FRAME
  claim
    <k>
      outputField(query(
        oneSelect(col(concreteField("A.id"), concreteField("A.id"))),
        noAnn()
      ))
      => concreteField("A.id")
    </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - INT-004: annotation-only branch remains unchanged.
  // CLAIM: ANNOTATION-ONLY-FRAME
  claim
    <k>
      outputField(query(noSelect(), oneAnn(concreteField("annotation.value"))))
      => concreteField("annotation.value")
    </k>
    [all-path]
endmodule
