# Findings

Status: constructed for audit; not machine-checked.

## F-001: Resolved Root Cause - Positional-Only Default Lost

Classification: code bug, resolved by V1.

Input:

```rst
.. py:function:: foo(a, b=0, /, c=1)
```

Observed before V1:

The positional-only parameter `b` was represented without a default after
`signature_from_str()` converted the parsed AST into `inspect.Parameter`
objects, so `_parse_arglist()` had no `b=0` default to render.

Expected:

The default value is shown. The rendered signature must include `b=0`.

Trace:

- Public evidence: E1, E2, E3.
- Proof obligations: PO-001 through PO-005.

Resolution:

V1 pads `args.defaults` across `posonlyargs + args` and uses the padded slots for
both positional-only and ordinary positional parameters.

## F-002: No New Code Bug Found - V1 Matches The Intent Spec

Classification: confirmation finding.

Input family:

Any valid parsed signature where `arguments.defaults` applies to the suffix of
`posonlyargs + args`.

Expected:

Each positional parameter receives the default from its combined positional
index after left-padding.

Observed in V1 by static proof:

The padding loop constructs exactly that aligned defaults list, and the two
parameter loops index it at `i` and `len(posonlyargs) + i`.

Trace:

- Public evidence: E4.
- Proof obligations: PO-001, PO-002, PO-003, PO-006.

Resolution:

No source change beyond V1 is justified.

## F-003: Compatibility Preserved

Classification: compatibility finding, no defect.

Observed in V1 by static proof:

No function signature, return type, call protocol, or public consumer protocol
changed. `_parse_arglist()` was already designed to render any non-empty
`Parameter.default`.

Trace:

- Public evidence: E5, E7.
- Proof obligations: PO-007, PO-008.

Resolution:

No compatibility repair is needed.

## F-004: Proof Is Constructed, Not Machine-Checked

Classification: proof capability gap.

Observed:

This environment forbids running K tooling, tests, Python, or project code.

Expected before claiming machine verification:

Run the emitted commands in an environment with K installed and require
`kprove` to return `#Top`.

Trace:

- `fvk/PROOF.md`, "Reproduce the machine check"

Resolution:

Keep the proof labelled "constructed, not machine-checked." Do not remove tests
based on this proof alone.

## Proof-Derived Findings From Verify

No proof-derived code bug was found. The adequacy gate passed, the public
compatibility audit found no unhandled callsite or override, and all proof
obligations either discharge against the constructed K claims or against a
static source diff/frame argument.
