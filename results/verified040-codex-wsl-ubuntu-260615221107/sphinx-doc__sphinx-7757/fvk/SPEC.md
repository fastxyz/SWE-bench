# FVK Specification

Status: constructed for audit; not machine-checked.

## Target

The target is the V1 source change in `repo/sphinx/util/inspect.py`,
`signature_from_str(signature: str)`, and its observable use by
`repo/sphinx/domains/python.py`, `_parse_arglist(arglist: str)`.

This is a repair-focused FVK scope for issue `sphinx-doc__sphinx-7757`, not a
whole-repository proof.

## Public Intent Ledger

Critical entries are mirrored from `fvk/PUBLIC_EVIDENCE_LEDGER.md`:

- E1: The issue says positional-only defaults vanished. Obligation: preserve
  defaults on positional-only parameters.
- E2: The issue example `foo(a, b=0, /, c=1)` must show the default for `b`.
- E3: The expected behavior says "The default value is shown." Obligation: the
  default must reach the normal rendered output path.
- E4: Python AST/default-domain evidence: positional defaults align against the
  combined positional list `posonlyargs + args`; Sphinx's own AST unparser uses
  that alignment.
- E5: Visible public tests already cover ordinary defaults, keyword-only
  parameters, and positional-only parameter kind. Obligation: do not regress
  those behaviors.
- E7: Source callsites use the existing helper API. Obligation: no public API
  shape change.

## Domain

Inputs are signatures accepted by the parser call:

```python
ast.parse('def func' + signature + ': pass')
```

The formal model starts after parsing, at the AST `arguments` record:

- `P`: list of positional-only arguments, possibly empty on Python versions or
  AST providers without `posonlyargs`
- `A`: list of positional-or-keyword arguments
- `D`: `arguments.defaults`, the Python AST list of defaults for the final
  positional parameters in `P + A`

Domain precondition:

```text
0 <= len(D) <= len(P) + len(A)
```

Invalid Python signatures and parser errors are outside this contract.

## Intended Postconditions

O1. Let `T = len(P) + len(A)`. Let `AD = left_pad(noDefault, T - len(D), D)`.
For each positional-only argument `P[i]`, the returned `inspect.Parameter`
default is:

```text
Parameter.empty        if AD[i] is noDefault
ast_unparse(AD[i])     otherwise
```

O2. For each positional-or-keyword argument `A[j]`, the returned
`inspect.Parameter` default is:

```text
Parameter.empty        if AD[len(P) + j] is noDefault
ast_unparse(AD[len(P) + j]) otherwise
```

O3. `_parse_arglist()` displays a default whenever the corresponding
`inspect.Parameter.default` is not `Parameter.empty`. Therefore the issue input
`foo(a, b=0, /, c=1)` renders parameters equivalent to:

```text
a, b=0, /, c=1
```

O4. `/` separator insertion is still controlled only by `Parameter.kind`
transitions and is not changed by default alignment.

O5. Keyword-only parameters, varargs, kwargs, annotations, and return annotation
handling are frame properties of this fix and remain governed by the preexisting
code paths.

O6. When `len(P) == 0`, the default alignment degenerates to the old ordinary
positional behavior: pad `D` to `len(A)` and use `AD[j]` for `A[j]`.

## Formal Core

The non-optional K-style core is included in:

- `fvk/mini-signature-parser.k`
- `fvk/signature-from-str-spec.k`

Exact commands to machine-check later, not executed in this environment:

```sh
kompile fvk/mini-signature-parser.k --backend haskell
kast --backend haskell fvk/signature-from-str-spec.k
kprove fvk/signature-from-str-spec.k
```

Expected result after a real K run: `#Top`.
