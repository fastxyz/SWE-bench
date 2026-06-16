# SPEC_AUDIT

Status: constructed, not machine-checked.

## Adequacy Results

METADATA-MATRIX: pass. It directly encodes the public obligation that unused
`MatrixSymbol` arguments keep array shape metadata.

METADATA-KNOWN-ARRAY: pass. It preserves the pre-existing expression-derived
array behavior and supports shaped `IndexedBase` arguments added to
`array_symbols`.

METADATA-SCALAR: pass. Public intent does not require scalar redundant arguments
to become arrays.

ROUTINE-UNUSED-MATRIX: pass. It covers the issue reproducer's missing path.

ROUTINE-UNUSED-KNOWN-ARRAY: pass. It is a conservative extension for explicit
shaped indexed arrays and does not weaken the MatrixSymbol obligation.

ROUTINE-UNUSED-SCALAR: pass. It preserves scalar behavior.

ROUTINE-EXISTING-ARG: pass. It ensures V1 does not disturb already-correct
expression-derived arguments.

C-PROTOTYPE-ARRAY: pass. It matches the issue's required `double *x` output.

CYTHON-PROTOTYPE-ARRAY: pass. It matches the issue's requirement that the wrapper
accept a NumPy array.

CYTHON-CALL-ARRAY: pass. It matches the required data-pointer call path and
prevents scalar conversion.

## Scope Audit

The formal claims cover the C/Cython autowrap path named in the public issue.
They do not claim correctness for every specialized language-specific
`routine()` implementation in `codegen.py`. That omission does not block V1 for
this task because the public failure is a Cython backend failure with an
incorrect generated C signature.

## Adequacy Verdict

The formal English obligations are neither weaker nor stronger than the
C/Cython public intent. V1 may stand unchanged for this issue.

