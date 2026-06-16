# Constructed Proof

Status: constructed, not machine-checked. No tests, Python code, `kompile`,
`kast`, or `kprove` were run.

## Claims Proved in the Model

The formal core is:

- `fvk/mini-locale-precedence.k`
- `fvk/locale-precedence-spec.k`

The model represents exactly the ordering property under audit:

1. `_init_i18n()` builds a lookup order.
2. `resolve(M)` scans that order left to right.
3. The first source whose catalog contains `M` supplies the result.

## Proof Sketch

### PO-1: project locale directories are first

V1 source constructs:

```python
locale_dirs = list(repo.locale_dirs) + [
    None, path.join(package_dir, 'locale')
]
```

For any yielded project directory list `U`, the list supplied to
`locale.init()` is `U ++ [system, package]` in the model. Therefore every
project directory precedes every built-in fallback location.

### PO-2: first catalog wins

`locale.init()` makes the first successful `gettext.translation()` result the
primary `translator`. Later catalogs are added through `translator.add_fallback`.
By gettext fallback semantics, `translator.gettext(M)` consults the primary
catalog first and delegates only when that catalog lacks `M`.

In the K model, this is the `scan` rule:

```k
rule <k> scan(ListItem(S) REST, M) => .K ... </k>
     <out> _ => val(S, M) </out>
  requires has(S, M)
```

The complementary rule advances only when `notBool has(S, M)`. Thus if a
project source is first and has `M`, no built-in source can be reached for that
message.

### PO-3: missing project messages fall through

If a project source does not have `M`, the complementary `scan` rule removes it
from the front of the list and continues with the rest. Since V1 appends
`system` and `package`, built-in translations remain available for messages
absent from project catalogs.

### PO-4: no-project behavior is preserved

When `repo.locale_dirs` yields an empty list, V1 passes:

```text
[] ++ [system, package] = [system, package]
```

This is the same built-in order V0 used after abstracting `None` to `system`
and `path.join(package_dir, 'locale')` to `package`.

### PO-5 and PO-6: frame conditions

The auto-build loop still precedes lookup, so the generated project `sphinx.mo`
is available before `locale.init()` runs. No public signature or direct helper
changed, so extension catalog compatibility is preserved.

## Adequacy Check

`fvk/FORMAL_SPEC_ENGLISH.md` paraphrases each K claim. `fvk/SPEC_AUDIT.md`
compares those paraphrases against `fvk/INTENT_SPEC.md` and marks each claim
PASS. No claim preserves the reported legacy behavior.

## Test Guidance

No tests were run and no test files were modified. Existing and future tests
should be kept until the K commands below are actually run and return `#Top`.
After machine-checking, tests that assert only in-domain points of the
project-first winner rule may be considered proof-subsumed, but integration
tests of Sphinx build output should remain.

## Reproduce the Machine Check

Run in an environment with K installed:

```sh
cd fvk
kompile mini-locale-precedence.k --backend haskell
kast --backend haskell locale-precedence-spec.k
kprove locale-precedence-spec.k
```

Expected result: `kprove` returns `#Top` for all claims after any syntax
adjustments required by the installed K version.
