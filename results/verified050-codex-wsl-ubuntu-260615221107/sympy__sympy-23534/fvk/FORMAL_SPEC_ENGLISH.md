# Formal Spec English

This file paraphrases the nontrivial claims and rules in `symbols-spec.k`.

## Claim SYMBOLS-FUNCTION-NESTED-RANGES

For the concrete call modeled as
`symbols(tuple(range("q", 0, 2), range("u", 0, 2)), FunctionCls)`, the result is
a nested tuple-like value:

- first group: `q0`, `q1`, each carrying `FunctionCls`;
- second group: `u0`, `u1`, each carrying `FunctionCls`.

The output shape has one outer tuple and two inner tuple groups.

## Claim SYMBOLS-ITERABLE-PRESERVES-CLASS

For any modeled non-string iterable `tuple(N ; NS)` and any class token `C`,
`symbols()` returns the tuple of recursively parsed children where every child
is parsed with the same class token `C`. The recursive step must not substitute
`SymbolCls` unless the caller's class token is already `SymbolCls`.

## Rule STRING-RANGE-USES-CLASS

For a range spec `range(prefix, start, end)` and class token `C`, each generated
name `prefix + index` is constructed as an object carrying `C`.

## Frame Conditions

The formal model preserves only the observable properties relevant to the issue:
the constructor class token and nested tuple shape. Other `symbols()` behavior
is covered by source-level proof obligations, not by new semantics.
