# Formal Spec in English

This paraphrases the K claims in `blueprint-name-spec.k`.

- `C-INIT-EMPTY`: Starting constructor validation with `name == ""` must produce `valueErrorRaised`.
- `C-INIT-DOTTED`: Starting constructor validation with a non-empty dotted name must produce `valueErrorRaised`, preserving the existing dotted-name validation.
- `C-INIT-NONEMPTY`: Starting constructor validation with a non-empty, non-dotted name must produce normal initialization with the blueprint name stored.
- `C-REGISTER-EMPTY-OVERRIDE`: Starting registration with an explicit name option whose value is `""` must produce `valueErrorRaised` and leave `app.blueprints` unchanged.
- `C-REGISTER-EMPTY-DEFAULT`: Starting registration with no name option and a stored blueprint name of `""` must produce `valueErrorRaised` and leave `app.blueprints` unchanged.
- `C-REGISTER-NONEMPTY-NOCONFLICT`: Starting registration with a non-empty effective name and no duplicate-name conflict must proceed to normal registration and store the blueprint under the computed effective name.
