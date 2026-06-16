# Formal Spec English

Status: constructed, not machine-checked.

1. `DECIMAL-LAG-WINDOW`: Compiling a SQLite `Window` whose output is Decimal and whose source is `Lag` over a Decimal expression yields SQL with a Numeric cast around the whole window expression: `castNumeric(over(raw(lag)))`.

2. `FLOAT-LAG-WINDOW`: Compiling a SQLite `Window` whose output is Float and whose source is `Lag` over a Float expression yields the existing uncast window expression: `over(raw(lag))`.

3. `STANDALONE-DECIMAL-FUNC`: Compiling a standalone SQLite Decimal `Lag`/`Func` source outside `Window` still applies `SQLiteNumericMixin` at the function level: `castNumeric(raw(lag))`.

4. `DECIMAL-AGGREGATE-WINDOW`: Compiling a SQLite `Window` whose output is Decimal and whose source is a Decimal aggregate yields an outer cast around the aggregate window expression: `castNumeric(over(raw(aggregate)))`.

5. The model abstracts partition/order/frame clause content into `over(...)`; it preserves the audited property, namely whether `castNumeric` is outside or inside `over`.
