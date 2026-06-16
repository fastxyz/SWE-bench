# PUBLIC_COMPATIBILITY_AUDIT

Status: constructed, not machine-checked.

## Changed Symbols

`CodeGen._get_input_arg_metadata`

- Kind: new private helper.
- Public API impact: none. No public caller is required to pass new arguments or
  consume a new return type.
- Compatibility status: pass.

`CodeGen.routine`

- Kind: existing method, unchanged signature.
- Public API impact: behavior changes only for explicit redundant array
  arguments that previously lost dimensions. Existing scalar redundant arguments
  remain scalar, existing expression-derived arguments are reused, and existing
  missing-argument errors remain.
- Compatibility status: pass.

## Downstream Consumers

`CCodeGen.get_prototype`

- Consumes `arg.dimensions` to choose pointer arguments. V1 supplies the
  dimensions that this consumer already expected for arrays.
- Compatibility status: pass.

`CythonCodeWrapper._prototype_arg` and `_call_arg`

- Consume `arg.dimensions` to choose ndarray wrapper arguments and data-pointer
  calls. V1 supplies the dimensions that these consumers already expected for
  arrays.
- Compatibility status: pass.

## Public Callsite and Override Search

No public function signature was changed. No subclass override must accept a new
keyword or positional argument. The changed behavior flows through existing
`InputArgument.dimensions` metadata.

## Verdict

No public compatibility blocker was found.

