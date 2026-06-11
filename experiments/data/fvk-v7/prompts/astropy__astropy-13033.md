# Guidance for Autonomous Program-Repair Agent

Use the solved examples as a senior engineer uses precedent:
- Study each issue → patch mapping to understand the diagnostic approach and fix **shape**.
- Transfer patterns, not text: never copy line numbers, file names, or exact wording.
  Instead, see how the maintainers inserted a guard clause, enriched an error message,
  or parameterised a check. Apply the same reasoning to the new problem.
- The examples are from different codebases, but they reveal universal patterns:
  make error messages informative, validate early, include the offending value.

---

## Example 1: django__django-13212 – Make validators include the provided value in ValidationError

**Issue summary**  
Validators (URL, email, int, etc.) raised `ValidationError` without the actual value that caused the failure, making it impossible to build custom error messages using `%(value)s`. The maintainers solved this by passing `params={'value': value}` to every `ValidationError` in the validators.

**Relation to target**  
The target issue is also about a misleading / uninformative exception when a required column check fails. The fix shape here is **enriching the error payload** with the exact data that triggered the failure (e.g., which column is missing, what was found). That pattern transfers directly – if the validation is already in place, the minimal fix is to include the relevant context in the exception, exactly like this example adds the invalid value.

**What transfers**  
- A localised, repetitive change inside an existing validation function: add `params={...}` (or, in astropy, perhaps passing extra keyword arguments to `ValueError`) to make the message dynamic.
- The change is small, mechanical, and confined to the error‑raising lines; the rest of the validation logic is unchanged.

**Gold patch (truncated in source)**

```diff
diff --git a/django/core/validators.py b/django/core/validators.py
--- a/django/core/validators.py
+++ b/django/core/validators.py
@@ -48,7 +48,7 @@ def __call__(self, value):
         regex_matches = self.regex.search(str(value))
         invalid_input = regex_matches if self.inverse_match else not regex_matches
         if invalid_input:
-            raise ValidationError(self.message, code=self.code)
+            raise ValidationError(self.message, code=self.code, params={'value': value})
 
     def __eq__(self, other):
         return (
@@ -100,11 +100,11 @@ def __init__(self, schemes=None, **kwargs):
 
     def __call__(self, value):
         if not isinstance(value, str):
-            raise ValidationError(self.message, code=self.code)
+            raise ValidationError(self.message, code=self.code, params={'value': value})
         # Check if the scheme is valid.
         scheme = value.split('://')[0].lower()
         if scheme not in self.schemes:
-            raise ValidationError(self.message, code=self.code)
+            raise ValidationError(self.message, code=self.code, params={'value': value})
 
         # Then check full URL
         try:
@@ -115,7 +115,7 @@ def __call__(self, value):
                 try:
                     scheme, netloc, path, query, fragment = urlsplit(value)
                 except ValueError:  # for example, "Invalid IPv6 URL"
-                    raise ValidationError(self.message, code=self.code)
+                    raise ValidationError(self.message, code=self.code, params={'value': value})
                 try:
                     netloc = punycode(netloc)  # IDN -> ACE
                 except UnicodeError:  # invalid domain part
@@ -132,14 +132,14 @@ def __call__(self, value):
                 try:
                     validate_ipv6_address(potential_ip)
                 except ValidationError:
-                    raise ValidationError(self.message, code=self.code)
+                    raise ValidationError(self.message, code=self.code, params={'value': value})
 
         # The maximum length of a full host name is 253 characters per RFC 1034
         # section 3.1. It's defined to be 255 bytes or less, but this includes
         # one byte for the length of the name and one byte for the trailing dot
         # that's used to indicate absolute names in DNS.
         if len(urlsplit(value).netloc) > 253:
-            raise ValidationError(self.message, code=self.code)
+            raise ValidationError(self.message, code=self.code, params={'value': value})
 
 
 integer_validator = RegexValidator(
@@ -208,12 +208,12 @@ def __init__(self, message=None, code=None, allowlist=None, *, whitelist=None):
 
     def __call__(self, value):
         if not value or '@' not in value:
-            raise ValidationError(self.message, code=self.code)
+            raise ValidationError(self.message, code=self.code, params={'value': value})
 
         user_part, domain_part = value.rsplit('@', 1)
 
         if not self.user_regex.match(user_part):
-            raise ValidationError(self.message, code=self.code)
+            raise ValidationError(self.message, code=self.code, params={'value': value})
 
         if (domain_part not in self.domain_allowlist and
                 not self.validate_domain_part(domain_part)):
@@ -225,7 +225,7 @@ def __call__(self, value):
             else:
                 if self.validate_domain_part(domain_part):
                     return
-            raise ValidationError(self.message, code=self.code)
+            raise ValidationError(self.message, code=self.code, params={'value': value})
 
     def validate_domain_part(self, domain_part):
         if self.domain_regex.match(domain_part):
@@ -272,12 +272,12 @@ def validate_ipv4_address(value):
     try:
         ipaddress.IPv4Address(value)
     except ValueError:
…(truncated, 89 more lines)
```

