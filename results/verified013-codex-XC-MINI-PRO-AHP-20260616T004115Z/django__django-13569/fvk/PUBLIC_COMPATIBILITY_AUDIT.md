# Public Compatibility Audit

Status: constructed, not machine-checked.

Changed symbol: `SQLCompiler.get_group_by()` internals in
`repo/django/db/models/sql/compiler.py`.

Signature compatibility: Pass. No function, method, class, import, or public API
signature changed.

Callsite compatibility: Pass. Existing callers still call `get_group_by(select,
order_by)` with the same parameters and receive the same output shape, a list of
`(sql, params)` tuples after compilation.

Subclass/override compatibility: Pass. The change is internal list filtering in
the base implementation and does not add required override arguments or virtual
dispatch parameters.

Producer/consumer compatibility: Pass. The consumer of `expressions` and
`collapse_group_by()` receives the same expression object type it already
handled. The V2 edit only restores inclusion of subquery expressions that V1
could wrongly omit and excludes column-free expressions such as `Random()`.
