# Formal Spec English

Status: paraphrase of the constructed K claims.

`NON-EXPRESSION-RHS`: any value without `resolve_expression` is accepted by
`check_filterable()` for purposes of expression filterability, regardless of a
`filterable` attribute or a `get_source_expressions` method.

`NON-FILTERABLE-EXPRESSION`: any value with `resolve_expression` and
`filterable=False` is rejected with `NotSupportedError`.

`FILTERABLE-EXPRESSION-NO-SOURCES`: any value with `resolve_expression`,
`filterable=True`, and no source-expression walk is accepted.

`FILTERABLE-EXPRESSION-SOURCES`: any value with `resolve_expression`,
`filterable=True`, and source expressions is accepted exactly when every source
expression is accepted by the same contract; the first rejected source causes
rejection.
