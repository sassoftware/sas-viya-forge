## Introduction

Python environments in SAS Viya need regular updates to pick up new Python versions, security fixes, and package releases. Because many programs, models, and decision flows can depend on the same environment, an update that isn't planned carefully can break production workloads in SAS Compute, CAS, or MAS.

This guide describes how to upgrade a Python environment managed by the SAS Configurator for Open Source (sas-pyconfig) safely and in a repeatable way. It answers three operational questions:

1. **Dry run:** How can you confirm that a new environment will build and work in SAS Viya before you deploy it?
2. **Compatibility testing:** How can you test existing code and models against the new environment before production workloads depend on it?
3. **Rollback:** How can you return to the previous Python environment if the new one fails?

The approach is to build the new environment as a separate configuration profile next to the current one, validate it, and then switch each runtime to it in a controlled way. The current environment stays available throughout, so rollback means pointing each runtime back to it.

This guide assumes you are familiar with the practices in *Python Environment Best Practices*, especially keeping environments minimal, using trusted package sources, and keeping version-controlled environment definitions.