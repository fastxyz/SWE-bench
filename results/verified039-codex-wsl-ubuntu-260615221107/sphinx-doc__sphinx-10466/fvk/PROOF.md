# Constructed Proof

Status: constructed, not machine-checked.

## Claims Proved

The proof constructs partial correctness for the gettext location path:

1. `_unique_locations()` returns first-occurrence, preserve-order unique
   locations.
2. `Catalog.__iter__()` normalizes source paths before creating `Message`
   instances.
3. `Message.__init__()` stores the unique normalized location list.
4. Rendering retained normalized paths produces the same final path text as
   rendering the original paths.
5. Therefore the emitted POT location comments for a message contain no
   duplicate `#: path:line` lines.

## Symbolic Proof Sketch

Let `M` be an arbitrary finite metadata list for one message.

1. `Catalog.__iter__()` transforms each entry `(source, line, uuid)` into
   `(N(source), line)`, where `N(source) = canon_path(relpath(source))`.
2. `Message.__init__()` calls `_unique_locations()` on that list.
3. The loop invariant for `_unique_locations()` is:
   - after processing prefix `P`, `unique = StableUnique(P)`;
   - `seen` is exactly the set of locations in `unique`;
   - `unique` has no duplicates;
   - retained order is first-occurrence order.
4. The invariant is initially true for the empty prefix.
5. For the next location:
   - if it is already in `seen`, skipping it preserves `StableUnique(P)`;
   - if it is not in `seen`, appending it creates `StableUnique(P + [location])`
     and preserves no-duplicates.
6. At loop exit, the processed prefix is the whole input list, so
   `_unique_locations()` returns `StableUnique([L(entry) for entry in M])`.
7. The path lemma gives `R(N(source)) = R(source)`, so retained normalized
   locations render with the same text as the original source paths.
8. The companion path identity condition says any two entries with the same
   rendered output line have equal normalized location tuples. Thus the stable
   unique normalized list renders to
   `StableUnique([Rendered(entry) for entry in M])`.
9. Therefore no duplicate rendered location comment line remains.

## Adequacy Check

`fvk/FORMAL_SPEC_ENGLISH.md` matches `fvk/INTENT_SPEC.md`:

- The public intent is about duplicate rendered location lines.
- The formal observable is rendered source path plus line number.
- The proof covers both exact duplicate tuples and textually different source
  paths that normalize to the same final location.
- Frame conditions are limited to behavior the issue did not ask to change.

## Residual Risk

- The proof is constructed against an abstract mini semantics, not
  machine-checked with K.
- Termination is obvious for finite Python lists but is not machine-proved.
- Filesystem identity is abstracted through Sphinx-style `relpath`/`canon_path`
  laws. Symlink resolution and case-insensitive filesystem aliases are outside
  this issue's public intent.

## Machine-Check Commands Not Executed

```sh
kompile fvk/mini-python-location-catalog.k --backend haskell
kast --backend haskell fvk/gettext-location-spec.k
kprove fvk/gettext-location-spec.k --definition fvk/mini-python-location-catalog-kompiled
```

Expected result after a successful machine check: `#Top` for all claims.

## Test Recommendation

No tests were modified. Existing unit/integration tests should be kept unless a
future environment actually runs the emitted K commands and the relevant claims
return `#Top`.
