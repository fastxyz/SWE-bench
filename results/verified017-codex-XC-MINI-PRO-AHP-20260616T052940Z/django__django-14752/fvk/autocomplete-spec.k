// Constructed, not machine-checked.
// These claims are the formal core for the V1 AutocompleteJsonView audit.

requires "mini-python-autocomplete.k"

module AUTOCOMPLETE-SPEC
  imports MINI-PYTHON-AUTOCOMPLETE

  // SPEC-PROVENANCE:
  // - from_prompt: "serialize_result() contains the original object to
  //   dictionary conversion code" => default serializer returns the legacy
  //   id/text result.
  // - from_code: repo/django/contrib/admin/views/autocomplete.py:
  //   serialize_result(obj, to_field_name) returns
  //   {'id': str(getattr(obj, to_field_name)), 'text': str(obj)}.
  claim applyHook(defaultHook, obj(ID, TEXT), FIELD)
    => result(ID, TEXT)

  // SPEC-PROVENANCE:
  // - from_prompt: "self.serialize_result(obj, to_field_name) for obj in
  //   context['object_list']" => get() must map every object through the hook.
  // - from_prompt: "pagination: {'more': context['page_obj'].has_next()}" =>
  //   pagination is preserved while result serialization is customized.
  // - from_code: V1 calls self.serialize_result(obj, to_field_name) in the list
  //   comprehension and leaves pagination unchanged.
  claim buildResponse(OBJECTS, FIELD, MORE, HOOK)
    => response(mapResults(OBJECTS, FIELD, HOOK), MORE)

  // SPEC-PROVENANCE:
  // - from_prompt: "simple, side-effect- and risk-free" and the before/after
  //   snippets => default AutocompleteJsonView output remains the legacy
  //   sequence of id/text dictionaries.
  // - from_code: composing get() with the default serializer yields the same
  //   per-object id/text result as the pre-V1 inline comprehension.
  claim buildResponse(OBJECTS, FIELD, MORE, defaultHook)
    => response(defaultResults(OBJECTS), MORE)
endmodule
