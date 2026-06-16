# FVK PROOF OBLIGATIONS for pytest-dev__pytest-6197

Status: constructed, not machine-checked.

## PO1 - Package discovery does not import

Claim: `Package.collect(P)` must not call `P.obj`,
`_mount_obj_if_needed()`, or any operation that imports `P/__init__.py`.

Intent trace: F1, SPEC C1.

Code evidence: V1 removed `self._mount_obj_if_needed()` from
`Package.collect()`. The remaining body computes paths, checks
`python_files`, visits children, and delegates files to `_collectfile()`.

Discharge: static source inspection plus abstract K claim
`NO-IMPORT-UNRELATED-PACKAGE`.

Status: discharged.

## PO2 - Package-only recursion preserves no-import

Claim: if a package tree contains only packages with no collected modules and
files that do not match collection patterns, recursively collecting the package
collectors emits no package import event.

Intent trace: F1, F2, SPEC C1-C2.

Proof sketch: by structural induction on the package tree. The base package has
no yielded `Module`; PO1 gives no import. The inductive step yields only nested
`Package` collectors and ignored files; each nested package satisfies the
induction hypothesis, and ignored files do not call `Module.collect()`.

Status: discharged.

## PO3 - Package marks are mounted before item creation

Claim: for any collected `Module(M)` under package parents `P1..Pn`, every
`Pi._mount_obj_if_needed()` runs before `Function` items under `M` are created.

Intent trace: F3, SPEC C3.

Code evidence: V1 calls `_mount_package_parents()` as the first statement in
`Module.collect()`. `Function` items are created later by
`PyCollector.collect()` through `super().collect()`. `Function.__init__` then
copies marker names from `iter_markers()`, which walks the already-mounted
parent chain.

Status: discharged.

## PO4 - Configured initializer module collection is preserved

Claim: when `P/__init__.py` matches `python_files`, `Package.collect(P)` can
yield a `Module` for that initializer, and the initializer can still be imported
through normal `Module.collect()`.

Intent trace: F4, SPEC C4.

Code evidence: V1 leaves this branch unchanged:
`if init_module.check(file=1) and path_matches_patterns(init_module,
self.config.getini("python_files")): yield Module(init_module, self)`.

Status: discharged.

## PO5 - Public compatibility frame

Claim: the repair must not change hook signatures, collector public classes,
node parent-chain shape, or `python_files` matching behavior.

Intent trace: F5, SPEC C5.

Code evidence: V1 adds one private helper method on `Module`, moves an existing
mount call, and does not alter hook signatures or return types.

Status: discharged.

## PO6 - Honesty and execution boundary

Claim: the FVK proof must be reported as constructed, not machine-checked, and
must not justify deleting or modifying tests in this no-execution environment.

Intent trace: task instructions and FVK verify.md honesty gate.

Status: discharged by artifact labeling and by making no test edits.
