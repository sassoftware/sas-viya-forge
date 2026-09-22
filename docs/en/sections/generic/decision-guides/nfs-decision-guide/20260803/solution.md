## Decision Overview

Selecting NFS-backed storage for SAS Viya compute on Kubernetes requires balancing performance, scalability, durability, operational simplicity, security, and cost. The decision should be evaluated across six areas:

1. Storage Service Selection
2. Provisioning Model and Cost Control
3. Durability and Availability
4. VM Node Sizing and Placement
5. Linux NFS Client and CSI Design
6. Security and Network Path

No single storage architecture is universally optimal. The appropriate choice depends on workload characteristics, recovery requirements, concurrency requirements, and operational objectives.

### Assumptions

This guide assumes:

- SAS Viya workloads are deployed on Kubernetes.
- Shared ReadWriteMany (RWX) file access is required.
- Data is accessed through NFS-backed Persistent Volumes.
- Workloads include one or more of the following:
  - Large sequential scans
  - Metadata-intensive access patterns
  - Concurrent analytics
  - Shared SAS libraries
  - Write-intensive output
- Kubernetes worker nodes and storage services can be colocated within the same region and, where possible, the same availability zone.
- Administrators can perform workload validation using representative SAS Viya performance tests.

### Solution Comparison

#### Storage Service Selection
First, determine whether the workload needs high-performance managed NFS or can use a general-purpose managed NFS service. High-performance NFS fits latency-sensitive, high-concurrency SAS Viya environments. It is especially useful when large sequential scans are combined with metadata-heavy activity or many concurrent analytic jobs. General-purpose NFS may fit moderate performance requirements, simpler operations, cost-constrained deployments, or workloads with more predictable sequential access.

This grouping is for architecture discussions, not strict feature-parity comparisons across cloud providers. Administrators should evaluate each service tier based on the throughput, IOPS, and write limits it can provide. They should also consider latency behavior, CSI driver support, topology options, and vendor guidance for the target environment.

| **Option** | **When it fits** | **Administrator considerations** |
|----|----|----|
| High-performance managed NFS | Latency-sensitive, high-concurrency, metadata-heavy workloads with mixed read/write activity. | Validate service tier, same-zone placement, CSI driver behavior, Linux mount options, and cost at expected concurrency. |
| General-purpose managed NFS | Moderate RWX requirements, simpler operations, broad availability, or workloads where peak performance is not the primary driver. | Confirm whether performance depends on capacity, configured throughput, IOPS, redundancy choice, or service tier. |

!!! note
    Local ephemeral or block-backed storage may be appropriate for temporary scratch paths, but it is outside the scope of this NFS service selection table.

#### Provisioning Model and Cost Control
Treat provisioning as both a performance control and a capacity decision. Some managed file services tie performance to capacity, so increasing capacity also increases available throughput or IOPS. Others allow throughput and IOPS to be configured more independently. Both models can work, but they create different operating patterns and cost tradeoffs.

Capacity-tied models may require deliberate overprovisioning to reach the throughput or IOPS the workload needs. This is simple to operate but inefficient when capacity needs are small and I/O demand is high. Independently provisioned models let administrators size capacity for the data footprint and provision throughput or IOPS for workload demand. They provide more control, but underprovisioning becomes explicit: a share can have free space and still throttle SAS Viya compute workloads if provisioned performance is too low.

#### Durability and Availability
Make durability decisions workload by workload. Single-zone or single-site durability usually provides the shortest write path and the most predictable latency. It may fit temporary job state or environments where rerunning the job is the accepted recovery action. Multi-zone or regional durability improves failure-domain resilience. However, the added coordination can increase end-to-end latency for small-write, metadata-heavy, or latency-sensitive patterns.

For persisted SAS datasets, align durability with platform availability, recovery time objectives, and recovery point objectives. For temporary datasets and files created during active execution, storage may preserve the bytes, but the process state is lost if the job or node fails. Administrators should document whether the design supports data recovery, job rerun, or both.

| **Durability choice** | **Prefer when** | **Tradeoff** |
|----|----|----|
| Single-zone or single-site | Job-level recovery is acceptable, and the priority is low latency, a shorter write path, and predictable elapsed time. | Less resilient to zone or site failure; recovery may require rerunning jobs. |
| Multi-zone or regional | Persisted data, availability objectives, or recovery requirements require fault-domain resilience. | May add latency or transient pauses; validate failover and client retry behavior. |

