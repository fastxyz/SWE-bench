// Constructed claims for the django__django-12304 FVK audit.
// Not machine-checked in this session.

requires "mini-django-template.k"

module CHOICES-TEMPLATE-SPEC
  imports MINI-DJANGO-TEMPLATE
  imports MAP

  // SPEC-PROVENANCE:
  // - from_prompt: "declare do_not_call_in_templates = True on the various Choices classes"
  //   => choices enum class creation must install the template marker.
  // - from_code: V1 assigns cls.do_not_call_in_templates = True after EnumMeta creates cls.
  claim
    <k> createChoices(YearInSchool, FRESHMAN |-> member(FRESHMAN, invalid)) => .K </k>
    <classes>
      .Map => YearInSchool |-> enumClass(true, FRESHMAN |-> member(FRESHMAN, invalid))
    </classes>
    <context> .Map </context>
    <current> none </current>
    [label(CHOICES-CREATION-MARKS), all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "{% if student.year_in_school == YearInSchool.FRESHMAN %}"
  //   => the dotted template path must reach FRESHMAN.
  // - from_template_hook: do_not_call_in_templates preserves callable values
  //   and allows normal attribute lookup.
  claim
    <k> lookup(YearInSchool) ~> callGate ~> attr(FRESHMAN) ~> callGate => .K </k>
    <context>
      YearInSchool |-> enumClass(true, FRESHMAN |-> member(FRESHMAN, invalid))
    </context>
    <classes> .Map </classes>
    <current> none => member(FRESHMAN, invalid) </current>
    [label(TEMPLATE-ENUM-MEMBER-LOOKUP), all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "YearInSchool, being a class, is callable, and Django Templates
  //   always call callables with no arguments. The call fails..."
  //   => without the marker, the callable gate consumes/invalidates the class.
  // - diagnostic only: this is the pre-fix failure, not desired V2 behavior.
  claim
    <k> lookup(YearInSchool) ~> callGate => .K </k>
    <context>
      YearInSchool |-> enumClass(false, FRESHMAN |-> member(FRESHMAN, invalid))
    </context>
    <classes> .Map </classes>
    <current> none => invalid </current>
    [label(UNMARKED-ENUM-CLASS-FAILS), all-path]

  // SPEC-PROVENANCE:
  // - from_public_api: Choices member values and labels must not change.
  // - from_code: V1 adds the marker after class creation and does not mutate
  //   the member map.
  claim
    <k> createChoices(YearInSchool, MEMBERS:Map) => .K </k>
    <classes> .Map => YearInSchool |-> enumClass(true, MEMBERS) </classes>
    <context> .Map </context>
    <current> none </current>
    [label(CHOICES-MEMBER-FRAME), all-path]
endmodule
