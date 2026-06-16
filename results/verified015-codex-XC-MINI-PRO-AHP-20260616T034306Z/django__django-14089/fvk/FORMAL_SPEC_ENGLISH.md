# Formal Spec English

K-001: For any finite list of key values `XS`, constructing an `OrderedSet`
keeps the first occurrence of each distinct value and discards later duplicates.

K-002: For any finite list of key values `XS`,
`list(reversed(OrderedSet(XS)))` evaluates to `reverseList(uniqueFirst(XS))`.
In ordinary Python terms, reversing an `OrderedSet` yields its distinct elements
from newest insertion position to oldest insertion position.

K-003: For any finite list of key values `XS`, `list(iter(OrderedSet(XS)))`
evaluates to `uniqueFirst(XS)`.

K-004: For an empty input, reverse iteration yields an empty list.

K-005: For duplicate-containing input `[1, 2, 1]`, reverse iteration yields
`[2, 1]`, because the set has distinct insertion-order contents `[1, 2]`.

K-006: The method-level proof assumes the backing dictionary preserves insertion
order and supports reverse key iteration in the supported Python runtime.
