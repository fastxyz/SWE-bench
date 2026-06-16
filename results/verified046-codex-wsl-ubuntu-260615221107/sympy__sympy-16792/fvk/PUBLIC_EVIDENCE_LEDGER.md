# PUBLIC_EVIDENCE_LEDGER

Status: constructed, not machine-checked.

## E1

Source: prompt / issue.

Quoted evidence: "This should of course return `1.0`".

Semantic obligation: Cython autowrap must accept the explicit ndarray argument
and return the constant expression result.

Spec status: encoded in SPEC P4 and P6.

## E2

Source: prompt / issue.

Quoted evidence: "`x` should be `double *`, not `double` in this case".

Semantic obligation: unused `MatrixSymbol` arguments must carry non-empty
dimensions into C prototype generation.

Spec status: encoded in SPEC P2, P4, and P6.

## E3

Source: prompt / issue.

Quoted evidence: "pre-defined signature regardless of whether a given argument
contributes to the output".

Semantic obligation: explicit arguments are preserved even when redundant.

Spec status: encoded in SPEC P4 and P5.

## E4

Source: public API docs in `repo/sympy/utilities/codegen.py`.

Quoted evidence: "Redundant arguments are used without warning."

Semantic obligation: redundant explicit arguments are valid routine arguments.

Spec status: encoded in SPEC P4.

## E5

Source: implementation consumer in `CCodeGen.get_prototype`.

Quoted evidence: `if arg.dimensions or isinstance(arg, ResultBase)`.

Semantic obligation: `dimensions` is the operative field for pointer C
parameters.

Spec status: encoded in SPEC P6.

## E6

Source: implementation consumer in `CythonCodeWrapper`.

Quoted evidence: `np.ndarray[...]` and `<{0}*> {1}.data` are selected when
`arg.dimensions` is truthy.

Semantic obligation: `dimensions` is the operative field for ndarray wrapper
parameters and pointer calls.

Spec status: encoded in SPEC P6.

