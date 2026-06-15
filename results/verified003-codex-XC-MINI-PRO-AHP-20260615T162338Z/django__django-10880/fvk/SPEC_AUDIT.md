# Spec Audit

Status: constructed, not machine-checked.

Claim 1 vs intent: pass.

Reason: I-1 and I-2 require distinct `Count(Case(...))` to render valid SQL, and E-2 specifically identifies the missing separator between `DISTINCT` and `CASE`.

Claim 2 vs intent: pass.

Reason: I-3 requires preserving non-distinct rendering. The formal claim proves the marker is empty when `distinct=False`, so the aggregate remains `COUNT(<expression>)`.

Claim 3 vs intent: pass.

Reason: I-2 and E-3 require backend-independent correctness. The fallback path is the path where Django rewrites conditional aggregation to `CASE`, and the claim keeps the separator in that path.

Claim 4 vs intent: pass.

Reason: I-2 and E-3 also cover backends with native aggregate `FILTER` support. The base aggregate inside the filter wrapper still separates `DISTINCT` from the expression.

Adequacy discriminator: pass.

Passing instance: `aggregateSql(true, "COUNT", "CASE WHEN P THEN X ELSE NULL END")` maps to `COUNT(DISTINCT CASE WHEN P THEN X ELSE NULL END)`.

Failing instance: the pre-V1 marker `DISTINCT` without trailing space would map to `COUNT(DISTINCTCASE WHEN P THEN X ELSE NULL END)`.

The model distinguishes these strings, so it has not abstracted away the property being audited.