#### VM Node Sizing and Placement
Kubernetes worker nodes must have enough CPU, memory bandwidth, network capacity, and interrupt-handling headroom to drive the expected storage throughput. Small or burstable nodes can become the bottleneck even when the storage service is properly sized. For burstable VM families, size long-running SAS Viya jobs against sustained baseline CPU and network capacity, not short-duration burst credits. Larger compute- or memory-optimized nodes with enhanced networking can sustain higher throughput, IOPS, and queue depth when the storage service and network topology support the same demand.

Placement matters as much as VM node selection. For performance-sensitive SAS Viya compute workloads, keep storage and Kubernetes worker VM nodes in the same region and, where the service model allows, the same zone or fault domain. Use topology-aware scheduling, node affinity, and storage provisioning policies to avoid accidental cross-zone placement after rescheduling or scale-out. Avoid cross-region NFS mounts for performance-sensitive workloads. Each extra network hop can increase latency, especially for metadata-heavy or small-block I/O.

- Validate baseline node network bandwidth, CPU headroom, and any burst-credit behavior under representative concurrent SAS Viya jobs.

- Confirm that the worker size can drive configured storage throughput without saturating client resources.

- Keep storage and workers close in the network topology when workload latency matters.

- Document any required cross-zone placement and test that configuration explicitly.

#### Linux NFS Client and CSI Design

Linux NFS client behavior can materially affect SAS Viya performance. For high-performance managed NFS services, vendor guidance often recommends large `rsize` and `wsize` values. It may also recommend `nconnect` where supported. In Kubernetes, these mount options are typically defined in `StorageClass` or `PersistentVolume` settings and applied through the CSI driver. Administrators should validate the service tier, kernel version, mount options, CSI driver behavior, and Kubernetes distribution together.

Administrators should not assume that `nconnect` is universally supported or beneficial across all NFS implementations. Support, recommended values, interoperability considerations, and observed performance gains can vary by storage platform, Linux distribution, CSI driver, and security configuration. Vendor guidance and workload-specific validation testing should be treated as the authoritative basis for determining whether `nconnect` is appropriate and how it should be configured in a given environment.

Read-ahead behavior is especially important for read-heavy workloads, such as large sequential table scans. Newer Linux distributions may use smaller default NFS read-ahead values than older systems. If read-ahead is too small, sequential throughput can fall short even when the storage service has available bandwidth. Measure per-mount read-ahead behavior and persist changes only when testing shows a SAS Viya performance benefit.

Endpoint-level client state is another operational consideration. Multiple NFS mounts to the same endpoint can share kernel-side client state, so conflicting mount options may not remain isolated per mount. The first mount can establish an effective option set that later mounts inherit. To reduce non-determinism, keep mount options consistent per endpoint, or use separate NFS endpoints for workloads that require materially different client behavior.

| **Tuning area** | **Why it matters** | **Validation action** |
|---|---|---|
| `nconnect` | Can increase concurrency and throughput when supported by the service, kernel, CSI driver, and security mode. It is not universally supported. | Confirm vendor support and interoperability, then test with the selected CSI driver, workload type, Linux distribution, and security settings before production use. |
| `rsize` / `wsize` | Large transfer sizes can improve sequential streaming efficiency. | Start with vendor guidance, then measure achieved throughput. |
| `read_ahead_kb` | Small defaults can reduce large sequential read performance. | Measure per-mount behavior and keep changes only when testing supports them. |
| CSI driver | Controls provisioning, mount consistency, topology awareness, and option delivery. | Use provider- or vendor-specific CSI drivers when they improve reliability or performance. |
| Mount option consistency | Conflicting endpoint options can produce inconsistent behavior. | Keep options consistent per endpoint or separate endpoints by workload profile. |


#### Security and Network Path

Security controls should protect NFS access while avoiding unnecessary latency and unplanned cost. Prefer private networking, storage access controls, firewall rules, and provider backbone routing. For private endpoints or similar private-access features, include any hourly, data-processing, or data-transfer charges in the cost model, as appropriate. Avoid unnecessary proxies, inspection points, and cross-boundary routing for performance-sensitive NFS traffic. If stronger in-transit protection, Kerberos-based NFS modes, or other controls are required, validate their effect in the same performance test plan. Include CPU utilization, latency, throughput, and, where applicable, cost.

