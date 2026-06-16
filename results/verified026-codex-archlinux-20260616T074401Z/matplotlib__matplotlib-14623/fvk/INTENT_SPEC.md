# Intent Spec

Status: constructed from public evidence only; not machine-checked.

## Required Behavior

1. For a log-scaled Matplotlib axis, explicit finite positive limits supplied in
   reverse order must remain reversed. This is the axis-inversion API: the
   stored view interval order is semantically observable.

2. The behavior must apply to the reproduction shape
   `ax.set_yscale("log"); ax.set_ylim(y.max(), y.min())` where
   `y.max() > y.min() > 0`.

3. The same locator normalization is used by both x and y log axes, so the
   order-preservation requirement applies to either axis when finite positive
   explicit limits are reversed.

4. Log axes only accept positive explicit limits. Nonpositive explicit axis
   limits are already warned about and ignored by `set_xlim` / `set_ylim`; this
   audit does not change that domain policy.

5. Unequal finite positive limits are not a singular interval. Normalization may
   validate them, but must not reorder them.

6. Equal finite positive limits may still be expanded to avoid a singular
   transform. Equality does not carry an inversion direction.

7. Tick placement may internally sort a reversed view interval for calculation,
   but that internal sorting must not change the stored axis view interval.

