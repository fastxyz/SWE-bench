# Intent Specification

Status: constructed for FVK, not machine-checked.

## Required Behavior

1. Django must drop support for SQLite versions older than 3.9.0.
2. The SQLite backend must reject SQLite runtime versions below 3.9.0 before
   normal backend use.
3. SQLite 3.9.0 itself and later versions must remain accepted by the support
   floor.
4. Public current documentation that states Django's supported SQLite version
   must advertise 3.9.0 or later, not 3.8.3.
5. JSON1 availability must remain a runtime capability check because the issue
   identifies it as a compile-time option even though it is available in SQLite
   3.9.0+.

## Out of Scope

Historical release notes that describe past releases are not current support
floor declarations. They can continue to mention older SQLite versions as
historical facts.

This checkout does not expose a generic expression-index `Index` API, so the
intent does not imply adding that API in this branch.
