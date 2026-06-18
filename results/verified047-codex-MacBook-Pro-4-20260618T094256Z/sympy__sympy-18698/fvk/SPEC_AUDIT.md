# Spec Audit

Status: constructed, not machine-checked.

| Formal obligation | Intent comparison | Result |
|---|---|---|
| Claim 1 combines the reported multiplicity-3 pair. | Directly entailed by E1 and E2. | Pass |
| Claim 2 groups equal multiplicity beyond exponent 3. | Entailed by E4's "all factors of same degree" statement. | Pass |
| Claim 3 does not combine different generator keys. | Supported as a compatibility frame by E5 ambiguity and E6 public test. It is intentionally weaker than a broad multivariate grouping rule. | Pass for V1 revision discipline |
| Claim 4 leaves `factor` method unchanged. | Entailed by the issue scope and E7 implementation frame. | Pass |
| Claim 5 applies combination only for `sqf`. | Entailed by E3 and E7. | Pass |
| Claim 6 models the traversal as a guarded recursive step. | Implementation-derived control-flow model, used only for proof structure. | Pass |
| Arbitrary-list grouping theorem. | Required by the general intent, but only stated as an escalation-bounded residual rather than machine-proved here. | Ambiguous proof coverage, not a code bug |

## Adequacy Decision

The formal claims are adequate for deciding whether V1 should be edited in this
repair pass. They prove the reported bug shape and the regression-sensitive
frames in the constructed model. The only ambiguity is proof strength over all
finite lists and full SymPy polynomial algebra, which is a proof-capability
boundary rather than a concrete counterexample against V1.
