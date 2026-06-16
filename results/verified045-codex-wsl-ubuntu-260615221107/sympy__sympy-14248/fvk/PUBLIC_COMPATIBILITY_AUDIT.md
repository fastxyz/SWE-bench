# Public Compatibility Audit

Status: no compatibility blockers found.

## Changed Public/Overridable Symbols

- `StrPrinter._print_MatAdd(self, expr)`
- `LatexPrinter._print_MatAdd(self, expr)`
- `PrettyPrinter._print_MatAdd(self, expr)`

All three retain their existing signatures and return-shape contracts.

## Callers and Dispatch Shape

The printer dispatch mechanism calls `_print_<ClassName>(self, expr)` based on
expression type. V1 does not add parameters, change method names, change return
types, or alter the dispatch protocol. Direct callers of `_print_MatAdd` remain
source-compatible.

## Subclasses and Overrides

No changed method now calls a virtual method with a new keyword or new argument
shape. The patch uses existing printer helpers (`self._print`,
`self.parenthesize`, and `prettyForm.__add__`) with existing call shapes.

## Producer/Consumer Shape

The producer is still a `MatAdd` expression with `expr.args`. The consumer
observable is still a string for `StrPrinter` and `LatexPrinter`, and a
`prettyForm` for `PrettyPrinter`. The only intended behavior change is the
rendered sign sequence for negative matrix terms.

## Verdict

Compatibility audit passes. No source edit beyond V1 is required for public API
compatibility.
