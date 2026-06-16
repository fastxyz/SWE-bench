# FVK Spec: pytest-dev__pytest-6202

Status: constructed from public intent and source inspection only. No tests, Python code, or K tooling were executed.

## Scope

The unit under audit is `PyobjMixin.getmodpath()` in `repo/src/_pytest/python.py`, plus the observable propagation path:

`getmodpath()` -> `reportinfo()` -> `Node.location` -> `TestReport.head_line` -> terminal failure headline.

The audited behavior is partial correctness of the returned/displayed test-name string for all collected Python node names in the normal pytest collection tree. There are no loops in the patched unit.

## Intent Spec

I-01. A parametrized test id is literal user/test data once it is part of `Function.name`; characters inside that id, including the substring `".["`, must be preserved in report metadata and terminal headlines.

I-02. `getmodpath()` should build a dotted Python path from the collected node chain by skipping `Instance`, using the module stem for `Module`, respecting `stopatmodule` and `includemodule`, and joining the selected parts with `"."`.

I-03. After the selected parts are joined, no content-based normalization may rewrite characters inside a part. In particular, `".["` inside a parametrized function name must remain `".["`.

I-04. The obsolete generated-yield-test display form `test_gen[0]` is not an active compatibility requirement for this checkout because yield tests are removed/ignored in pytest 4.0 and later.

I-05. The public API shape is unchanged: method names, arguments, return type, and the report location tuple shape remain the same.

## Public Evidence Ledger

E-01. Source: prompt/issue. Evidence: the issue reports that `"test_boo[..[]"` is shown as `"test_boo[.[]"`. Obligation: preserve the literal parametrized name in the report headline. Status: encoded by I-01 and O-01.

E-02. Source: prompt/issue. Evidence: the issue traces the headline through `TestReport.head_line`, `Node.location`, `reportinfo()`, and `getmodpath()`. Obligation: verify the whole observable propagation path, not only the edited line. Status: encoded by I-02, I-03, O-02, and O-03.

E-03. Source: prompt/issue. Evidence: the issue identifies `return s.replace(".[", "[")` as the cause. Obligation: reject the legacy global replacement as the intended postcondition. Status: encoded by I-03 and Finding F-01.

E-04. Source: public hint. Evidence: the replacement existed for older generator-function yield tests whose child name was like `[0]`. Obligation: consider the compatibility purpose of the old rewrite. Status: encoded by I-04 and Finding F-02.

E-05. Source: public hint. Evidence: yield tests were removed in pytest 4.0, so the line can be replaced with `return s`. Obligation: do not preserve old generated-yield formatting as a current requirement. Status: encoded by I-04 and O-04.

E-06. Source: implementation. Evidence: `_genfunctions()` constructs parametrized item names as `"{name}[{callspec.id}]"`. Obligation: treat `callspec.id` as part of a single node name, not as a path separator. Status: encoded by O-01.

E-07. Source: implementation. Evidence: `reportinfo()` returns `modpath = self.getmodpath()`, `Node.location` stores `str(location[2])`, and `TestReport.head_line` returns that domain. Obligation: prove exact string propagation after `getmodpath()`. Status: encoded by O-03.

E-08. Source: implementation. Evidence: generator functions are collected as a `Function` marked xfail/run=False with the warning "yield tests were removed in pytest 4.0". Obligation: classify old yield-generated child formatting as obsolete. Status: encoded by I-04 and Finding F-02.

## Abstract Formal Model

Let `project(chain, stopatmodule, includemodule)` be the ordered list of display parts produced by the current `getmodpath()` loop:

1. Start from `self.listchain()`.
2. Traverse from the item toward the root.
3. Ignore nodes whose runtime type is `Instance`.
4. For a `Module`, use `os.path.splitext(node.name)[0]`; if `stopatmodule` is true, append it only when `includemodule` is true, then stop.
5. For all other included nodes, append `node.name`.
6. Reverse the accumulated list into display order.

Let `join(parts)` be `".".join(parts)`.

The intended contract is:

`getmodpath(chain, stopatmodule, includemodule) == join(project(chain, stopatmodule, includemodule))`

There is no post-join replacement function in the contract.

For the issue reproducer, after projection the selected parts are:

`["test_boo[..[]"]`

The required result is:

`join(["test_boo[..[]"]) == "test_boo[..[]"`

The rejected legacy behavior is:

`"test_boo[..[]".replace(".[", "[") == "test_boo[.[]"`

## Formal Spec English and Adequacy Audit

S-01. `getmodpath()` returns exactly the dotted join of the projected node-name parts.
Audit: pass. This is entailed by E-02 and by the method's public purpose as a module path formatter.

S-02. If a selected node-name part contains `".["`, that substring is preserved.
Audit: pass. This is entailed by E-01, E-03, and E-06. It is not implementation-derived from V1 alone.

S-03. `reportinfo()`, `Node.location`, and `TestReport.head_line` propagate the returned `modpath` without content mutation.
Audit: pass. This is implementation evidence for the observable path named by the issue, not a new user-facing behavior.

S-04. The obsolete `test_gen.[0] -> test_gen[0]` rewrite is not preserved.
Audit: pass. E-04 identifies the old purpose, while E-05 and E-08 remove it from the current intent domain.

S-05. No public signature or return-shape compatibility is changed.
Audit: pass. The V1 patch changes only the returned value for names affected by the obsolete replacement.

## Public Compatibility Audit

Changed symbol: `PyobjMixin.getmodpath(self, stopatmodule=True, includemodule=False)`.

Signature: unchanged.

Return type: unchanged (`str`).

Known in-source consumers: `reportinfo()` in the same mixin and public-style calls in tests. The consumer contract is a display/report path string. V1 strengthens literal preservation and removes only the obsolete generated-yield formatting.

Subclass/override impact: no changed virtual dispatch signature and no new call arguments.

Producer/consumer impact: parametrized `Function.name` values containing `".["` now flow unchanged to report metadata. This is the required observable behavior.

Compatibility conclusion: no further source change is required.
