# Intent Spec

Status: constructed, not machine-checked.

I1. A Python enum member used as a function default must render as a readable
member reference, not Python's default enum `repr`.

I2. The expected direct enum-member form is `EnumClass.Member`, matching the
issue's expected `MyEnum.ValueA` and omitting the module prefix.

I3. Existing non-enum default formatting must be preserved: dictionaries, sets,
frozensets, generic `repr`, memory-address stripping, and newline normalization
are outside the reported bug.

I4. Signature spacing around defaults must remain unchanged. Only the default
value text changes for enum members.

I5. `EnumClass.Member` is valid only when a member spelling exists. Named flag
combinations should qualify every component; nameless enum values must not be
rendered as `EnumClass.None`.
