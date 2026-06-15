# Formal Spec English

This paraphrases the nontrivial K claims and source-preservation obligations.

## PLAIN-EMPTY-SUFFIX

For any column token `C`, rendering a plain column with suffix `''` returns exactly the quoted column token and no trailing whitespace.

## PLAIN-NONEMPTY-SUFFIX

For any column token `C` and non-empty suffix token `S`, rendering a plain column returns the quoted column token, one space, and `S`.

## INDEX-EMPTY-SUFFIX

For any column token `C` and non-empty opclass token `O`, rendering an opclass column with suffix `''` returns the quoted column token, one space, and `O`, with no trailing whitespace.

## INDEX-NONEMPTY-SUFFIX

For any column token `C`, non-empty opclass token `O`, and non-empty suffix token `S`, rendering an opclass column returns the quoted column token, one space, `O`, one space, and `S`.

## MULTI-COLUMN-PRESERVATION

For several columns, the per-column renderings are combined with comma-space. The V1 edit leaves that outer delimiter unchanged.

## COMPATIBILITY-PRESERVATION

The V1 edit changes only the internal string assembly of `__str__()` methods. Constructor signatures, method signatures, dispatch, and return type remain unchanged.
