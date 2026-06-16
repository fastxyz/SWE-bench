# Formal Spec in English

Claim `AUTO-OVR-NO-INDEX-ERROR`: for binary data with
`multi_class='auto'` and a non-liblinear solver, the resolved mode is OvR; an
OvR-ranked coefficient path is selected with OvR indexing, producing `ok`.

Claim `LIBLINEAR-AUTO-OVR-NO-INDEX-ERROR`: for liblinear with
`multi_class='auto'`, the resolved mode is OvR even with more than two classes;
an OvR-ranked coefficient path is selected with OvR indexing, producing `ok`.

Claim `MULTINOMIAL-INDEX-OK`: for non-liblinear multiclass auto mode, the
resolved mode is multinomial; a multinomial-ranked coefficient path is selected
with multinomial indexing, producing `ok`.

Claim `NON-ELASTICNET-L1-ABSENT`: if the active penalty is not elastic-net,
l1-ratio selection yields `noneL1`.

Claim `ELASTICNET-L1-MEAN-OK`: if the active penalty is elastic-net and ratios
are valid list-like input, selected l1 ratios are averaged as `meanL1`.

Claims `SHAPE-PLAIN-WHEN-NON-ELASTICNET` and
`SHAPE-ELASTICNET-WHEN-ELASTICNET`: public path/scores/n_iter shapes expose an
l1-ratio axis exactly for elastic-net fits.
