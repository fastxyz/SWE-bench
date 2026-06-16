# FVK Notes

The FVK audit confirms V1 unchanged.

Decision: keep the scalar-zero branch in `repo/sympy/physics/vector/vector.py`.
This is justified by FVK-F1 and proof obligations PO1, PO2, and PO4: the public
failure is caused by `sum()` starting with scalar `0`, reflected addition
reaching `Vector.__add__`, and `_check_vector(0)` rejecting the additive
identity before vector addition can proceed.

Decision: do not modify `_check_vector()`. This is justified by FVK-F3 and
proof obligations PO5 and PO6. `_check_vector()` is shared by dot, cross, outer
product, frame setters, point setters, and helper APIs; coercing scalar zero
there would broaden non-add APIs beyond the issue's intent.

Decision: do not add a separate `__radd__` method. PO2 is already discharged by
the existing `__radd__ = __add__` alias once `__add__` handles scalar zero.
Adding a second method would duplicate behavior without improving the proof.

Decision: do not change `sympy.vector` or `Dyadic`. FVK-F5's scope review and
PO7 show the public traceback and issue identify `sympy.physics.vector.Vector`
only. No public evidence requires touching parallel vector implementations.

Decision: do not run tests or K tooling. This follows the task constraints and
is recorded in FVK-F4 and PO8. The proof artifacts include the commands that
should be run later in an environment where execution is allowed.
