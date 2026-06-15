# Formal Spec in English

Status: constructed, not machine-checked.

`CSTACK-SHAPE`: For any left and right coordinate matrices, `cstack` returns a
matrix whose row count is the sum of the operand row counts and whose column
count is the sum of the operand column counts.

`CSTACK-LEFT-PRESERVE`: Every dependency entry in the left operand appears
unchanged in the upper-left block of the result.

`CSTACK-RIGHT-PRESERVE`: Every dependency entry in the right operand appears
unchanged in the lower-right block of the result.

`CSTACK-OFF-BLOCKS`: The upper-right and lower-left cross blocks are false,
because `&` concatenates independent input/output groups rather than composing
one side through the other.

`CSTACK-NESTED-RIGHT`: If the right operand is itself the result of a previous
`cstack`, placing it to the right of another matrix preserves every entry of the
nested matrix. Therefore right-hand nested `&` compound models have the same
separability as their flattened block layout.
