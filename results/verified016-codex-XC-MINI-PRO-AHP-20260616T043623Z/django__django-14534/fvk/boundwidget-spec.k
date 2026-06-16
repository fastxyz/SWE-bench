requires "mini-django-boundwidget.k"

module BOUNDWIDGET-SPEC
  imports MINI-DJANGO-BOUNDWIDGET
  imports MAP
  imports STRING
  imports BOOL

  // SPEC-PROVENANCE:
  // - from_prompt: "widget['attrs']['id'] contains the 'id' we would like to use"
  //   => return the rendered subwidget id when present.
  // - from_code: ChoiceWidget.create_option() stores the computed rendered id in
  //   option attrs before BoundWidget wraps the option dictionary.
  claim [ID-FOR-LABEL-PRESENT]:
    <k> idForLabel(("id" |-> ID:String) REST:Map) => ID </k>
    requires notBool ("id" in_keys(REST))
    [all-path]

  // SPEC-PROVENANCE:
  // - from_docs: id_for_label outputs the element's ID.
  // - from_templates: option/input templates only render a label target when
  //   widget.attrs.id exists.
  // - conflict: an existing select-option test expects an invented id even
  //   though the rendered option has no id; recorded as F-002.
  claim [ID-FOR-LABEL-ABSENT]:
    <k> idForLabel(ATTRS:Map) => "" </k>
    requires notBool ("id" in_keys(ATTRS))
    [all-path]
endmodule
