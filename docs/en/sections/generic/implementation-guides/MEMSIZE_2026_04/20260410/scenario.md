## Scenario

This guide covers two scenarios for configuring the SAS Viya Compute Server environment to support user‑selectable execution contexts under the revised implementation of the MEMSIZE system option introduced in the 2026.04 release:

- Migration from a pre‑2026.04 environment
- Design guidance for creating tiered, user‑selectable contexts in a new deployment

The migration section outlines the configuration changes a SAS administrator may need to make using SAS Environment Manager to align existing compute contexts with the new MEMSIZE implementation.

The new‑deployment guidance is intended to support initial environment design and configuration based on inputs to the 2026.04 sizing process, enabling SAS administrators to define tiered compute contexts that align user workloads with appropriate resource profiles.

For migration scenarios, the guidance ensures that existing workloads can execute successfully in the SAS Viya Compute Server without encountering out‑of‑memory errors under the revised MEMSIZE behavior.

For both migration and new deployments, the guidance assists SAS administrators in designing a compute environment that supports reliable workload execution while minimizing overall resource consumption and maintaining predictable system behavior.

The compute environment enforces resource efficiency and governance by enabling tiered, user‑selectable contexts that align memory allocation with workload requirements, reducing over‑provisioning and unnecessary resource utilization. User access to these contexts can be controlled by SAS administrators through explicit permission assignments.