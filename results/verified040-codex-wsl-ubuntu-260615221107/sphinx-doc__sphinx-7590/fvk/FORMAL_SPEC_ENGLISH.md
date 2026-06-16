# Formal Spec English

Status: paraphrase of the claims in `cpp-udl-spec.k`; constructed, not
machine-checked.

## Claim UDL-NUMERIC

For any numeric literal core and any immediate valid suffix, parsing returns a
literal whose displayed spelling is the core followed by the suffix, records the
suffix as attached to the literal, and leaves the remaining input untouched.

## Claim UDL-STRING

For any string literal core, including prefixed or raw spellings already
recognized as a string literal core, and any immediate valid suffix, parsing
returns a literal whose displayed spelling is the string core followed by the
suffix and leaves the remaining input untouched.

## Claim UDL-CHAR

For any character literal core and any immediate valid suffix, parsing returns a
literal whose displayed spelling is the character core followed by the suffix and
leaves the remaining input untouched.

## Claim NO-SUFFIX-FRAME

For numeric, string, and character literals with no immediate valid suffix,
parsing returns the original literal spelling with no attached suffix and leaves
the remaining input untouched.

## Claim FRAME

The C++ literal-expression parser change does not alter the C domain shared
literal regexes or the C++ `operator""` declaration parser.
