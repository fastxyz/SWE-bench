requires "mini-django-expressions.k"

module TEMPORAL-SUBTRACTION-SPEC
  imports MINI-DJANGO-EXPRESSIONS

  // SPEC-PROVENANCE:
  // - E1: "make temporal subtraction work without ExpressionWrapper"
  // - E6: public tests wrap date subtraction with DurationField.
  // Claim ID: DATE-SUB
  claim <k> resolveOutput(SUB, DateField, DateField) => DurationField </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E1/E2: the reported issue uses DateTimeField subtraction.
  // - E4: TemporalSubtraction.output_field is DurationField.
  // Claim ID: DATETIME-SUB
  claim <k> resolveOutput(SUB, DateTimeField, DateTimeField) => DurationField </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E1/E6: time subtraction is in the same existing temporal family.
  // Claim ID: TIME-SUB
  claim <k> resolveOutput(SUB, TimeField, TimeField) => DurationField </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E2/E3: the issue expression must not be typed as DateTimeField + DurationField.
  // Claim ID: ISSUE-NESTED-DATETIME-DURATION
  claim
    <k> resolveOutput(
          ADD,
          resolveOutput(SUB, DateTimeField, DateTimeField),
          DurationField
        ) => DurationField </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E7: preserve generic same-type inference for non-special cases.
  // Claim ID: GENERIC-SAME-DURATION
  claim <k> resolveOutput(ADD, DurationField, DurationField) => DurationField </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E7: direct mixed DateTimeField + DurationField remains a generic FieldError.
  // Claim ID: GENERIC-MIXED-DATETIME-DURATION
  claim <k> resolveOutput(ADD, DateTimeField, DurationField) => FieldError </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E7: same non-temporal types continue through the base resolver.
  // Claim ID: GENERIC-SAME-INTEGER
  claim <k> resolveOutput(ADD, IntegerField, IntegerField) => IntegerField </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E4/E5: SQL rendering already routes same-type temporal subtraction to
  //   TemporalSubtraction and must remain aligned with output inference.
  // Claim ID: SQL-TEMPORAL-SUBTRACTION
  claim <k> sqlKind(SUB, DateTimeField, DateTimeField) => TemporalSubtractionSQL </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E4: TemporalSubtraction.output_field is DurationField.
  // Claim ID: SQL-TEMPORAL-SUBTRACTION-OUTPUT
  claim <k> sqlOutput(sqlKind(SUB, DateTimeField, DateTimeField)) => DurationField </k>
    [all-path]
endmodule
