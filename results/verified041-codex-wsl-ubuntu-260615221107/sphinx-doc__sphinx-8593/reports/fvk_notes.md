# FVK Notes

## Decisions

* Changed `repo/sphinx/ext/autodoc/__init__.py` so attribute-comment visibility metadata becomes the effective metadata source when it contains `:meta public:` or `:meta private:`. This addresses `fvk/FINDINGS.md` F-2 and discharges `fvk/PROOF_OBLIGATIONS.md` PO-3. V1 merged attribute metadata with runtime-docstring metadata; the FVK audit showed that could still let an unrelated runtime `private` marker win over explicit variable documentation.

* Kept the parser and analyzer unchanged. `fvk/FINDINGS.md` F-1 and `fvk/PROOF_OBLIGATIONS.md` PO-1 show that variable comments already flow from `VariableCommentPicker` into `ModuleAnalyzer.attr_docs`; the defect was in consumption during filtering, not in capture.

* Kept the fix inside `Documenter.filter_members()` rather than changing module member collection or data documenter selection. `fvk/FINDINGS.md` F-1 and `fvk/PROOF_OBLIGATIONS.md` PO-4 show that once `isprivate` is computed correctly, the existing attribute-documentation branch already keeps public documented attributes and sets `isattr = True`.

* Preserved existing skip and frame behavior for mocked members, excluded members, special members, `__all__` skipped members, and user `autodoc-skip-member` overrides. This is required by `fvk/PROOF_OBLIGATIONS.md` PO-6 and recorded in `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`.

* Did not modify tests and did not run tests, Python, or K tooling. `fvk/FINDINGS.md` F-3 and `fvk/PROOF_OBLIGATIONS.md` PO-7 record the task constraint and the constructed-not-machine-checked status. The K commands are written in `fvk/PROOF.md` and `fvk/ITERATION_GUIDANCE.md` for a future executable environment.

## Outcome

V2 is a small improvement over V1: it keeps V1's fix for `_foo = None  #: :meta public:` and also handles the proof-derived conflict case where a variable's explicit attribute comment has visibility metadata that conflicts with the assigned object's runtime docstring metadata. No further source changes are justified by the FVK findings.
