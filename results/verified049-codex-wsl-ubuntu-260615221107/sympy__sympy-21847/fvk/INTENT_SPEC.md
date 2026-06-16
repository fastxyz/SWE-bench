# Intent Spec

Status: constructed for audit, not machine-checked.

Target: `sympy.polys.monomials.itermonomials`, focused on the integer `max_degrees` / integer `min_degrees` total-degree mode changed by the V1 fix.

## Intent-Only Obligations

I1. Integer `max_degrees` and `min_degrees` define total-degree bounds. For every yielded monomial `m`, `min_degree <= total_degree(m) <= max_degree`.

I2. When `min_degrees` is omitted in integer mode, the lower bound is `0`.

I3. Mixed monomials count by total degree, not by the largest exponent of any single variable. For example, with variables `[x1, x2, x3]` and `min_degree = max_degree = 3`, monomials such as `x1*x2**2` and `x2*x3**2` are in scope.

I4. Raising `max_degree` above `min_degree` must not lose monomials whose total degree lies between the two bounds.

I5. The empty variable list has only the unit monomial `1`, whose total degree is `0`. Therefore integer mode returns `1` for empty variables exactly when `min_degree == 0` and `max_degree >= 0`; it returns no monomial when `min_degree > 0`.

I6. Negative integer `max_degree` or `min_degree` is outside the valid domain and should raise `ValueError`, matching existing public behavior and docs.

I7. List-valued `max_degrees` / `min_degrees` define per-variable bounds through `degree_list`, not total-degree bounds. The V1/V2 integer-mode fix must not change list mode.

I8. `itermonomials` is a generator of a set-like collection. No public evidence imposes a generator iteration order; examples sort or convert to `set`.

I9. Public API compatibility must be preserved: function name, arguments, return shape as generator, and existing callsites not passing `min_degrees` remain compatible.
