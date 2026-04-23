## Solution overview

### Assumptions

The solution described in this section is based on the following assumptions:

- The SAS Viya environment is running release 2026.04 or later, where the revised MEMSIZE behavior is in effect.
- SAS administrators manage compute contexts and user permissions using SAS Environment Manager.
- The underlying Kubernetes cluster is properly configured and has sufficient node capacity to support the CPU and memory requirements of Compute Server workloads.
- SAS administrators may modify Viya Compute Server–related pod templates (Compute, Batch, and Connect), as required, to support the revised MEMSIZE implementation.
- User access to compute contexts is governed through explicit permission assignments.
- Workloads can be reasonably categorized into tiers with similar resource requirements.
- Inputs from the 2026.04 sizing process accurately represent expected workload characteristics.
- The environment prioritizes predictable and reliable workload execution while minimizing unnecessary resource consumption and over‑provisioning.

### Solution

#### Rationale for the 20% Memory Margin
Under the revised MEMSIZE implementation, each user selectable execution context (Compute, Batch, or Connect) must define a MEMSIZE value that fits safely within the container level memory limit enforced by the SAS Launcher context. To ensure stable and predictable behavior, the launcher container memory limit should be set to at least 125% of the maximum MEMSIZE value defined across all child execution contexts.
This relationship preserves an effective 20 percent margin between MEMSIZE and the container memory limit:

- Container memory limit = 1.25 × MEMSIZE
- MEMSIZE = 80% of the container memory limit

This margin accounts for:

- Additional memory required by the SAS runtime and supporting processes
- Memory consumed by internal allocations not governed directly by MEMSIZE
- Transient allocations during program execution, startup, and I/O processing

If this margin is not preserved and the container memory limit is set too close to (or below) the MEMSIZE value, SAS will automatically reduce MEMSIZE at runtime to remain within the enforced container limit. This behavior can result in unexpected changes in workload execution characteristics.

#### Practical Example
Assume the highest MEMSIZE value defined across all user accessible execution contexts is:

- MEMSIZE = 64 GB

To preserve the required margin, the SAS Launcher context must define a container memory limit of at least:

- 64 GB × 1.25 = 80 GB

In this configuration:

- MEMSIZE consumes no more than 80% of the container limit
- The remaining 20% provides headroom for non MEMSIZE memory consumption
- MEMSIZE is not reduced at runtime

Execution contexts with lower MEMSIZE values inherit the same protection.

#### Migration Overview
During migration from pre‑2026.04 environments, existing configurations often define container‑level memory limits in SAS Launcher contexts independently from MEMSIZE values defined in user‑accessible Compute, Batch, or Connect execution contexts. Under the revised MEMSIZE implementation, these values must be aligned to preserve the required 20 percent memory margin and avoid runtime MEMSIZE reduction.

Each SAS Launcher context (Compute, Batch, or Connect) must be evaluated individually, recognizing that each launcher context may have multiple associated child execution contexts. For each launcher context, SAS administrators must examine the MEMSIZE values defined in its child contexts and ensure that the launcher container memory limit is set to at least 125 percent of the largest MEMSIZE value among its children. This per‑launcher sizing is required to ensure stable and predictable workload execution.

Because the memory values that can be configured in launcher contexts are constrained by the global sas.launcher.max setting, migration may also require adjusting this limit. The sas.launcher.max memory value must be set to accommodate the largest container memory limit required by any launcher context across Compute, Batch, and Connect workloads. If sas.launcher.max is set lower than required, it will prevent proper alignment of launcher memory limits and can indirectly force MEMSIZE reductions.
SAS administrators should therefore validate launcher context memory limits, child context MEMSIZE values, and the sas.launcher.max configuration together as part of migration to ensure the 20 percent margin is consistently preserved.

#### Best Practice for SUMSIZE
As a best practice during migration, SUMSIZE should be explicitly defined in execution contexts rather than relying on the default value of 0, which causes SUMSIZE to implicitly scale in proportion to MEMSIZE. Explicitly setting SUMSIZE ensures predictable and stable memory behavior when MEMSIZE values are adjusted as part of migration or future tuning activities.

See the Migration checklist at the end of this document

#### New Deployment Design and Implementation
For new SAS Viya deployments running release 2026.04 or later, the SAS hardware (sizing) estimate accounts for differences in workload characterization that drive CPU and memory requirements across interactive (SAS Studio), background (batch), and SAS/CONNECT sessions, providing SAS administrators with a foundation for Compute Server design.
#### Tiered Launcher Context Design
Based on sizing inputs, SAS administrators should define multiple, tiered SAS Launcher contexts of type Compute, Batch, and Connect, each representing a different workload class. Each launcher context establishes container‑level CPU and memory requests and limits that bound the resources available to its associated execution contexts.

Typical tiers might include:

- A lower‑capacity tier for lightweight or short‑running workloads
- A medium‑capacity tier for common analytical workloads
- A higher‑capacity tier for memory‑intensive or long‑running workloads

