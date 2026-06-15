requires "mini-django-expressions.k"

module EXPRESSION-WRAPPER-SPEC
  imports MINI-DJANGO-EXPRESSIONS

  // SPEC-PROVENANCE:
  // - E-001/E-002/E-007: wrapped constants must be omitted from GROUP BY.
  claim <k> wrapperGroupBy(Wrapper(Value(V)), A) => Ok(NoCols) </k>
    [all-path, label(WRAPPED-VALUE-NO-GROUP-BY)]

  // SPEC-PROVENANCE:
  // - E-003/E-004/E-008: wrappers must preserve alias-aware child grouping.
  claim <k> wrapperGroupBy(Wrapper(AliasAware(Name, Cs)), A)
        => childGroupBy(AliasAware(Name, Cs), A) </k>
    [all-path, label(WRAPPER-DELEGATES-ALIAS-AWARE)]

  // SPEC-PROVENANCE:
  // - E-005/E-006: missing-alias child overrides remain deprecated but usable.
  claim <k> wrapperGroupBy(Wrapper(LegacyNoAlias(Name, Cs)), A)
        => Warn(Name, Cs) </k>
    [all-path, label(WRAPPER-PRESERVES-LEGACY-DEPRECATION)]
endmodule
