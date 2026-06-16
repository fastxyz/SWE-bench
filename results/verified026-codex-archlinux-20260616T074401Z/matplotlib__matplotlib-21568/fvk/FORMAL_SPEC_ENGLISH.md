# Formal Spec in English

`CLAIM-WRAP-IN-TEX`: Calling the modeled `_wrap_in_tex` on any in-domain date
label string returns the expected wrapped string formed by splitting alphabetic
runs, protecting dashes, protecting colons, converting literal spaces to `\;`,
wrapping the result in `$\mathdefault{...}$`, and removing empty mathdefault
chunks.

`CLAIM-PROTECT-SEPARATORS`: The wrapped output for any in-domain date label has
protected date/time separators: `-` appears as `{-}`, `:` appears as `{:}`, and
literal spaces appear as `\;`.

`CLAIM-DATEFORMATTER-USETEX`: A built-in date formatter with TeX enabled returns
the `_wrap_in_tex` result for its formatted label string.

`CLAIM-DATEFORMATTER-NON-TEX`: A built-in date formatter with TeX disabled
returns its formatted label string unchanged.

Frame condition: The formal spec does not change public signatures or define
behavior for user-supplied callable formatter functions.
