# PROOF OBLIGATIONS

Status: constructed, not machine-checked.

## PO-1 - Localize the Pre-Fix Failure

Claim: In the pre-fix path, SQLite compilation of Decimal `Lag` inside `Window` produces `over(castNumeric(raw(lag)))`.

Evidence: `Func` inherits `SQLiteNumericMixin`; `Window.as_sql()` compiles `self.source_expression` before applying its `%(expression)s OVER (%(window)s)` template.

Status: Discharged by code inspection and symbolic derivation in `PROOF.md`.

## PO-2 - Decimal Lag Window Uses Outer Cast

Claim: V1 SQLite compilation of Decimal `Lag` inside `Window` produces `castNumeric(over(raw(lag)))`.

Evidence: `fvk/django-window-sqlite-spec.k` claim `compileWindowSqlite(decimal, source(lag, decimal)) => castNumeric(over(raw(lag)))`.

Status: Constructed proof discharged; not machine-checked.

## PO-3 - Float Lag Window Is Unchanged

Claim: V1 SQLite compilation of Float `Lag` inside `Window` produces `over(raw(lag))`.

Evidence: `fvk/django-window-sqlite-spec.k` claim `compileWindowSqlite(float, source(lag, float)) => over(raw(lag))`.

Status: Constructed proof discharged; not machine-checked.

## PO-4 - Standalone Decimal Func Casting Is Preserved

Claim: V1 preserves standalone Decimal `Func` SQLite casting as `castNumeric(raw(lag))`.

Evidence: `fvk/django-window-sqlite-spec.k` claim `compileStandaloneSqlite(source(lag, decimal)) => castNumeric(raw(lag))`; `SQLiteNumericMixin.as_sqlite()` is unchanged.

Status: Constructed proof discharged; not machine-checked.

## PO-5 - Original Expression Metadata Is Preserved

Claim: V1 does not mutate the original `Window.source_expression.output_field`.

Evidence: V1 calls `clone = self.copy()` and `source_expressions[0] = source_expressions[0].copy()` before assigning `fields.FloatField()` to the cloned source expression.

Status: Discharged by code inspection.

## PO-6 - Backend Feature Check Remains on Path

Claim: Decimal SQLite `Window` compilation still checks `connection.features.supports_over_clause`.

Evidence: Decimal branch delegates to `super(Window, clone).as_sqlite()`, which calls `clone.as_sql()`. `Window.as_sql()` performs the support check before rendering SQL.

Status: Discharged by code inspection.

## PO-7 - Public Compatibility

Claim: V1 does not change public constructor signature, public call shape, or in-repo subclass override compatibility for `Window`.

Evidence: `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`.

Status: Discharged by repository search and code inspection.

## PO-8 - Machine Check Commands Are Emitted but Not Run

Claim: The FVK proof remains "constructed, not machine-checked" until K tooling is run.

Evidence: `PROOF.md` lists exact commands; task forbids execution.

Status: Open operational validation, not a code defect.

## PO-9 - Custom Output-Field-Dependent Expressions Are Underspecified

Claim: A custom `window_compatible=True` expression whose SQL rendering depends on `output_field` could render differently under V1's cloned-source `FloatField` compile.

Evidence: Potential public extension point; no public issue evidence requires preserving this behavior for custom expressions.

Status: Residual risk, not a blocking finding.
