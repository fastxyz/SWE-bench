# Findings

Status: constructed for FVK audit, not machine-checked.

## F-1: Pre-V1 autodoc missed `returns` in documented mode

Input: field list contains `:returns: The returned value`, annotations contain
`return -> str`, and `autodoc_typehints_description_target = "documented"`.

Observed pre-V1 behavior: no `rtype` field was generated because autodoc only
treated field name `return` as a return description.

Expected behavior: `rtype` should be generated because `returns` is a valid
Python-domain return-value field and Napoleon emits it.

Classification: code bug in autodoc. Status: fixed by V1 and discharged by
`PO-2` and `PO-3`.

## F-2: Changing Napoleon output is not justified

Input: Napoleon parses a Google-style `Returns:` section.

Observed behavior: Napoleon emits `:returns:`.

Expected behavior: autodoc should accept that valid field name. The Python domain
already declares `returns` and `return` as aliases.

Classification: rejected alternative. Status: no Napoleon source change.
Supported by `PO-5` and compatibility audit.

## F-3: `"all"` target branch does not require a source change

Input: annotations contain `return`, field list contains `:returns:` but no
`:rtype:`, and `autodoc_typehints_description_target = "all"`.

Observed source behavior: `modify_field_list()` adds `rtype` when a return
annotation exists and no `rtype` was detected.

Expected behavior: unchanged. The reported defect is in the `"documented"` branch
where a return description must be recognized before `rtype` is added.

Classification: no V2 source change needed. Supported by `PO-5`.

## F-4: Public tests cover the neighboring `return` spelling, not this alias

Input: public test uses `:return:` in documented mode.

Observed public coverage: the existing public test checks `return` and general
documented-mode behavior. Public Napoleon tests show `:returns:` output, but no
public test combines the exact issue path.

Expected next test when tests are editable: add a documented-mode autodoc case
with `:returns:` or Napoleon-generated `Returns:`.

Classification: test gap. Status: no test files modified because this benchmark
forbids it.

## F-5: Proof is constructed only

Input: FVK `.k` artifacts and proof obligations in this workspace.

Observed process: commands were written but not executed, as required by the
benchmark instructions.

Expected process: run the emitted `kompile` and `kprove` commands in an execution
environment before treating proof-based test removal as safe.

Classification: honesty gate / residual risk.
