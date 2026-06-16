# FVK Findings

Status: constructed, not machine-checked. Findings are from public intent,
static source inspection, and the constructed proof obligations.

## F-01: Resolved - named enum defaults used Python's ugly enum repr

Evidence: `benchmark/PROBLEM.md` shows the observed default text
`<MyEnum.ValueA: 10>` and the expected text `MyEnum.ValueA`.

Static cause: `stringify_signature()` formats `param.default` through
`object_description()`. Before the fix, `object_description()` reached generic
`repr()` for enum members.

Expected: named enum member defaults render as `EnumClass.Member`.

Resolution: `object_description()` now returns the enum class qualname plus the
member name for named enum members. This discharges PO-01, PO-02, and PO-03.

## F-02: Resolved - V1 over-assumed every enum value has one valid member name

Evidence: V1 returned `"%s.%s" % (object.__class__.__qualname__, object.name)`
for every `enum.Enum` instance. That is correct for the issue's direct
`Enum` member, but the branch also covers `enum.Flag` values.

Modeled problematic inputs:

- named flag combination with name `READ|WRITE` -> V1 would produce
  `Perm.READ|WRITE`, leaving `WRITE` unqualified;
- enum or flag value with `name is None` -> V1 would produce `Perm.None`,
  inventing a member spelling.

Expected: only use `EnumClass.Member` when a member spelling exists; qualify
each component of a named flag combination; otherwise preserve the repr fallback.

Resolution: V2 stores `enum_name = object.name`, checks it is not `None`, and
for `enum.Flag` values qualifies each pipe-separated component. Nameless enum
values fall through to the existing repr path. This discharges PO-05.

## F-03: Confirmed frame - non-enum formatting remains unchanged

Evidence: `benchmark/PROBLEM.md` targets enum defaults specifically, and its
hint says `repr()` remains generally appropriate for default values.

Expected: non-enum objects keep the existing dict/set/frozenset/`repr` behavior.

Resolution: the enum branch returns only for named enum values. All non-enum
objects and nameless enum values continue into the pre-existing branches. This
discharges PO-04.

## F-04: Residual ambiguity - custom enum `__repr__`

Evidence: the issue suggests custom `__repr__` as a workaround before Sphinx
has an enum special case. It does not state that Sphinx must continue honoring
custom enum repr once the special case exists.

Decision: keep the enum member-reference rule for named enum members. This is
the only behavior directly supported by the public expected output. A future
compatibility decision could make custom enum repr configurable, but that is
not required by this issue.

Related obligations: PO-01, PO-02, PO-06.

## F-05: Residual scope note - containers containing enum values

Evidence: `object_description()` recursively formats dict, set, and frozenset
contents, but not list or tuple contents. The public issue shows a direct enum
default, not a container default containing enum members.

Decision: do not broaden the patch to list/tuple recursion in this pass. Such
a change would affect a wider formatting surface and lacks direct public
evidence here.

Related obligations: PO-04 and PO-07.
