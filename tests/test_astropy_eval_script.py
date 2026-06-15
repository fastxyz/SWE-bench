from swebench.harness.constants.python import SPECS_ASTROPY
from swebench.harness.test_spec.python import make_eval_script_list_py


def test_astropy_eval_script_ignores_legacy_warning_noise():
    test_patch = """diff --git a/astropy/units/tests/test_quantity.py b/astropy/units/tests/test_quantity.py
--- a/astropy/units/tests/test_quantity.py
+++ b/astropy/units/tests/test_quantity.py
@@ -1,1 +1,1 @@
-old
+new
"""
    instance = {
        "repo": "astropy/astropy",
        "version": "4.1",
        "test_patch": test_patch,
    }

    script = make_eval_script_list_py(
        instance,
        SPECS_ASTROPY["4.1"],
        "testbed",
        "/testbed",
        "abc123",
        test_patch,
    )

    install_index = script.index("python -m pip install -e .[test] --verbose")
    shim_index = next(
        i for i, cmd in enumerate(script) if "setuptools._distutils.version" in cmd
    )
    test_command = next(cmd for cmd in script if cmd.startswith("pytest "))
    test_index = script.index(test_command)

    assert install_index < shim_index < test_index
    assert "_pytest.python" in script[shim_index]
    assert "-p no:warnings" in test_command
    assert (
        "-o filterwarnings=ignore:Support.*nose.*deprecated:Warning" in test_command
    )
    assert (
        "-o filterwarnings=ignore:distutils.*Version.*deprecated:DeprecationWarning"
        in test_command
    )
