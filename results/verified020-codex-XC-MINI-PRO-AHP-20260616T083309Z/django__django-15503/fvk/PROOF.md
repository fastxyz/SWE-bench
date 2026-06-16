# Constructed Proof

Status: constructed, not machine-checked.

No tests, Python, `kompile`, `kast`, or `kprove` were run.

## What is proved

Subject to the adequacy of the mini model in `mini-jsonpath.k`, the V2 code
satisfies the path-component obligations in `PROOF_OBLIGATIONS.md`:

- actual `has_key`-style RHS numeric keys compile as object members;
- numeric intermediate transform segments still compile as array indexes;
- `has_keys` and `has_any_keys` inherit the same per-key behavior;
- internal transform-existence callers opt out with `final_key=False`;
- SQL templates, logical operators, and PostgreSQL behavior are framed.

## Symbolic proof sketch

PO-001 starts from `hasKeyRhsPath(numeric(1111) .Keys, true)`. The
`hasKeyRhsPath(_, true)` rule rewrites to `compileFinalKeyPath(...)`. The base
rule for `compileFinalKeyPath(numeric(I) .Keys)` rewrites to
`member(intString(I)) .Components`. Instantiating `I = 1111` yields the desired
member component.

PO-002 starts from `hasKeyRhsPath(text("d") numeric(1) text("f") .Keys, true)`.
The true branch rewrites to `compileFinalKeyPath(...)`. The recursive rules
compile the prefix as `member("d") index(1)` and the final base rule compiles
`text("f")` as `member("f")`.

PO-003 follows because `HasKeys` and `HasAnyKeys` do not override
`HasKeyLookup.as_sql()`. Their per-key loop reaches the same path compiler used
by `HasKey`; the K claim repeats the numeric-key case for an arbitrary list
member.

PO-004 starts from `hasKeyRhsPath(text("d") numeric(0) .Keys, false)`. The false
branch rewrites to ordinary `compilePath(...)`, whose recursive rules compile
`text("d")` as `member("d")` and `numeric(0)` as `index(0)`.

PO-005 and PO-006 are frame checks from the static diff: the changed source does
not alter backend SQL templates, logical operators, lookup names, or
`as_postgresql()`.

## Machine-check commands, not executed

```sh
kompile fvk/mini-jsonpath.k --backend haskell
kast --backend haskell fvk/jsonfield-has-key-spec.k
kprove fvk/jsonfield-has-key-spec.k
```

Expected result after a future machine check: `#Top` for all claims.

## Test guidance

Do not delete or modify tests from this constructed proof. After machine
checking, point tests for numeric `has_key`, `has_keys`, `has_any_keys`, nested
array-prefix `has_key`, and numeric `KeyTransform` `isnull` become candidates for
subsumption by the proof, but integration/backend SQL tests should be kept.

Because this task forbids test changes, no test files were edited.

## Residual risk

The model verifies the path component decision, not full SQL execution or full
Django ORM compilation. The proof is partial and constructed only. Backend JSON
path syntax acceptance is assumed from Django's existing use of quoted member
paths in `compile_json_path()`.