Validate security choices together with mount tuning. Parallel connection features can interact with authentication or encryption modes, so test security settings, mount options, CSI behavior, and workload concurrency as a single configuration. Approve only configurations that use the same security path planned for production.
##  Decision Matrix

Use this matrix to compare NFS storage categories during Day 0 planning. Treat the ratings as relative guidance, not benchmark guarantees. Before using the matrix to narrow options, validate the storage service limits, including provisionable throughput, IOPS, and write limits. Then evaluate the workload and client path: workload shape, I/O size, queue depth, Linux NFS tuning, and CSI driver behavior. Finally, confirm the infrastructure assumptions: worker-node baseline bandwidth, CPU headroom, placement, durability model, security path, and cost model.

| **Storage category or configuration** | **Throughput tendency** | **IOPS tendency** | **Latency tendency** | **Guidance for SAS Viya compute** |
|----|----|----|----|----|
| High-performance managed NFS in same zone or fault domain as workers | Highest and most consistent when the service, client, and network path are not the bottleneck. | Strong small-block and metadata performance with good concurrency scaling. | Lowest and most stable relative latency. | Best fit for elapsed-time-sensitive SAS Viya compute and heavy concurrent analytics when cost and placement constraints are acceptable. |
| High-performance managed NFS without strict same-zone placement | Typically high but less consistent because cross-zone distance can affect tail behavior. | Generally strong, with more variation for metadata-heavy or bursty workloads. | Low overall, but usually less stable than strict colocation. | Good when a premium service is required and strict colocation is not possible; validate tail latency and cross-zone behavior. |
| General-purpose premium NFS with capacity-tied performance and single-zone durability | Moderate to high when provisioned large enough; tuning may require buying extra capacity. | Moderate to high; effective IOPS depend on capacity and concurrency. | Low millisecond-class tendency when well-sized, but more sensitive to contention. | Viable when a general-purpose file service is required, but less efficient for demanding workloads if capacity must be overprovisioned for performance. |
| General-purpose premium NFS with capacity-tied performance and multi-zone durability | Moderate to high, but often less efficient for write-sensitive workloads. | Moderate to high, with some coordination cost for small writes. | Slightly higher than the single-zone variant. | Use when zonal resilience is needed and the added latency, coordination, and cost tradeoffs are acceptable. |
| General-purpose NFS with independently provisioned capacity, IOPS, and throughput using single-zone durability | High and more predictable because throughput is provisioned directly. | High and more controllable because IOPS are provisioned independently. | Best general-purpose file-service latency tendency among compared cases. | Preferred general-purpose design when performance matters, broad availability is required, and independent provisioning is available. |
| General-purpose NFS with independently provisioned capacity, IOPS, and throughput using multi-zone durability | High when correctly provisioned, but usually less efficient than single-zone. | High, though small-write and tail-latency behavior can be worse under pressure. | Slightly higher than the single-zone version. | Choose when zone-level resilience is required for persisted datasets or recovery objectives; validate small-write and tail-latency behavior. |

## Recommended Decision Workflow
Work through these decisions in sequence. Start with workload, shared access, and recovery requirements so platform preference or cost does not hide constraints that must be satisfied first.

1.  Classify the workload profile: sequential, metadata-heavy, concurrent, write-intensive, or mixed.

2.  Identify which data paths require NFS-backed RWX semantics, and separate temporary scratch paths that do not require shared file access.

3.  Separate persisted data from temporary job state, and document whether the recovery action is data restore, job rerun, or both.

4.  Define latency, throughput, IOPS, concurrency, availability, recovery, and operational requirements before selecting a storage service.

5.  Select candidate NFS services, service tiers, and durability models that can satisfy those requirements.

6.  Validate service throughput, IOPS, and write limits with compute node size, baseline network bandwidth, CPU headroom, and placement strategy.

7.  Define mount options, read-ahead assumptions, CSI driver choice, and StorageClass or PersistentVolume strategy.

8.  Validate security controls, mount options, CSI behavior, and workload concurrency as a single configuration using the production security path.

9.  Run SAS Viya-representative performance tests and compare results with acceptance criteria. Include throughput, latency, tail latency, elapsed time, client CPU, retransmits, and throttling indicators.

