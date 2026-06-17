# FVK Specification

Status: constructed, not machine-checked.

## Target

Production target: `repo/sympy/core/symbol.py`, function
`symbols(names, *, cls=Symbol, **args)`.

Issue target: nested iterable input with `cls=Function`, specifically
`symbols(('q:2', 'u:2'), cls=Function)`.

## Public Intent Ledger

The public evidence ledger is also recorded in
`fvk/PUBLIC_EVIDENCE_LEDGER.md`.

| ID | Evidence | Obligation |
| --- | --- | --- |
| E1 | Problem says extra parentheses make `Function` objects become `Symbol`. | Preserve `cls` across iterable recursion. |
| E2 | Problem expects `type(q[0])` to be `UndefinedFunction`. | The concrete nested range reproducer must construct function classes. |
| E3 | Problem says extra parentheses are needed to deconstruct separate tuples. | Preserve the outer grouping and inner range tuple shape. |
| E4 | `symbols()` docstring says `cls` creates Function or Wild-like objects. | Treat `cls` as a general constructor selector, not a Function-only special case. |
| E5 | `symbols()` docstring shows tuple/list/set input forms preserve container kind. | Do not reshape the iterable output. |
| E6 | `Function.__new__` returns `UndefinedFunction` when called as `Function(name)`. | Calling the provided `cls` is sufficient to produce the expected function type. |

## Contract

C1. For a string name or range spec, every constructed object uses the active
`cls`.

C2. For a non-string iterable `names`, every recursive call to `symbols()` uses
the same active `cls` as the outer call.

C3. For `symbols(('q:2', 'u:2'), cls=Function)`, the outer result is a
two-element tuple. The first element is the range expansion for `q:2`; its first
object is created by `Function('q0')` and therefore has undefined-function type.

C4. The iterable branch preserves existing container reconstruction via
`type(names)(result)`.

C5. Existing `**args` propagation is preserved. The repair may pass `cls`
explicitly but must not remove or mutate assumptions and other keyword
arguments beyond the existing string-branch `seq` handling.

## Formal Core

`fvk/mini-symbols.k` models the issue-relevant observable: each constructed
object carries a class token, and iterable/range parsing produces nested
tuple-like values.

`fvk/symbols-spec.k` contains two claims:

- `SYMBOLS-FUNCTION-NESTED-RANGES`: the concrete issue input produces nested
  values whose leaves all carry `FunctionCls`.
- `SYMBOLS-ITERABLE-PRESERVES-CLASS`: for any modeled iterable input, the
  recursive branch preserves the caller's class token.

The model deliberately abstracts away unrelated SymPy object internals while
keeping the class token and nested output shape visible. A failing pre-fix
implementation and a passing implementation map to different modeled values:
`obj(SymbolCls, "q0")` versus `obj(FunctionCls, "q0")`.

## Preconditions and Scope

The spec covers accepted `symbols()` inputs in the issue family: iterable
containers whose elements are string names or range specs that the existing
parser accepts. Invalid strings and error behavior are outside this repair and
unchanged.

The proof is partial correctness and is constructed, not machine-checked.
