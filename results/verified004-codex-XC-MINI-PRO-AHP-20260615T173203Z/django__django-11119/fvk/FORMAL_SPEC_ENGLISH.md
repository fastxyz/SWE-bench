# Formal Spec In English

Status: paraphrase of `fvk/engine-render-to-string-spec.k`.

## HONOR-ENGINE-AUTOESCAPE

For every engine autoescape value `EA` and every template-name branch `TN`, calling `render_to_string()` with a plain non-`Context` context reaches a render result whose observed autoescape value is `EA`.

## FALSE-DISCRIMINATOR

For every template-name branch `TN`, when the engine autoescape value is `False` and the input context is plain, `render_to_string()` reaches a render result whose observed autoescape value is `False`.

This is the reported bug's distinguishing case: the legacy behavior would render with `True`.

## PRESERVE-EXISTING-CONTEXT

For every engine autoescape value `EA`, every caller-supplied context autoescape value `CA`, and every template-name branch `TN`, calling `render_to_string()` with an existing `Context` reaches a render result whose observed autoescape value is `CA`, not forcibly `EA`.

## Frame Conditions

The formal claims do not alter template selection, method arity, return type, or caller-supplied `Context` identity. They only specify the autoescape flag that reaches rendering.
