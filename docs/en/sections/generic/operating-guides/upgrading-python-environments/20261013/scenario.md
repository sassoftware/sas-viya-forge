<!--- 

If applicable start with an image that provides a visual overview.
Place your image in the img subfolder.
Replace with your description and filename

![Description](sections/generic/operating-guides/upgrading-python-environments/20261013/img/ExampleImage.png)

-->
## Scenario

A SAS administrator needs to upgrade a Python environment that SAS Viya workloads depend on. The upgrade might move to a new Python version, apply security fixes, or add, remove, or update packages. The environment is built and managed with SAS Configurator for Open Source (sas-pyconfig) and is used by one or more SAS Viya runtimes:

- **SAS Compute**, through `PROC_PYPATH` (for example, PROC PYTHON and Python Code steps)
- **SAS Model Studio**, through `DM_PYPATH`
- **CAS**, through the Python configuration in `extlang.xml`
- **MAS**, through `MAS_PYPATH`

Programs, models, forecasts, and decision flows may all depend on the current environment, so the upgrade must not disrupt production workloads. If something fails, the administrator must be able to return to a known working state quickly.

This guide supports the following non-functional requirements:

- **Reliability:** Production workloads continue to run on a validated environment during and after the upgrade.
- **Recoverability:** The previous environment stays available, so you can roll back by pointing each runtime back to it.
- **Change control:** Each change is validated before promotion and can be traced to a version-controlled environment definition.

**In scope**

- Upgrading Python environments managed by sas-pyconfig in an existing SAS Viya deployment
- Dry run validation of a new environment definition before deployment
- Compatibility testing in SAS Compute, CAS, and MAS
- Cutover and rollback for each runtime
- Any infrastructure provider or industry, since the procedure doesn't depend on a specific cloud platform

**Out of scope**

- Initial installation and configuration of sas-pyconfig
- Python environments not managed by sas-pyconfig, including personal development environments
- Upgrading SAS Viya itself
- Retraining or redeveloping models that fail compatibility testing
