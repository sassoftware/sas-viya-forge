# About

SAS maintains a repository of tools and scripts designed to run automated tests against various SAS Viya 4 applications to verify functionality and performance. These tests are fully self-contained and can be executed on any cloud platform and across any SAS Viya cadence. They can be run as single-user tests or scaled to simulate load with multiple concurrent users. The only requirement is access to a valid SAS Viya 4 web application.

This framework is powered by Locust, an open source performance load testing tool. It supports multiple test types, including UI-driven tests using Playwright for Python, command-line tests using the SAS Viya CLI, or other custom Python-based scenarios. Locust serves as the load generation engine and requires a Python test file as input. The repository provides a collection of pre-written and validated test scenarios for different Viya cadences, which can be executed directly against your environment.

This is an open-source project built entirely with open-source tools. We aim for it to be a community-driven, crowdsourced effort that grows through user contributions.

## When to use

The SAS Validation Scenarios are valuable for any Viya environment. They can be used and extended to verify critical functionality developed within your Viya environment, ensuring this functionality is always available. For larger environments, load testing can uncover infrastructure, deployment, configuration or content issues before they impact the end-user experience.

## Link

The SAS Validation Scenarios are expected to be published shortly. Please check back soon.

