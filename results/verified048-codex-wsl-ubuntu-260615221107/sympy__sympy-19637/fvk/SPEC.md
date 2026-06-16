# FVK Specification for sympy__sympy-19637

Status: constructed, not machine-checked. No tests, Python, or K tooling were run.

## Scope

Target under audit: `kernS(s)` in `repo/sympy/core/sympify.py`.

The proof scope is the control-flow safety of `kernS` around the temporary
placeholder variable `kern`. The full behavior of `sympify` and SymPy expression
construction is treated as an abstract oracle, because the public issue is an
`UnboundLocalError` raised before expression semantics can matter.

## Intent-Only Specification

For string inputs in the documented `kernS` domain:

- `kernS` should parse a string expression through `sympify`, using its placeholder
  hack only when that hack is actually introduced.
- A valid parseable string with parentheses, such as `(2*x)/(x-1)`, must not raise
  `UnboundLocalError` from internal bookkeeping.
- If the placeholder hack is not introduced, the cleanup path that substitutes
  `Symbol(kern)` must not run.
- If the placeholder hack is introduced and then fails with `TypeError`, the
  documented fallback is to pass the un-hacked string to `sympify`.
- Existing public API shape is preserved: `kernS` remains a one-argument helper
  and does not change callers or return protocols.

## Public Evidence Ledger

| ID | Source | Quoted Evidence | Semantic Obligation | Status |
| --- | --- | --- | --- | --- |
| E-001 | prompt | `text = "(2*x)/(x-1)"` and `UnboundLocalError: local variable 'kern' referenced before assignment` | This in-domain input must not reach a read of undefined local `kern`. | Encoded by PO-1 and PO-2. |
| E-002 | docstring | `Use a hack to try keep autosimplification from distributing a number into an Add` | The placeholder path is conditional; it supports the anti-distribution hack rather than all strings. | Encoded by PO-3. |
| E-003 | docstring | `If use of the hack fails, the un-hacked string will be passed to sympify` | The `TypeError` fallback should be reachable only after the hack was attempted. | Encoded by PO-4. |
| E-004 | docstring examples | `kernS('2*(x + y)')` and `kernS('-(x + 1)')` | Inputs that introduce the placeholder must still run the cleanup substitution. | Encoded by PO-3 and PO-5. |
| E-005 | implementation | `hit = False` before the rewrite block | `hit` is the guard for the cleanup path. This is implementation evidence, not public intent by itself. | Used in the proof model. |
| E-006 | implementation | `rep = {Symbol(kern): 1}` is guarded by `if not hit: return expr` | Reading `kern` after parsing is safe if `hit` can become true only after `kern` is assigned. | Encoded by PO-3 and PO-5. |

## Formal Domain and Abstractions

Precondition: `s` is a Python `str`. This follows from the public examples and
from `kernS` being a string helper around `sympify`.

Abstract functions in the formal model:

- `quoted(s)`: `s` contains either quote character, so `kernS` skips the hack.
- `hasLParen(s)`: `s` contains `(`.
- `balancedParens(s)`: `s.count('(') == s.count(')')`.
- `stripSpaces(s)`: the implementation's `''.join(s.split())`.
- `hackRewrite(t)`: the deterministic `*(`, `** *`, and `-(` rewrites before
  fresh placeholder replacement.
- `hasHackSpace(t)`: the rewritten string contains the space marker used by the
  placeholder hack.
- `freshKern(t)`: a string not occurring in `t`, produced by the existing fresh
  name loop when the placeholder path is needed.
- `sympify(t)`: abstract result or abstract exception from the existing parser.
- `clearSympify(t, k)`: abstract result of parsing `t` and substituting
  `Symbol(k)` by `1`.

The model deliberately distinguishes strings that need the placeholder from
strings that merely contain parentheses. This distinction is the property that
the bug collapsed.

## Branch Contracts

1. If `not hasLParen(s)` or `quoted(s)`, `kernS(s)` skips the rewrite block and
   delegates to `sympify(s)` with `hit == False`.
2. If `hasLParen(s)` and not `quoted(s)` and parentheses are unbalanced, `kernS`
   raises `SympifyError('unmatched left parenthesis')`.
3. If the rewrite block runs and `hasHackSpace(hackRewrite(stripSpaces(s)))` is
   false, `kernS` leaves `hit == False`, never assigns or reads `kern`, and
   delegates to `sympify(hackRewrite(stripSpaces(s)))`.
4. If the rewrite block runs and `hasHackSpace(...)` is true, `kernS` assigns a
   fresh `kern`, replaces spaces with that value, sets `hit == True`, and later
   the cleanup path may read `kern`.
5. If the placeholder parse raises `TypeError`, `kernS` resets `s` to `olds`,
   sets `hit == False`, and retries through the un-hacked string path.

## Adequacy Audit

The formal branch contracts match the public intent:

- E-001 requires removal of the undefined-local failure. PO-2 states exactly that
  the no-placeholder branch does not read `kern`.
- E-002 and E-004 require the placeholder path to remain available when the hack
  is introduced. PO-3 preserves that path.
- E-003 requires the un-hacked fallback only after a hack attempt. PO-4 preserves
  that behavior.
- No public evidence requires changing the signature, callers, or the semantics
  of `sympify`; those are frame conditions rather than repair targets.

No required behavior is marked ambiguous. The proof is partial correctness:
termination of the random fresh-name loop is not proved.
