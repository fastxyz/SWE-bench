# Formal Spec In English

Status: constructed, not machine-checked.

Claim C1: Matching the escaped admin primary-key regex against a generated
field-name key is true exactly when the key has the literal prefix, a hyphen,
one or more decimal digits, another hyphen, and the literal primary-key field
name.

Claim C2: Scanning POST items with that predicate returns every matching value
and no non-matching value.

Claim C3: The scan preserves the relative order of matching POST items.

Claim C4: The source patch preserves the helper signature, return type, caller,
and queryset validation flow.

