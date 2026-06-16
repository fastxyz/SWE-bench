# Intent Specification

Status: constructed, not machine-checked.

I1. `roc_curve` accepts target scores that can be probability estimates,
confidence values, or decision-function scores.

I2. Returned rates are defined by applying each threshold with
`score >= thresholds[i]`.

I3. The first ROC threshold position is artificial and represents no instances
being predicted, giving the initial zero-count ROC point on meaningful
two-class inputs.

I4. For probability-estimate scores in `[0, 1]`, `roc_curve` must not fabricate
a finite threshold greater than 1. The artificial first value may be a sentinel
that is explicitly not an observed probability threshold.

I5. The fix must preserve the public `roc_curve` signature, output shape
alignment, and ordinary validation behavior.

I6. Public examples or tests showing `max(y_score) + 1` as the first threshold
are suspect legacy evidence when they conflict with I4.
