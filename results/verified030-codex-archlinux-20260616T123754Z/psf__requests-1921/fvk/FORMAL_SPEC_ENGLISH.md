# Formal Spec English

Status: English paraphrase of the K claims, constructed but not
machine-checked.

## Claims

- C-MERGE-MAPPING: When both inputs are mappings, `mergeSetting(request,
  session)` returns the session mapping overlaid with the request mapping, then
  removes every key whose final value is `noneVal`.

- C-SESSION-NONE: If the session mapping contains canonical header key
  `accept-encoding` with value `noneVal`, and the request mapping has no value
  for that key, the result has no `accept-encoding` key.

- C-REQUEST-NONE: If the session mapping contains `foo: "bar"` and the request
  mapping contains the same canonical key with `noneVal`, the result has no
  `foo` key.

- C-REQUEST-OVERRIDE: If the session mapping contains `accept-encoding:
  noneVal` and the request mapping contains `accept-encoding: "identity"`, the
  result contains `accept-encoding: "identity"`.

- C-NONMAPPING-FRAME: If the request setting is scalar and the session setting
  is a mapping, `mergeSetting()` returns the scalar request setting, matching
  the pre-existing non-mapping bypass.

## Side Conditions

- Header keys in these claims are canonical lowercase keys. This models the
  `CaseInsensitiveDict` behavior used by `Session.prepare_request()`.
- The claims cover mappings accepted by `to_key_val_list()` and exclude
  duplicate lowercased header keys, matching the documented undefined behavior
  of `CaseInsensitiveDict` for equal lowercase keys.
- The proof is partial correctness: if the helper returns normally, the result
  has the stated shape. Termination of Python's finite list/dictionary
  operations is not separately machine-proved.

