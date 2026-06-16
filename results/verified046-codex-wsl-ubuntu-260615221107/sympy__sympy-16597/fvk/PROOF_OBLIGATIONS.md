# Proof Obligations

Status: constructed, not machine-checked.

## PO-1: Rational implies finite

Statement: in the old assumptions closure, any fact set containing
`rational=True` closes to a fact set containing `finite=True`.

Evidence: public hint E-4.

Discharge: V1 adds `_assume_rules` entry `rational -> finite`; K claim D models
this edge directly.

Status: discharged by constructed proof.

## PO-2: Parity implies finite

Statement: in the old assumptions closure, any fact set containing `even=True`
or `odd=True` closes to a fact set containing `finite=True`.

Evidence: issue evidence E-1 and E-2.

Discharge: existing `even -> integer` and `odd -> integer`, existing
`integer -> rational`, and V1 `rational -> finite`.

Status: discharged by constructed proof.

## PO-3: Integer implies finite

Statement: in the old assumptions closure, any fact set containing
`integer=True` closes to a fact set containing `finite=True`.

Evidence: issue evidence E-3.

Discharge: existing `integer -> rational`, then V1 `rational -> finite`.

Status: discharged by constructed proof.

## PO-4: Leaf-rule duplication is unnecessary

Statement: no separate `integer -> finite`, `even -> finite`, or `odd -> finite`
rules are required if PO-1 is true and the existing implication graph remains
intact.

Evidence: old rules in `sympy/core/assumptions.py`.

Discharge: graph paths in PO-2 and PO-3.

Status: discharged by constructed proof.

## PO-5: Do not globally narrow old `real`

Statement: this issue fix must not add `finite=True` solely from
old-assumption `real=True`.

Evidence: public hint E-5.

Discharge: V1 does not add `real -> finite`; K claim E frames this behavior.

Status: discharged by constructed proof.

## PO-6: Preserve unknown generic finiteness

Statement: a symbol with no relevant numeric-set assumptions must not acquire
`finite=True` from this patch.

Evidence: old assumptions docs describe `None` for undetermined facts.

Discharge: V1 only adds an implication with antecedent `rational=True`; K claim F
frames the empty fact set.

Status: discharged by constructed proof.

## PO-7: Keep newer `ask(Q.*)` table changes out of this patch

Statement: the V1 confirmation is valid only for old `.is_*` assumptions. The
newer `ask` generated tables are not changed in this pass.

Evidence: issue examples use `.is_finite`; public hint names `_assume_rules`;
public compatibility audit notes generated-file and sign/finite interactions.

Discharge: source diff touches only `sympy/core/assumptions.py`.

Status: accepted scope boundary; not a code proof obligation for this issue.
