# Baseline Notes

## Root cause

`PyobjMixin.getmodpath()` builds a dotted path from the collected node chain and then rewrites every `".["`-style boundary by calling `s.replace(".[", "[")`. That rewrite was meant for old yield-generated tests whose child names looked like `[0]`, so their display path would be `test_gen[0]` instead of `test_gen.[0]`.

Yield tests are no longer supported as normal generated test items in this version; generator functions are marked as ignored/xfail during collection instead. The global replacement now applies to ordinary collected item names too, including parametrized test names. For a parametrized id containing `..[`, the assembled modpath contains `test_boo[..[]`, and the global replacement corrupts that literal name into `test_boo[.[]`, which is then used by `reportinfo()` and the long report headline.

## Changed files

`repo/src/_pytest/python.py`

Removed the final `s.replace(".[", "[")` normalization from `PyobjMixin.getmodpath()` and returned the assembled modpath unchanged. This preserves literal parameter ids and keeps report headlines consistent with the collected item name.

## Assumptions

The legacy generated-test formatting behavior is no longer required because yield tests were removed in pytest 4.0 and this checkout already warns/ignores generator functions instead of collecting yielded child items.

The reported corruption is limited to the post-processing in `getmodpath()`, because `Node.location` and `TestReport.head_line` simply propagate the third value returned by `reportinfo()`.

## Alternatives considered

One option was to replace only a leading or segment-final occurrence of `".["` instead of removing the rewrite entirely. I rejected that because the old generated-test behavior is obsolete, while any pattern-based rewrite at the string level can still mis-handle legitimate test names.

Another option was to special-case parametrized function names before building the report location. I rejected that because the corruption happens in the shared modpath formatter after the correct name has already been assembled; preserving the assembled string is the smaller and more direct fix.
