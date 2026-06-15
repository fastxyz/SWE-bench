# Formal Spec In English

Status: constructed, not machine-checked.

## `CHOICES-CREATION-MARKS`

For any choices class name and member map passed to the modeled
`createChoices` step, the resulting class table contains that class name bound
to an enum class with `do_not_call_in_templates` represented as `true`.

## `TEMPLATE-ENUM-MEMBER-LOOKUP`

If the template context contains `YearInSchool` as a marked enum class and that
class has a `FRESHMAN` member, then resolving the dotted template path
`YearInSchool.FRESHMAN` first preserves the callable class at the callable gate
and then resolves `FRESHMAN` from the class's member map.

## `UNMARKED-ENUM-CLASS-FAILS`

If the same template path starts from an unmarked callable enum class, the
callable gate calls or invalidates the class before the member lookup can
complete. In the model this reaches `invalid`. This claim explains the reported
pre-fix failure path.

## `CHOICES-MEMBER-FRAME`

Adding the template marker to a choices enum class does not change the member
map. A class with member map `M` still has member map `M` after the creation
step.

## Compatibility frame

The V1 source change does not change public function signatures, constructor
arguments, exports, or template callable semantics for values outside the
choices enum class family.
