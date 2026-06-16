requires "mini-python-json-script.k"

module JSON-SCRIPT-SPEC
  imports MINI-PYTHON-JSON-SCRIPT

  // SPEC-PROVENANCE:
  // - from_prompt: "Make the element_id argument of json_script optional"
  //   => omitting element_id is in-domain.
  // - from_prompt: "I didn't need any id for it"
  //   => the omitted form must not render an id attribute.
  claim
    <k> jsonScript(V:Value, omitted)
      => "<script type=\"application/json\">" +String JSONESC(V) +String "</script>"
    </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "I didn't need any id for it"
  //   => explicit None follows the same no-id behavior as omission.
  // - from_default_domain: Python optional arguments commonly use None as
  //   the absent sentinel.
  claim
    <k> jsonScript(V:Value, noneId)
      => "<script type=\"application/json\">" +String JSONESC(V) +String "</script>"
    </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_docs_or_tests: existing json_script examples and public tests
  //   show id="..." when a concrete id is supplied.
  // - from_code: format_html() escapes attributes through conditional_escape().
  claim
    <k> jsonScript(V:Value, id(E:String))
      => "<script id=\"" +String HTMLESC(E) +String "\" type=\"application/json\">" +String JSONESC(V) +String "</script>"
    </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: django.template.defaultfilters.json_script delegates to
  //   django.utils.html.json_script with the same argument.
  claim
    <k> filterJsonScript(V:Value, I:IdArg) => jsonScript(V, I) </k>
    [all-path]
endmodule