10. After designs meet technical requirements, use cost, availability tradeoffs, and operational simplicity to choose among them.

## Production Readiness Checklist

Use this checklist after completing the decision workflow in Section 5. Each item should be supported by documented design assumptions, configuration choices, or test results before the NFS-backed storage design is approved for production.

<div class="checklist" markdown>

| **Done** | **Validation item** |
|----|----|
| ☐ | Workload profile is categorized and representative test jobs are identified. |
| ☐ | Shared RWX requirements are separated from scratch or temporary path requirements. |
| ☐ | Durability choice is documented separately for persisted data and temporary job state. |
| ☐ | Provisionable throughput, IOPS, write limits, and capacity assumptions are recorded. |
| ☐ | Worker instance type, CPU, memory, and network headroom are validated. |
| ☐ | Storage and worker placement strategy is defined, including zone and region assumptions. |
| ☐ | CSI driver and mount option strategy are documented. |
| ☐ | read_ahead_kb behavior is measured for read-heavy workloads. |
| ☐ | Security settings are tested with the same mount options, CSI behavior, workload concurrency, and production security path planned for production. |
| ☐ | Performance tests capture throughput, average latency, tail latency, elapsed time, client CPU, retransmits, and storage throttling indicators. |
| ☐ | Failover or transient pause behavior is tested where multi-zone or regional durability is selected. |
| ☐ | Cost comparison is performed only among designs that meet technical requirements. |

</div>

## Conclusion

For I/O-intensive SAS Viya compute on Kubernetes, the right NFS storage decision is not simply the fastest or most feature-rich service. The appropriate design is the most cost-effective architecture that meets performance, availability, recovery, and operational requirements with enough headroom for expected concurrency. High-performance managed NFS services are the strongest fit for latency-sensitive, high-concurrency environments. General-purpose managed NFS services are acceptable for moderate workloads or when operational simplicity and cost are stronger drivers. In those cases, validate provisionable throughput, IOPS, write limits, and client-side behavior.

Administrators should avoid treating storage, compute, networking, and security as independent decisions. Test the selected service tier, durability model, worker size, placement strategy, mount options, CSI driver, security path, and cost model as a complete system. Use representative SAS Viya workloads and acceptance criteria. When those layers are validated together, the design can support predictable SAS Viya workload execution while balancing performance headroom, recovery objectives, operational simplicity, and cost.

## Provider Mapping

This appendix maps the vendor-neutral patterns used in this guide to representative managed services. It is not intended to be an exhaustive list of provider services, configurations, or regional capabilities. The mapping is conceptual and does not imply feature parity across providers. Administrators should validate the exact service tier, region, durability option, CSI integration, and performance envelope in the target environment.

| **Vendor-neutral pattern** | **AWS** | **Azure** | **Google Cloud** |
|----|----|----|----|
| High-performance managed NFS service | Amazon FSx for NetApp ONTAP for NFS-centric Kubernetes deployments; Amazon EFS may be used in less specialized cases. | Azure NetApp Files. | Filestore Zonal for single-zone high performance, or Filestore Enterprise for regional resilience. |
| General-purpose managed file service for NFS shared storage | Amazon EFS with General Purpose performance mode and Elastic, Provisioned, or Bursting throughput. | Azure Files NFS shares, especially premium SSD-backed offerings and newer independently provisioned models where available. | Filestore Basic SSD or other Filestore tiers for moderate shared NFS requirements. |
| Single-zone or single-site durability | EFS One Zone, or single-AZ placement choices where applicable. | Locally redundant or zonal options such as LRS-oriented Azure Files designs or zonal Azure NetApp Files deployments where supported. | Filestore Zonal or Basic tiers deployed in a single zone. |
| Multi-zone or regional durability | Regional Amazon EFS or cross-AZ managed file configurations where supported. | Zone-redundant or geo-/regionally replicated Azure Files configurations; Azure NetApp Files cross-zone or zone-redundant offerings where adopted. | Filestore Enterprise or Regional tiers. |
| Managed Kubernetes integration | Amazon EKS with the EFS CSI driver, or Trident / CSI-based integration for FSx for NetApp ONTAP. | Azure Kubernetes Service with the Azure Files CSI driver, or Trident / CSI-based integration for Azure NetApp Files. | Google Kubernetes Engine with the Filestore CSI driver. |
