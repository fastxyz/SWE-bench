# Formal Spec English

Status: constructed, not machine-checked.

K1. `objectDescription(enumNamed(C, N, R))` reaches `C.N` for every non-empty
enum member name `N`.

K2. `objectDescription(flagNamed(C, N1|...|Nk, R))` reaches
`C.N1|...|C.Nk`, qualifying every flag component.

K3. `objectDescription(enumUnnamed(C, R))` reaches the cleaned repr fallback
`R`, not `C.None`.

K4. `objectDescription(other(R))` reaches the cleaned repr fallback `R`.

K5. `stringifyDefault(P, O)` reaches `P` followed by `objectDescription(O)`,
so enum default text propagates into the signature default slot.
