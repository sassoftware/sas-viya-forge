## Introduction

SAS maintains a repository of tools and scripts designed to run automated tests against various SAS Viya applications to verify functionality and performance. These tests are fully self-contained and can be executed on any supported platform and are available for SAS Viya release 2026.01 and later. They can be run as single-user tests or scaled to simulate load with multiple concurrent users. The only requirement is access to a valid SAS Viya environment.

This framework is powered by Locust, an open source performance load testing tool. It supports multiple test types, including UI-driven tests using Playwright for Python, command-line tests using the SAS Viya CLI, or other custom Python-based scenarios. Locust serves as the load generation engine and requires a Python test file as input. The repository provides a collection of pre-written and validated test scenarios for different Viya cadences, which can be executed directly against your environment.

And if you want to create your own unique tests that fits your own needs, then you can follow the template and guidance provided to create your own.

This is an open-source project built entirely with open-source tools. We aim for it to be a community-driven, crowdsourced effort that grows through user contributions.

### Why sas-validation-scenarios

Automated Tests are critical because every environment is different, and tests provide objective proof that the application works in that specific environment. They catch integration issues early, and establish a verified baseline before going live. During updates, they identify regressions and enable faster, lower-risk deployment updates. They also support customer self-sufficiency over time and satisfy audit and compliance requirements with documented, repeatable validation records.

The SAS Validation Scenarios provides just that and are valuable for any Viya environment. They can be used and extended to verify critical functionality developed within your Viya environment, ensuring this functionality is always available.  

For larger environments, load testing can uncover infrastructure, deployment, configuration or content issues before they impact the end-user experience. Load testing is essential because every environment is unique — different hardware, infrastructure, and usage patterns mean that performance validated in a lab may not hold in the real world. It identifies breaking points, hidden bottlenecks like memory leaks or database contention, and whether a new application impacts existing systems sharing the same infrastructure. It validates performance with objective evidence, provides data for future capacity planning, and most importantly prevents the damaging first impression of a system that works for one user but struggles when the entire team goes live. In short, it proves the application works at scale in that specific environment, not just in theory.

### Versions: Stable and LTS cadence
As new versions of SAS Viya are released, architectural updates, web UI changes, and feature additions or deprecations may occur. Such changes can affect the behavior and compatibility of validation scenarios.
When a new cadence becomes available, the sas-validation-scenarios framework is validated against that release.
To manage these differences, each branch of this repository is aligned to the Viya cadence it supports.
Updates or adjustments are implemented and maintained within the associated branch to ensure compatibility and consistent test coverage across Viya versions.

Whenever you are using the sas-validation-scenarios project, you must ensure you are using the branch with the label that corresponds to your specific Viya version. When you update your Viya deployment to a new version, clone the latest version of the sas-validation-scenarios project from Github and checkout the appropriate branch. If you update your SAS environment to a version for which a branch does not yet exist in the sas-validation-scenarios project, you may continue to use the latest version. Be mindful however that there may have been changes in the Viya platform that cause test cases to fail.

See [VERSIONS.md](https://github.com/sassoftware/sas-validation-scenarios/blob/main/VERSIONS.md) for a list of currently supported versions.