# FVK Findings

Status: constructed, not machine-checked. Findings are based only on public
issue text, source code, and the FVK audit.

## F-001: Undefined `kern` on No-Placeholder Parenthesized Inputs

- Classification: code bug, resolved by V1.
- Evidence: E-001 and PO-2.
- Input: `(2*x)/(x-1)`.
- Pre-V1 observed behavior: the parenthesis rewrite block ran, no placeholder was
  introduced, and the implementation still evaluated `hit = kern in s`, raising
  `UnboundLocalError`.
- Expected behavior: this string is in the documented string-expression domain
  and should proceed to `sympify` rather than fail on internal bookkeeping.
- V1 status: resolved. `hit = kern in s` is now inside the branch that assigns
  `kern`; when no placeholder is introduced, `hit` remains the earlier `False`.

## F-002: Placeholder Cleanup Must Stay Conditional

- Classification: audit confirmation, no code change required.
- Evidence: E-002, E-004, PO-3, and PO-5.
- Input family: strings such as `2*(x + y)` and `-(x + 1)` where the hack inserts
  a placeholder marker.
- Observed candidate behavior by inspection: V1 still assigns `kern`, replaces
  spaces, marks `hit`, and reaches the cleanup substitution path.
- Expected behavior: the anti-distribution hack remains available for inputs
  that need it.
- V1 status: confirmed. The change only moves the `hit` update into the existing
  placeholder branch and does not remove the branch.

## F-003: `sympify` Semantics Are Outside This Proof Slice

- Classification: proof capability boundary, not a code bug in this task.
- Evidence: PO-7.
- Input: any string whose final parse result depends on full SymPy parser and
  expression semantics.
- Observed candidate behavior by inspection: `kernS` delegates to existing
  `sympify` for parsing and expression construction.
- Expected behavior: this issue requires removing the `UnboundLocalError`, not
  re-proving all of `sympify`.
- Status: keep existing tests that cover expression semantics. The FVK proof
  abstracts `sympify` and proves the local control-flow safety obligation.

## F-004: Fresh-Name Loop Termination Not Proved

- Classification: termination gap, not a required code change for this issue.
- Evidence: PO-7.
- Input family: placeholder-path strings where the randomly extended `kern`
  candidate keeps colliding with the input string.
- Observed candidate behavior by inspection: the loop searches for a fresh marker
  by appending random letters or digits until the marker is absent from `s`.
- Expected behavior: partial correctness suffices for this FVK pass; if the loop
  terminates, the chosen `kern` is fresh.
- Status: no source change. A total-correctness pass could replace randomness
  with a deterministic fresh-name search, but the public issue does not require
  that broader refactor.

## F-005: Public Compatibility Preserved

- Classification: compatibility confirmation.
- Evidence: PO-6.
- Input/callsite shape: `kernS(s)` with one string argument.
- Observed candidate behavior by inspection: V1 changes only the location of an
  internal assignment and does not alter the public signature, imports, or return
  protocol.
- Expected behavior: callers and documented examples continue to use `kernS(s)`.
- V1 status: confirmed.

## Proof-Derived Findings from `/verify`

The constructed proof generated no new required production-code changes. The
only unresolved items are proof-scope boundaries: full `sympify` semantics
remain abstract (F-003), and total termination of the random fresh-name loop is
not proved (F-004). Both are outside the public issue's required repair.
