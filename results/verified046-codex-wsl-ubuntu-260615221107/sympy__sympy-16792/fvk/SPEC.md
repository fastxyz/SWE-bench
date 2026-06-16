# SPEC

Status: constructed, not machine-checked.

## Scope

This FVK pass audits the V1 change for `sympy.utilities.codegen.CodeGen`.
The observable under verification is the code-generation metadata that decides
whether an explicit unused array argument is emitted as an array/pointer argument
or as a scalar argument.

The audited source paths are:

- `repo/sympy/utilities/codegen.py`
  - `CodeGen._get_input_arg_metadata`
  - `CodeGen.routine`, specifically construction of redundant
    `InputArgument`s from `argument_sequence`
  - `CCodeGen.get_prototype`, as the downstream consumer of `arg.dimensions`
- `repo/sympy/utilities/autowrap.py`
  - `CythonCodeWrapper._prototype_arg`
  - `CythonCodeWrapper._call_arg`

## Intent-Only Contract

For C/Cython autowrap, an explicit array argument supplied through `args` /
`argument_sequence` must keep its array nature even when the wrapped expression
does not reference that argument. In particular, a `MatrixSymbol('x', r, c)` in
the explicit argument sequence is in-domain for all positive dimensions `r` and
`c`, and the generated routine argument must have dimensions
`[(0, r - 1), (0, c - 1)]`.

That metadata must make the C prototype use a pointer argument, not a scalar
argument, and must make the Cython wrapper accept a NumPy ndarray and pass its
data pointer to C.

## Preconditions

- `argument_sequence` is supplied by the caller.
- The required expression-derived arguments are all present in
  `argument_sequence`; otherwise the existing `CodeGenArgumentListError`
  behavior remains in force.
- Matrix array arguments are represented as `MatrixSymbol` instances with a
  non-empty declared shape.
- `IndexedBase` arguments are treated as arrays only when they carry explicit
  shape information or are already discoverable from the expression's indexed
  atoms.

## Postconditions

P1. `_get_input_arg_metadata(symbol, array_symbols)` returns
`{'dimensions': [(0, dim - 1), ...]}` when `symbol` is present in
`array_symbols` and that array has a shape.

P2. `_get_input_arg_metadata(symbol, array_symbols)` returns
`{'dimensions': [(0, dim - 1), ...]}` when `symbol` is a `MatrixSymbol`, even if
it is not present in `array_symbols`.

P3. `_get_input_arg_metadata(symbol, array_symbols)` returns `{}` when `symbol`
is not a known shaped array and is not a `MatrixSymbol`.

P4. In `CodeGen.routine`, when an explicit argument is not already present in
`name_arg_dict`, the synthesized `InputArgument` is created with the metadata
from P1-P3.

P5. Existing expression-derived arguments and existing output/inout arguments
are preserved by the reordering path because `name_arg_dict[symbol]` is reused
when available.

P6. In C code generation, any argument with non-empty `dimensions` is emitted as
`<ctype> *<name>`. In Cython wrapping, any argument with non-empty `dimensions`
is exposed as an `np.ndarray[...]` and passed to C as `<ctype*> name.data`.

## Frame Conditions

- Scalar redundant arguments remain scalar.
- Existing missing-required-argument errors are unchanged.
- Existing expression-derived array arguments keep the same metadata as before.
- The public signatures of `CodeGen.routine`, `codegen`, `make_routine`, and
  `autowrap` are unchanged.
- No test files are modified.

## Public Intent Ledger

1. Source: prompt / issue.
   Quote: "`x` should be `double *`, not `double` in this case".
   Obligation: unused `MatrixSymbol` arguments must produce non-empty
   dimensions and therefore pointer C parameters.
   Status: encoded by P2, P4, and P6.

2. Source: prompt / issue.
   Quote: "This should of course return `1.0`".
   Obligation: the generated wrapper must accept the ndarray argument and return
   the constant result instead of failing during scalar conversion.
   Status: encoded by P4 and P6.

3. Source: prompt / issue.
   Quote: "one often needs functions to have a pre-defined signature regardless
   of whether a given argument contributes to the output".
   Obligation: explicit argument sequence entries are semantically part of the
   requested signature independent of expression free symbols.
   Status: encoded by P4 and P5.

4. Source: public API docs in `repo/sympy/utilities/codegen.py`.
   Quote: "Redundant arguments are used without warning."
   Obligation: an explicit argument not needed by the expression is still a
   routine argument, not an error or ignored entry.
   Status: encoded by P4.

5. Source: implementation consumer in `CCodeGen.get_prototype`.
   Quote: `if arg.dimensions or isinstance(arg, ResultBase): ... "*%s"`.
   Obligation: `dimensions` is the data-flow fact that selects pointer C
   parameters.
   Status: encoded by P6.

6. Source: implementation consumer in `CythonCodeWrapper`.
   Quote: `if arg.dimensions: ... np.ndarray` and
   `return "<{0}*> {1}.data"`.
   Obligation: `dimensions` is the data-flow fact that selects ndarray wrapper
   arguments and data-pointer calls.
   Status: encoded by P6.

## Formal Files

- `fvk/mini-codegen.k`: minimal K fragment modeling shaped/scalar arguments,
  redundant argument construction, C prototype selection, and Cython wrapper
  selection.
- `fvk/codegen-spec.k`: reachability claims for the postconditions above.

