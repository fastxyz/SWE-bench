# Formal Spec in English

- `WRAPPED-VALUE-NO-GROUP-BY`: for every constant value and every alias state,
  wrapping `Value` returns no group-by columns.
- `WRAPPER-DELEGATES-ALIAS-AWARE`: for every alias-aware child expression and
  every alias state, wrapping the child returns exactly the same group-by
  columns the child returns for that alias.
- `WRAPPER-PRESERVES-LEGACY-DEPRECATION`: for every legacy child expression
  whose `get_group_by_cols()` method lacks `alias`, wrapping the child emits the
  Django 3.2 deprecation warning and returns the child method's no-argument
  result rather than failing with a keyword-argument error.
- Frame condition: the wrapper method signature remains `alias=None`, and
  unrelated expression methods and classes are unchanged.
