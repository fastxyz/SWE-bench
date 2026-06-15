# Intent Spec

Status: intent-only English obligations from public evidence.

1. Ordinary lookup RHS values, including model instances, may define an
   application attribute or model field named `filterable`; that must not make
   Django reject them as non-filterable query expressions.
2. Real ORM expressions that participate in query expression resolution and set
   `filterable=False` must still be rejected from filter clauses.
3. Recursive validation of source expressions remains part of real expression
   filterability checking.
4. The repair must not alter public method signatures or test files.
