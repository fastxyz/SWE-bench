# Iteration Guidance

Status: constructed, not machine-checked.

## Decision

V1 stands unchanged. The audit did not surface a source-code problem requiring
a V2 edit.

## Trace

- Keep V1's project-first order because F-001 discharges PO-1 and PO-2.
- Keep V1's built-in order as `[None, package_dir/locale]` because F-003
  discharges PO-4 and avoids an unrelated system-vs-package precedence change.
- Keep `locale.init()` unchanged because F-004 discharges PO-6; changing the
  merge helper would broaden the blast radius to extension catalogs and direct
  callers.
- Keep the existing auto-build loop unchanged because PO-5 confirms it still
  runs before lookup.

## Suggested public tests for a normal development environment

Do not edit tests in this benchmark. If adding public tests later, target these
behaviors:

1. For `language = 'da'`, a project `locale/da/LC_MESSAGES/sphinx.po` overriding
   `Fig. %s` and `Listing %s` should win over bundled Danish translations after
   auto-building `sphinx.mo`.
2. A partial project `sphinx.mo` should still fall back to bundled/system
   translations for messages it does not contain.
3. With no yielded project locale directory, the built-in fallback order should
   remain system gettext location before bundled package locale.
4. Multiple configured project locale directories should be honored in config
   order, with the first directory containing a message winning.

## Machine-check guidance

The proof artifacts are intentionally labeled constructed, not machine-checked.
Run these commands in an environment with K installed:

```sh
cd fvk
kompile mini-locale-precedence.k --backend haskell
kast --backend haskell locale-precedence-spec.k
kprove locale-precedence-spec.k
```

Expected result after any syntax adjustments needed by the local K version:
`kprove` discharges the claims to `#Top`.
