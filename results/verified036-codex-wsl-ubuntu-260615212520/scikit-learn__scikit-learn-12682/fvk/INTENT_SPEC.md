# Intent Spec

Status: intent-first specification, before relying on V1 behavior.

## Required Behavior

1. `SparseCoder` users must have an exposed way to control the maximum
   iteration limit used by the lasso-family estimator selected for transform.
   Public evidence: the issue says "`SparseCoder` doesn't expose `max_iter`"
   and asks for a user-specifiable estimator parameter.

2. The existing `max_iter` control must reach the `LassoLars` backend used by
   `algorithm='lasso_lars'`. Public evidence: the hint says "`max_iter` is ...
   not passed to `LassoLars`" and "just fixing it to pass to LassoLars seems
   sensible."

3. The existing `max_iter` control for `algorithm='lasso_cd'` must keep reaching
   the coordinate-descent `Lasso` backend. Public evidence: the issue describes
   `Lasso` as the backend and identifies `max_iter` as the missing control.

4. The new estimator-level control should follow the existing transform
   parameter naming convention. Public evidence: the public estimator API
   already names transform-time controls `transform_algorithm`,
   `transform_alpha`, and `transform_n_nonzero_coefs`.

5. Existing public constructor calls should remain source compatible. Public
   evidence: the task asks for a minimal targeted fix, not an unrelated API
   break.

6. Non-lasso sparse coding algorithms (`lars`, `omp`, `threshold`) should not
   acquire new behavior from this fix. Public evidence: the issue is scoped to
   lasso-family estimator iteration limits.

## Explicit Non-goals

- Do not add generic `algorithm_kwargs`; the public hint considered that but
  narrowed the resolution to forwarding the missing `max_iter`.
- Do not prove or guarantee numerical convergence for every sparse coding
  problem. The obligation is parameter exposure and forwarding.
- Do not modify tests or run tests, Python, or K tooling in this environment.
