# Formal Spec English

Status: paraphrase of the abstract K-style claims and proof obligations.

## Claim C-1: Repeated V1 compilations are independent

Starting with an original child query whose `values_select` and selected column
state are empty, compiling a combined query with outer fields `nameOrder` and
then compiling it with outer fields `order` leaves the original child query
unchanged and leaves the second compilation's child compiler query selected to
`order`.

## Claim C-2: V1 applies outer fields during a single compilation

Starting with an original child query whose `values_select` is empty, compiling
with outer fields `order` leaves the original child unchanged and selects
`order` on the child compiler query used for that compilation.

## Claim C-3: V1 preserves explicit child selection

Starting with an original child query whose `values_select` is already
`explicit`, compiling with outer fields `order` leaves the original child
unchanged and leaves the child compiler query selected to `explicit`.

## Frame and side conditions

The proof is partial correctness over selected-column state. It assumes normal
query cloning copies the relevant selected-column state into a distinct query
object, as implemented by `Query.clone()`. It does not prove database SQL
execution, result iteration, or performance.
