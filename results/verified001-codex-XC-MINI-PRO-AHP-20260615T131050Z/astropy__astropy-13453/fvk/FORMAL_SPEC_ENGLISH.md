# Formal Spec In English

Status: paraphrase of the constructed K claims, not machine-checked.

## Claim HTML-FORMATS-1D

For any accepted one-dimensional HTML output column, if the `formats` map
contains an entry for that column name, the writer first updates the column's
format to that entry and then obtains cell text from the standard
`iter_str_vals` formatter. The emitted HTML cell text is therefore the formatted
text, with the existing fill-value and raw-HTML processing applied afterward.

## Claim HTML-FORMATS-NO-ENTRY

For any output column whose name is absent from the `formats` map, the writer
does not change that column's format. The emitted HTML cell text follows the
same path as before the fix.

## Claim HTML-FORMATS-MULTICOL

For any multidimensional source column rendered as multiple HTML cells, if the
source column has a format after the `formats` map is applied, each temporary
split column receives that same format before its own `iter_str_vals` iterator
is created.

## Frame Conditions

The claims do not alter the HTML writer's public method signature, table/header
emission order, fill-value replacement rules, or raw HTML escape/cleaning
decision. Those behaviors are framed around the format propagation step.
