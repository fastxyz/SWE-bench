# Intent Specification

Status: intent-only, before accepting implementation behavior as the spec.

1. Aggregating over a selected annotation that contains a window expression must
   not generate SQL where an aggregate function directly contains a window
   function.
2. The issue's in-scope usage is annotation-based: a queryset first annotates
   `cumul_DJR` with `Window(...)`, then calls `aggregate()` with
   `Sum("cumul_DJR")`.
3. Django's documented aggregate behavior allows aggregate expressions to
   reference aliases defined by `annotate()`.
4. Django's documented window behavior presents window expressions as selected
   columns produced by `annotate()`.
5. Existing aggregate wrapping behavior for grouping, slicing, existing
   aggregation, subquery references, qualify filters, distinct, and combinators
   must be preserved.
6. No public method signature, return shape, or expression API should change.

Ambiguous:

- Direct nested aggregate expressions over a `Window`, such as
  `aggregate(total=Sum(Window(...)))`, are not established by the public issue
  example or docs evidence gathered in this audit.
