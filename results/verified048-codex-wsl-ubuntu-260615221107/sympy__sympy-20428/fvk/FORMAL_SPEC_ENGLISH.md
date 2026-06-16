# Formal Spec in English

Status: constructed, not machine-checked.

The K claims in `fvk/clear-denoms-spec.k` state the following:

1. `DUP-CLEAR-DENOMS-CANONICAL`: for any univariate dense polynomial list `F`,
   `dupClearDenoms(F)` returns `pair(C, R)` where `C` is the accumulated lcm of
   the denominators of coefficients in `F`, and `R` is `dupStrip(dupMulGround(F,
   C))`. Therefore, if multiplying by `C` makes the leading coefficient zero,
   the returned list has that zero stripped.
2. `DUP-CLEAR-DENOMS-ZERO`: for a one-term polynomial whose term becomes zero
   after multiplication by the common denominator, `dupClearDenoms` returns the
   empty dense list `.Poly`, the univariate canonical zero.
3. `DMP-CLEAR-DENOMS-CANONICAL`: for a recursive dense polynomial `F`,
   `dmpClearDenoms(F)` returns `dpair(C, R)` where `C` is the recursive lcm of
   all ground denominators and `R` is `recStrip(dmpMulGround(F, C))`. Therefore
   inner zero polynomial coefficients are stripped before outer leading-zero
   stripping.
4. `DMP-CLEAR-DENOMS-INNER-ZERO`: for a recursive dense polynomial whose only
   inner coefficient polynomial becomes zero after multiplication, the returned
   representation is the recursive canonical zero.

Frame and compatibility properties:

1. The claims do not change the shape of public return values: the result remains
   a pair `(common, dense_representation)` at the dense helper level and a pair
   `(coeff, Poly)` at the `Poly.clear_denoms()` level.
2. The claims preserve the algebraic denotation of denominator clearing. The only
   intended representation change is removal of leading zero terms that denote
   no polynomial content.
3. The claims do not require changing the expression simplifier or domain
   arithmetic; they act after multiplication has produced a coefficient the
   domain recognizes as zero.
