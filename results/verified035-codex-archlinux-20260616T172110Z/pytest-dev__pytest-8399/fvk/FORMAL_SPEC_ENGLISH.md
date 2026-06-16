# Formal Spec In English

Constructed, not machine-checked.

C1. For any unittest class qualname `Q`, rendering the generated
`setUpClass` fixture name produces `_unittest_setUpClass_fixture_` followed by
`Q`.

C2. For any unittest class qualname `Q`, rendering the generated unittest
`setup_method` fixture name produces `_unittest_setup_method_fixture_` followed
by `Q`.

C3. For any module name `M`, rendering the generated xunit setup-module fixture
name produces `_xunit_setup_module_fixture_` followed by `M`.

C4. For any module name `M`, rendering the generated xunit setup-function
fixture name produces `_xunit_setup_function_fixture_` followed by `M`.

C5. For any class qualname `Q`, rendering the generated xunit setup-class
fixture name produces `_xunit_setup_class_fixture_` followed by `Q`.

C6. For any class qualname `Q`, rendering the generated xunit setup-method
fixture name produces `_xunit_setup_method_fixture_` followed by `Q`.

C7. For non-verbose fixture listing, a list containing only generated setup
fixture names from C1-C6 is rendered as an empty visible list.

C8. For verbose fixture listing, generated setup fixture names from C1-C6 remain
visible/available in the modeled listing.

Frame claim F. The patch changes only the explicit fixture registration names;
it does not change the generated fixture functions, hook invocation bodies,
scopes, autouse flags, cleanup behavior, or attachment attributes.
