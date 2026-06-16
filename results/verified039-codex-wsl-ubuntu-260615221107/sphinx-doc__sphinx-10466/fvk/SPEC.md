# FVK Spec

Status: constructed, not machine-checked.

## Scope

This FVK pass audits the V1 fix for `sphinx-doc__sphinx-10466` in
`repo/sphinx/builders/gettext.py`. The verified observable is the sequence of
gettext location comment lines produced for each message by the combined
`Catalog.__iter__()` -> `Message.__init__()` -> gettext template path.

## Public Intent Ledger

See `fvk/PUBLIC_EVIDENCE_LEDGER.md` for the standalone ledger. The critical
entries are:

- E1-E3: generated POT output must not contain duplicate location lines for a
  message.
- E4-E6: raw `set(locations)` de-duplication is insufficient because equivalent
  locations can differ textually before output; normalization in
  `Catalog.__iter__()` is required.
- E7: the rendered output identity is `relpath(source, outdir)` plus `line`.
- E8: existing message order is intentionally stable and should not be disturbed.

## Definitions

For a metadata triple `entry(source, line, uuid)`:

- `N(source) = canon_path(relpath(source))`, matching V1's
  `canon_path(relpath(source))` in `Catalog.__iter__()`.
- `R(source) = canon_path(relpath(source, outdir))`, matching
  `GettextRenderer._relpath()` in the gettext template.
- `L(entry) = (N(source), line)`.
- `Rendered(entry) = (R(source), line)`.
- `StableUnique(xs)` is the ordered list containing the first occurrence of each
  distinct element in `xs`.

## Contract

For each message with metadata sequence `M`:

1. `Catalog.__iter__()` must produce location candidates
   `[L(entry) for entry in M]`.
2. `Message.__init__()` must store `StableUnique([L(entry) for entry in M])`.
3. The rendered location output must equal
   `StableUnique([Rendered(entry) for entry in M])`.
4. Message text, message order, UUID values, and template path rendering are
   frame conditions and are not changed by the fix.

## Key Path Lemma

For in-domain Sphinx source paths interpreted relative to the same process
current working directory:

- `R(N(source)) = R(source)`.
- If `Rendered(entry1) == Rendered(entry2)`, then `L(entry1) == L(entry2)`.

The first property preserves the spelling of retained location lines. The second
property means de-duplicating normalized locations before rendering removes all
duplicates that would be visible in the POT output.

## Formal Artifacts

- `fvk/mini-python-location-catalog.k`
- `fvk/gettext-location-spec.k`

Exact commands to machine-check later, not executed here:

```sh
kompile fvk/mini-python-location-catalog.k --backend haskell
kast --backend haskell fvk/gettext-location-spec.k
kprove fvk/gettext-location-spec.k --definition fvk/mini-python-location-catalog-kompiled
```
