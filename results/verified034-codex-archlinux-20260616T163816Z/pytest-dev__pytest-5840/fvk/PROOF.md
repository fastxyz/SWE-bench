# Constructed Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`,
Python, or tests were run.

## Commands To Machine-Check Later

From the workspace root:

```sh
cd fvk
kompile mini-python-path.k --backend haskell
kast --backend haskell unique-path-spec.k
kprove unique-path-spec.k
```

Expected result after the external filesystem/pathlib obligations are supplied
by an adequate semantics or accepted as simplification assumptions: `#Top`.

## What Is Proved

For every in-domain conftest path object `p` naming an existing filesystem entry,
V1's `unique_path(p)` returns `type(p)(C)`, where `C` is the canonical
case-preserving resolved path for that entry.

Consequently, `_importconftest()` passes a canonical case-preserving path to
`pyimport()`, and the reported lowercased module-name failure is not reachable
through the modeled conftest path flow.

## Symbolic Execution Sketch

1. Start with `<k> uniquePath(path(T, S)) </k>` and filesystem state `FS`.
2. Apply the `uniquePath` rule from `mini-python-path.k`, which models
   `return type(path)(str(Path(str(path)).resolve()))`.
3. The term rewrites to `<k> path(T, resolveCanon(S, FS)) </k>`.
4. By the external canonicalization obligations in `unique-path-spec.k`, if
   `existsPath(S, FS)` then `resolveCanon(S, FS)` both preserves filesystem
   casing and names the same filesystem entry as `S`.
5. Therefore the result object preserves type `T`, preserves path casing, and
   remains a canonical same-file key.

No loop or recursion circularity is required for this source change.

## Composition With `_importconftest()`

`_importconftest()` first rewrites its input path through `unique_path()`. The
same rewritten value is used for cache lookup, `pypkgpath()`, and `pyimport()`.
Under PO-2 and PO-3, `pyimport()` cannot receive a path lowercased by pytest's
canonicalization helper, because V1 removed the only `normcase()` transition
from that flow.

## Alias-Uniqueness Argument

For two input strings `S1` and `S2` that name the same existing filesystem entry,
PO-4 supplies:

```text
resolveCanon(S1, FS) == resolveCanon(S2, FS)
```

The two `uniquePath` executions therefore return path objects of the same type
with the same canonical string. This preserves the conftest cache behavior that
prevents duplicate loads through symlinks or alternate case spellings.

## Adequacy

`FORMAL_SPEC_ENGLISH.md` matches `INTENT_SPEC.md` for the required behavior:
case preservation, alias uniqueness, import flow, and compatibility. The only
ambiguous entry is the external `Path.resolve()`/filesystem guarantee, recorded
as FINDING F2 and PO-2.

## Test Recommendation

Do not remove tests. The proof is constructed only, not machine-checked, and the
existing conftest tests exercise integration with real `py.path.local`, import,
and filesystem behavior outside the mini semantics. A useful additional test
would create an uppercase package component and import its conftest on Windows,
but test files are fixed and were not modified.
