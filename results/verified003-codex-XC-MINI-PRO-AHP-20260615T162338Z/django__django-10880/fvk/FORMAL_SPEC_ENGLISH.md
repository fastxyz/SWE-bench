# Formal Spec English

Status: constructed, not machine-checked.

K claim 1 says: rendering a distinct `COUNT` aggregate whose expression SQL begins with `CASE WHEN P ...` must produce `COUNT(DISTINCT CASE WHEN P THEN X ELSE NULL END)`. The required output has a space between `DISTINCT` and `CASE`.

K claim 2 says: rendering the same `COUNT` aggregate without `distinct` must produce `COUNT(CASE WHEN P THEN X ELSE NULL END)`. No extra separator is introduced when the distinct marker is empty.

K claim 3 says: when a conditional aggregate is implemented by rewriting the filter into a `CASE` expression, a distinct `COUNT` must still produce `COUNT(DISTINCT CASE WHEN P THEN X ELSE NULL END)`.

K claim 4 says: when a backend supports SQL aggregate `FILTER`, a distinct `COUNT` with expression `X` and filter `P` must produce `COUNT(DISTINCT X) FILTER (WHERE P)`.

The mini semantics abstracts away compiler argument parameter lists and database quoting because the issue concerns only token adjacency in the aggregate SQL template. It preserves the observable property under test: whether the generated SQL contains `DISTINCTCASE` or `DISTINCT CASE`.
