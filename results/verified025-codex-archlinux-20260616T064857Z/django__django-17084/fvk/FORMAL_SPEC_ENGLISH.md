# Formal Spec in English

Status: constructed, not machine-checked.

## Claim: `window-ref-forces-wrapper`

For every aggregate decision state, if an aggregate expression references a
selected annotation that contains a window clause, the decision is `Wrapped`.

## Claim: `window-ref-produces-safe-sql-shape`

For the minimal reported case where the only wrapping reason is a selected
window annotation reference, the final SQL shape is `SafeOuterAlias`: the window
expression is computed in the inner query and the outer aggregate references
the selected alias.

## Claim: `existing-trigger-still-wraps`

For every aggregate decision state, if any pre-existing wrapping reason is true,
the decision is `Wrapped`, regardless of the new window-reference flag.

## Claim: `no-trigger-remains-direct`

If no pre-existing wrapping reason is true and no selected window annotation is
referenced, the decision is `Direct`.

## Scope Clause

The formal claims do not cover direct expression lifting for
`Aggregate(Window(...))`; they cover selected annotation references, which is
the issue-backed public behavior.
