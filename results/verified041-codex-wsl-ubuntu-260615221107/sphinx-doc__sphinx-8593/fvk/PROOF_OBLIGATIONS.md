# Proof Obligations

Status: constructed, not machine-checked.

## PO-1: Variable comments reach `attr_docs`

* Statement: for an assignment with a `#:` comment, the analyzer records `(namespace, membername) -> comment lines` in `attr_docs`.
* Evidence: `repo/sphinx/pycode/parser.py:271` stores comments by `(basename, name)`; `repo/sphinx/pycode/parser.py:370` through `repo/sphinx/pycode/parser.py:378` capture comments after assignment; `repo/sphinx/pycode/__init__.py:170` through `repo/sphinx/pycode/__init__.py:175` expose them as lists in `attr_docs`.
* Status: discharged by source inspection; no code change needed.

## PO-2: Attribute-comment metadata participates in `isprivate`

* Statement: if `attr_doc` contains `public`, `isprivate` must be false; if it contains `private`, `isprivate` must be true.
* Evidence: public docs define metadata as visibility override; issue requires `public` on a variable to be honored.
* Status: discharged by V2 lines `repo/sphinx/ext/autodoc/__init__.py:733` through `repo/sphinx/ext/autodoc/__init__.py:746`.

## PO-3: Attribute-comment visibility takes precedence for documented variables

* Statement: when `attr_doc` contains a visibility marker, that marker is the effective visibility metadata for the documented variable, even if the assigned runtime object has conflicting docstring metadata.
* Evidence: `repo/sphinx/ext/autodoc/__init__.py:599` through `repo/sphinx/ext/autodoc/__init__.py:609` use `attr_docs` as the attribute documentation content.
* V1 status: failed.
* V2 status: discharged by `repo/sphinx/ext/autodoc/__init__.py:735` through `repo/sphinx/ext/autodoc/__init__.py:739`.

## PO-4: Documented attribute branch keeps public attribute docs and sets `isattr`

* Statement: for `attr_doc is not None`, non-private all-members filtering keeps the member and sets `isattr = True`.
* Evidence: `repo/sphinx/ext/autodoc/__init__.py:768` through `repo/sphinx/ext/autodoc/__init__.py:777`.
* Status: discharged; V1/V2 preserve the branch.

## PO-5: Private attribute docs remain skippable unless admitted

* Statement: for `attr_doc is not None`, all-members filtering skips a private member unless `:private-members:` admits it.
* Evidence: public docs for private members and source branch `repo/sphinx/ext/autodoc/__init__.py:769` through `repo/sphinx/ext/autodoc/__init__.py:773`.
* Status: discharged.

## PO-6: Frame conditions for unrelated branches remain unchanged

* Statement: mocked, excluded, special, `__all__` skipped, and event-overridden members keep their existing behavior.
* Evidence: the patch edits only metadata selection before the same branch chain; it does not alter event emission, branch order, or tuple shape.
* Status: discharged by diff inspection.

## PO-7: Honesty gate

* Statement: proof artifacts must be labeled constructed, not machine-checked, and commands must be recorded but not executed.
* Evidence: task forbids test, Python, and K execution.
* Status: discharged in `fvk/PROOF.md`.
