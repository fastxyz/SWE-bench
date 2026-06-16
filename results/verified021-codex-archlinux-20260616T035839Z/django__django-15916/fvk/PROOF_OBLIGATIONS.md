# PROOF_OBLIGATIONS.md

Status: constructed, not machine-checked.

## PO1: Factory Omission Preserves Inherited Meta Callback

- Claim: `FACTORY-OMITTED-PRESERVES-META`.
- Public evidence: E1, E2.
- Precondition: factory callback argument is `None`; inherited/resolved base
  `Meta` callback is `cbMeta`.
- Postcondition: generated form resolves callback `cbMeta`.
- V2 discharge: `modelform_factory()` creates no top-level override when the
  argument is `None`; generated `Meta` inherits `cbMeta`; metaclass reads
  `opts.formfield_callback`.
- Finding link: F2.

## PO2: Direct Meta Callback Is Used

- Claim: `META-DIRECT`.
- Public evidence: E2, E3.
- Precondition: no top-level class attribute override; resolved `Meta`
  contains callback `cbMeta`.
- Postcondition: `fields_for_model()` receives `cbMeta`.
- V2 discharge: `ModelFormOptions` stores the option and metaclass uses
  `opts.formfield_callback`.
- Finding link: F3.

## PO3: Explicit Factory Callback Overrides Meta

- Claim: `FACTORY-EXPLICIT-OVERRIDES-META`.
- Public evidence: E5.
- Precondition: factory callback argument is non-`None`.
- Postcondition: generated form resolves the explicit factory callback.
- V2 discharge: factory sets both `Meta.formfield_callback` and the top-level
  metaclass override for non-`None` arguments.
- Finding link: none open.

## PO4: Explicit Top-Level Class Attribute Overrides Meta

- Claims: `TOP-LEVEL-OVERRIDE`, `TOP-LEVEL-NONE-DISABLES`.
- Public evidence: E5 and existing implementation path.
- Precondition: class attributes include `formfield_callback`.
- Postcondition: that class attribute value wins, including explicit `None`.
- V2 discharge: metaclass records `formfield_callback_provided` before popping
  the attribute.
- Finding link: none open.

## PO5: Falsey Non-None Factory Callback Is Explicit

- Claim: `FACTORY-FALSEY-NON-NONE-OVERRIDES`.
- Public evidence: E6.
- Precondition: factory argument is a falsey object distinct from `None`.
- Postcondition: callback resolution returns that object.
- V2 discharge: factory checks `is not None`.
- Finding link: F4.

## PO6: Replacement Meta Does Not Leak Base Callback

- Claim: `REPLACED-META-DOES-NOT-LEAK-BASE`.
- Public evidence: E3, E4.
- Precondition: child form defines a replacement `Meta` without
  `formfield_callback`; base form `Meta` has a callback.
- Postcondition: child form resolves no callback.
- V2 discharge: removed V1's separate base-form fallback; only the resolved
  `Meta` object is consulted when no top-level override exists.
- Finding link: F1.

## PO7: Inherited Meta Still Preserves Callback

- Claim: `INHERITED-META-PRESERVES`.
- Public evidence: E4 and E5.
- Precondition: child form has no replacement `Meta`; first parent `Meta` has
  callback `cbBase`.
- Postcondition: child form resolves `cbBase`.
- V2 discharge: Python name resolution makes `getattr(new_class, "Meta", None)`
  return the parent `Meta`, and `ModelFormOptions` reads its callback.
- Finding link: none open.

## PO8: Invalid Callback Validation Is Preserved

- Claim: represented by frame condition rather than a separate K branch.
- Public evidence: E5.
- Precondition: chosen callback object is non-`None` and non-callable.
- Postcondition: `fields_for_model()` still raises
  `TypeError("formfield_callback must be a function or callable")`.
- V2 discharge: no change to `fields_for_model()` validation; metaclass merely
  passes the selected object through.
- Finding link: none open.
