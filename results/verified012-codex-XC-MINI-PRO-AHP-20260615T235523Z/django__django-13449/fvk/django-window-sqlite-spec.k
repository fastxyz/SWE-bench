requires "mini-django-sqlite-window.k"

module DJANGO-WINDOW-SQLITE-SPEC
  imports MINI-DJANGO-SQLITE-WINDOW

  // SPEC-PROVENANCE:
  // - from_prompt: "CAST() statement ends after LAG whereas it should be around the whole statement"
  //   => Decimal Lag inside Window on SQLite must compile as castNumeric(over(raw(lag))).
  // - from_code: Window.as_sqlite clones the source expression with FloatField output before
  //   delegating to SQLiteNumericMixin on the Window clone.
  claim
    <k> compileWindowSqlite(decimal, source(lag, decimal))
      => castNumeric(over(raw(lag))) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "Lag('data', 7)" for FloatField works correctly
  //   => non-Decimal windows keep the existing uncast window SQL shape.
  // - from_code: Window.as_sqlite falls back to as_sql() when output_field is not DecimalField.
  claim
    <k> compileWindowSqlite(float, source(lag, float))
      => over(raw(lag)) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_hint: "make sure window compatible functions can be used outside of windows expressions
  //   while being wrapped appropriately"
  //   => standalone Decimal Func/aggregate SQLite casting remains unchanged.
  // - from_code: SQLiteNumericMixin.as_sqlite is unchanged for Func and Aggregate.
  claim
    <k> compileStandaloneSqlite(source(lag, decimal))
      => castNumeric(raw(lag)) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_hint: Window-level handling is about Decimal-valued window expressions, not only Lag.
  // - from_code: Window.as_sqlite keys on Window.output_field, so Decimal aggregates in Window
  //   receive the same outer cast treatment.
  claim
    <k> compileWindowSqlite(decimal, source(aggregate, decimal))
      => castNumeric(over(raw(aggregate))) </k>
    [all-path]
endmodule
