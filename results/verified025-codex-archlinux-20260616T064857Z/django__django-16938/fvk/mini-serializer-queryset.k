// Constructed, not machine-checked.
// Minimal K-style semantics for the serializer/queryset fragment involved in
// django__django-16938. This abstracts Django QuerySet state to exactly the
// parts relevant to the issue: inherited select_related state, field loading
// masks, and the related rows whose primary keys are serialized.

requires "domains.md"

module MINI-SERIALIZER-QUERYSET-SYNTAX
  imports INT
  imports BOOL
  imports LIST

  syntax Sel ::= noSelectRelated()
               | someSelectRelated()
  syntax Load ::= allFields()
                | onlyPkField()
  syntax Row ::= row(Int)
  syntax QueryState ::= qs(Sel, Load, List)
  syntax Source ::= cached(List)
                  | uncached(QueryState)
  syntax Result ::= ok(List)
                  | fieldError()

  syntax KItem ::= clearSelectRelated(QueryState)
                 | onlyPk(QueryState)
                 | iteratorPks(QueryState)
                 | serializeM2MNonNatural(Source)
                 | serializeM2MNonNaturalOld(QueryState)

  syntax List ::= projectPks(List) [function]
endmodule

module MINI-SERIALIZER-QUERYSET
  imports MINI-SERIALIZER-QUERYSET-SYNTAX
  imports INT
  imports BOOL
  imports LIST

  configuration <k> $PGM:K </k>

  rule <k> serializeM2MNonNatural(cached(ROWS)) => ok(projectPks(ROWS)) ... </k>
  rule <k> serializeM2MNonNatural(uncached(QS))
        => iteratorPks(onlyPk(clearSelectRelated(QS))) ... </k>

  // Pre-fix behavior used for the counterexample: only("pk") was applied
  // while inherited select_related traversal remained present.
  rule <k> serializeM2MNonNaturalOld(QS)
        => iteratorPks(onlyPk(QS)) ... </k>

  // QuerySet.select_related(None): "clear the list".
  rule <k> clearSelectRelated(qs(_, LOAD, ROWS))
        => qs(noSelectRelated(), LOAD, ROWS) ... </k>

  // QuerySet.only("pk"): load only the primary key field.
  rule <k> onlyPk(qs(SEL, _, ROWS))
        => qs(SEL, onlyPkField(), ROWS) ... </k>

  // Iteration succeeds when no relation is being traversed while fields are
  // narrowed to the primary key.
  rule <k> iteratorPks(qs(noSelectRelated(), onlyPkField(), ROWS))
        => ok(projectPks(ROWS)) ... </k>

  // The reported FieldError condition: a selected relation is traversed while
  // only the pk field is in the selected-field mask.
  rule <k> iteratorPks(qs(someSelectRelated(), onlyPkField(), _ROWS))
        => fieldError() ... </k>

  rule projectPks(.List) => .List
  rule projectPks(ListItem(row(PK)) REST) => ListItem(PK) projectPks(REST)
endmodule
