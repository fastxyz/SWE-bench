# Formal Spec English

Status: plain-English paraphrase of the K claims and frame obligations.

## Claims

`CLAIM-PREPARE-INVALID`

For any raw submitted string `S` and encoder `E`, evaluating `prepareValue(invalidInput(S), E)` returns `raw(S)`. The JSON dumping operation is not reached.

`CLAIM-PREPARE-UNICODE-CHINA`

For the public issue's concrete Chinese text discriminator, evaluating `prepareValue(jstring(chinaText), E)` returns the readable Unicode display state `displayUnicodeChina`.

`CLAIM-PREPARE-GENERAL`

For any JSON value `V` that is not invalid input and any encoder `E`, evaluating `prepareValue(V, E)` returns `jsonDumps(V, false, E)`. The `false` flag is the model of `ensure_ascii=False`, and the encoder argument is preserved.

## Frame Obligations

Database serialization remains unchanged because the database JSON field source path is not edited.

Form widget rendering remains unchanged because the source change does not alter `BoundField`, `Widget`, `Textarea`, templates, or safe-string handling.

Valid bound JSON redisplay composes `bound_data()` decoding with the same non-invalid `prepareValue` display contract.
