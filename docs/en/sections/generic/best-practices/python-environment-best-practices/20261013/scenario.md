<!--- 

If applicable start with an image that provides a visual overview.
Place your image in the img subfolder.
Replace with your description and filename

![Description](sections/generic/best-practices/python-environment-best-practices/20261013/img/ExampleImage.png)

-->

## Scenario

A SAS Viya administrator maintains Python environments that many users and workloads share. Data scientists, data engineers, and production processes all depend on these environments to run Python code in SAS Compute, CAS, and MAS. Without clear practices, environments tend to grow into large, all-purpose installations that are hard to secure, troubleshoot, and rebuild. A single package change can then break unrelated programs, models, or decision flows.

This Best Practice covers how to design, govern, and maintain shared Python environments in SAS Viya so they stay isolated, secure, and reproducible. It addresses one requirement: **every shared Python environment can be traced, controlled, and rebuilt to a known, validated state.**

**In scope**

- Shared Python environments used by Compute, CAS, and MAS
- Environment design, access control, package governance, versioning, and reproducible definitions
- Any infrastructure provider, since these practices do not depend on a specific cloud platform

**Out of scope**

- Step-by-step upgrade, dry run, compatibility testing, and rollback procedures
- Detailed configuration of sas-pyconfig or Code Environment Management
- Personal development environments outside a shared SAS Viya deployment