Each launcher context may have multiple associated user‑accessible execution contexts, which define workload‑specific values such as MEMSIZE and SUMSIZE. For each launcher context, the container memory limit must be sized to accommodate the largest MEMSIZE value defined across its child execution contexts, preserving the required 20 percent memory margin (that is, the launcher container memory limit is set to at least 125 percent of the maximum MEMSIZE value among its children).

CPU requests and limits should be defined similarly, using sizing guidance to ensure that resource guarantees align with expected workload demand while preventing over‑commitment.

#### MEMSIZE and SUMSIZE Configuration
Within each tier, execution contexts should define explicit MEMSIZE values appropriate to the workload profile. To ensure predictable behavior, SUMSIZE should also be explicitly defined in each execution context rather than relying on the default value of 0, which implicitly scales SUMSIZE based on MEMSIZE.

Defining MEMSIZE and SUMSIZE explicitly within execution contexts allows resource consumption to be matched more precisely to workload requirements, while launcher contexts enforce upper bounds through container‑level limits.
#### sas.launcher.max Considerations
The sas.launcher.max configuration defines the upper bounds for CPU and memory values that can be specified in SAS Launcher contexts. In a new deployment, this value must be set to support the largest launcher container memory and CPU limits required by any defined tier across all user‑accessible contexts (Compute, Batch, and Connect).

When designing tiers, SAS administrators should:

- Identify the launcher context with the largest container memory and CPU limits
- Ensure that sas.launcher.max is set to at least those values
- Validate that future tier expansion or workload growth can be accommodated without requiring frequent reconfiguration

Because sas.launcher.max applies globally, it should be sized deliberately to enable required high‑capacity contexts while relying on permissions to prevent inappropriate use.
#### Governance and Access Control
Not all users require access to all workload tiers. SAS administrators should use [identity assignments](https://go.documentation.sas.com/doc/en/sasadmincdc/default/evfun/p1dkdadd9rkbmdn1fpv562l2p5vy.htm#n0bw1won3jn0axn1brl67tielej1) to govern access to execution contexts, ensuring that users can select only the tiers appropriate for their workloads. Higher‑capacity contexts should be restricted to workloads that have a demonstrated need for increased CPU or memory resources.

This governance model allows new deployments to:

- Support diverse workload requirements
- Maintain predictable resource utilization
- Minimize over‑provisioning

Preserve platform stability under the revised MEMSIZE implementation

#### Summary
In new deployments, the combination of the 2026.04 sizing process, tiered launcher contexts, explicit MEMSIZE and SUMSIZE configuration, appropriately sized sas.launcher.max values, and permission‑based governance enables a scalable and well‑controlled Compute Server environment. This approach ensures reliable workload execution while balancing flexibility for users with administrative control over resource consumption.
#### Migration Checklist: 

Use this checklist to validate and adjust memory related settings when migrating to the revised MEMSIZE implementation introduced in the 2026.04 release.

Step 1: **Identify SAS Launcher Contexts**

- Identify all defined SAS Launcher contexts of type Compute, Batch, and Connect.
- Treat each launcher context independently, as memory limits are enforced per launcher context.

Step 2: **Enumerate Child Execution Contexts**

- For each launcher context, list all associated user accessible execution contexts.
- Include every child context that references the launcher context, regardless of intended workload tier.

Step 3: **Determine the Maximum MEMSIZE per Launcher Context**

- Examine the MEMSIZE value defined in each child execution context.
- Identify the largest MEMSIZE value among the child contexts of that launcher context.

Step 4: **Validate the Launcher Container Memory Limit**

- For each launcher context, verify that the container level memory limit is set to at least 125 percent of the largest MEMSIZE value identified in Step 3.
- Apply the sizing rule:
- Launcher container memory limit ≥ max(MEMSIZE of child contexts) × 1.25

Step 5: **Adjust Launcher Context Settings if Required**

- If the launcher container memory limit does not meet the 125 percent requirement: 
    -	Increase the memory limit using SAS Environment Manager.
- Ensure all values comply with the limits enforced by sas.launcher.max.

Step 6: **Validate and Adjust sas.launcher.max**

- Review the sas.launcher.max memory limit, which defines the maximum memory values allowed in SAS Launcher contexts.
- Set sas.launcher.max to at least the largest container memory limit required by any launcher context across Compute, Batch, and Connect.
- Confirm that sas.launcher.max does not prevent configuring launcher contexts to preserve the required 20 percent margin.

Step 7: **Validate SUMSIZE Configuration**

- Confirm that SUMSIZE is explicitly defined in each execution context.
- Avoid relying on the default value of 0, which implicitly scales SUMSIZE with MEMSIZE and may introduce unintended changes during migration.

Step 8: **Apply Governance Controls**

- Use permission assignments to restrict user access to higher capacity execution contexts.
- Ensure that only workloads requiring larger resource profiles can select contexts with higher MEMSIZE values.

Step 9: **Re validate After Changes**

- Re-review each launcher context to ensure: 
    -	The 125 percent memory margin is preserved
    -	No child execution context defines a MEMSIZE value exceeding safe limits
- Validate that MEMSIZE is not reduced at runtime during representative workload execution.
