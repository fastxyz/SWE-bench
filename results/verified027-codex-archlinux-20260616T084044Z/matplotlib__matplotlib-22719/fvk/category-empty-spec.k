requires "mini-category.k"

module CATEGORY-EMPTY-SPEC
  imports MINI-CATEGORY
  imports LIST

  // SPEC-PROVENANCE:
  // - E1/E3: empty data is in-domain and should produce no-data artists.
  // - E2: the pre-fix empty-data deprecation warning is the reported bug.
  // - E5: public hint requires values.size before is_numlike.
  claim [CONVERT-EMPTY-VACUOUS-NUMERIC]:
    <k> convert(0, true, true) => .K </k>
    <warnings> .List </warnings>
    <logs> .List </logs>
    <resultSize> 0 => 0 </resultSize>
    <status> ok => ok </status>
    [all-path]

  // SPEC-PROVENANCE:
  // - E7: public tests expect non-empty numeric pass-through to warn.
  // - E5: values.size guard remains true for N > 0.
  claim [CONVERT-NONEMPTY-NUMERIC]:
    <k> convert(N:Int, true, UPDATEOK:Bool) => .K </k>
    <warnings> .List => ListItem(deprecatedNumeric) .List </warnings>
    <logs> .List </logs>
    <resultSize> 0 => N </resultSize>
    <status> ok => ok </status>
    requires N >Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - E8/E9: non-empty categorical values still use UnitData.update.
  // - E5: false all-numlike data should not emit numeric warning.
  claim [CONVERT-NONEMPTY-CATEGORICAL]:
    <k> convert(N:Int, false, true) => .K </k>
    <warnings> .List </warnings>
    <logs> .List </logs>
    <resultSize> 0 => N </resultSize>
    <status> ok => ok </status>
    requires N >Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - E8: public tests expect non-empty mixed categorical/numeric values to
  //   fail validation rather than silently convert.
  claim [CONVERT-NONEMPTY-INVALID]:
    <k> convert(N:Int, false, false) => .K </k>
    <warnings> .List </warnings>
    <logs> .List </logs>
    <status> ok => typeError </status>
    requires N >Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - E6: public hint requires data.size before convertible.
  // - E10: empty data leaves all-convertible true by vacuity.
  claim [UPDATE-EMPTY-CONVERTIBLE]:
    <k> update(0, true) => .K </k>
    <warnings> .List </warnings>
    <logs> .List </logs>
    <status> ok => ok </status>
    [all-path]

  // SPEC-PROVENANCE:
  // - E6: non-empty all-convertible logging is preserved.
  claim [UPDATE-NONEMPTY-CONVERTIBLE]:
    <k> update(N:Int, true) => .K </k>
    <warnings> .List </warnings>
    <logs> .List => ListItem(allConvertible) .List </logs>
    <status> ok => ok </status>
    requires N >Int 0
    [all-path]
endmodule