---

## Example 2: django__django-13933 – ModelChoiceField does not provide value of invalid choice

**Issue summary**  
`ModelChoiceField.to_python()` raised a `ValidationError` with a generic message "Select a valid choice. That choice is not one of the available choices." but never included the actual invalid value, unlike `ChoiceField` or `ModelMultipleChoiceField`. The fix passes `params={'value': value}` so the error template can show the rejected value.

**Relation to target**  
Again, the problem is an unhelpful exception – the user cannot tell *what* went wrong. The target’s current error says `“expected 'time' as the first columns but found 'time'”` – it is not only uninformative but also self‑contradictory. The pattern here is: **when an invariant check fails, include the actual state** (the value that failed, or the set of required columns vs. the set actually present). That transforms a baffling message into a self‑explanatory one.

**What transfers**  
- A single, surgical change in the validation path: augment the `raise` with missing/additional information.
- The fix preserves the overall flow; it only changes the constructor of the exception.
- The approach works even when the underlying check logic is correct but the message generation is poor.

**Gold patch (verbatim)**

```diff
diff --git a/django/forms/models.py b/django/forms/models.py
--- a/django/forms/models.py
+++ b/django/forms/models.py
@@ -1284,7 +1284,11 @@ def to_python(self, value):
                 value = getattr(value, key)
             value = self.queryset.get(**{key: value})
         except (ValueError, TypeError, self.queryset.model.DoesNotExist):
-            raise ValidationError(self.error_messages['invalid_choice'], code='invalid_choice')
+            raise ValidationError(
+                self.error_messages['invalid_choice'],
+                code='invalid_choice',
+                params={'value': value},
+            )
         return value
 
     def validate(self, value):
```

---

## Example 3: pallets__flask-5014 – Require a non‑empty name for Blueprints

**Issue summary**  
A `Blueprint` with an empty name leads to obscure failures later. The fix adds an early, explicit `ValueError("'name' may not be empty.")` right after the constructor starts, before any further processing.

**Relation to target**  
The target’s exception is raised when a required column is missing (or removed). This is a structural invariant that can be checked *early* – as soon as the object is modified – rather than relying on a later misinterpretation. The pattern of **inserting a guard clause with a clear error message** directly addresses the issue: the user gets a straightforward message saying which required columns are missing, instead of a confusing internal‑state dump.

**What transfers**  
- Validate the precondition as soon as possible; raise a dedicated `ValueError` with a descriptive string.
- The check should be self‑contained, using only local state (e.g., `colnames`, `required_columns`).
- The patch is tiny – one line of validation – and does not restructure the surrounding code.

**Gold patch (verbatim)**

```diff
diff --git a/src/flask/blueprints.py b/src/flask/blueprints.py
--- a/src/flask/blueprints.py
+++ b/src/flask/blueprints.py
@@ -190,6 +190,9 @@ def __init__(
             root_path=root_path,
         )
 
+        if not name:
+            raise ValueError("'name' may not be empty.")
+
         if "." in name:
             raise ValueError("'name' may not contain a dot '.' character.")
 
```

---

**How to proceed with the target issue**  
- Inspect the `TimeSeries` code where the “expected 'time' as the first columns” check is performed and understand why the message becomes contradictory.
- Choose the most fitting pattern from the examples:
  - If the check itself is correct but the message is generic/wrong, apply the **enrichment pattern** (like Examples 1 & 2) – include the actual column names that are required vs. found.
  - If the check can be moved earlier or made unconditional, apply the **guard‑clause pattern** (like Example 3) – add a clear `ValueError` before the confusing part is ever reached.
- Keep the fix minimal, local, and consistent with astropy’s error‑handling conventions (which may differ from Django/Flask, but the principle of informative messages transfers).

The examples show that a small, targeted change in the error‑raising code is sufficient; they also demonstrate that the fix never touches unrelated logic, preserves public API, and uses the codebase’s existing exception types. Use these insights, not the literal patches, to craft your own repair.
