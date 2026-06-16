// Constructed FVK artifact, not machine-checked.
// Claims for the keyboard tokenizer obligations. SPEC-PROVENANCE comments
// reference the public intent ledger in fvk/SPEC.md.

requires "mini-keyboard.k"

module KEYBOARD-TRANSFORM-SPEC
  imports MINI-KEYBOARD
  imports STRING
  imports BOOL
  imports LIST

  // SPEC-PROVENANCE:
  // - INT-1/INT-3: standalone "-", "+", and "^" are keys, not separators.
  claim
    <k> splitKeys("-") => .K ... </k>
    <out> .List => ListItem(key("-")) </out>
    [all-path]

  claim
    <k> splitKeys("+") => .K ... </k>
    <out> .List => ListItem(key("+")) </out>
    [all-path]

  claim
    <k> splitKeys("^") => .K ... </k>
    <out> .List => ListItem(key("^")) </out>
    [all-path]

  // SPEC-PROVENANCE:
  // - INT-4/INT-5: ordinary compound key syntax remains supported.
  claim
    <k> splitKeys("Control+X") => .K ... </k>
    <out> .List => ListItem(key("Control")) ListItem(sep("+")) ListItem(key("X")) </out>
    [all-path]

  claim
    <k> splitKeys("M-x  M-s") => .K ... </k>
    <out> .List =>
      ListItem(key("M")) ListItem(sep("-")) ListItem(key("x"))
      ListItem(sep("  ")) ListItem(key("M")) ListItem(sep("-")) ListItem(key("s"))
    </out>
    [all-path]

  // SPEC-PROVENANCE:
  // - INT-2/INT-3: punctuation separators in key position are key text.
  claim
    <k> splitKeys("Shift-+") => .K ... </k>
    <out> .List => ListItem(key("Shift")) ListItem(sep("-")) ListItem(key("+")) </out>
    [all-path]

  claim
    <k> splitKeys("Shift--") => .K ... </k>
    <out> .List => ListItem(key("Shift")) ListItem(sep("-")) ListItem(key("-")) </out>
    [all-path]

  claim
    <k> splitKeys("Shift-^") => .K ... </k>
    <out> .List => ListItem(key("Shift")) ListItem(sep("-")) ListItem(key("^")) </out>
    [all-path]

  claim
    <k> splitKeys("Control++") => .K ... </k>
    <out> .List => ListItem(key("Control")) ListItem(sep("+")) ListItem(key("+")) </out>
    [all-path]

  claim
    <k> splitKeys("Control+-") => .K ... </k>
    <out> .List => ListItem(key("Control")) ListItem(sep("+")) ListItem(key("-")) </out>
    [all-path]

  claim
    <k> splitKeys("Control+^") => .K ... </k>
    <out> .List => ListItem(key("Control")) ListItem(sep("+")) ListItem(key("^")) </out>
    [all-path]
endmodule
