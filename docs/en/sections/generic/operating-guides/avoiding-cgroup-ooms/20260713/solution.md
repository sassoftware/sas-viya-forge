## Solution overview
Avoiding cgroup OOMs in SAS Viya requires sizing the sas-programming-environment container for total cgroup memory usage, not just SAS MEMSIZE. Administrators should explicitly set MEMSIZE, add headroom for runtime overhead and buffered I/O page-cache growth, standardize those choices into workload tiers, and use monitoring data to tune the resulting limits over time. Direct I/O can be considered for workloads where page-cache growth is a primary source of memory instability.

### Solution
The sections below translate this sizing strategy into practical implementation patterns. They describe a dirty-page-aware method for environments where Linux write-back behavior can be estimated, a formula-based heuristic for simpler tier planning, and a tiered context model for applying those choices consistently across compute, batch, and Connect workloads.

### Dirty-Page-Aware Sizing
This method protects SAS compute pods by explicitly accounting for Linux write-back behavior in the page cache.

Configure the sas-programming-environment container memory limit to MEMSIZE plus sufficient headroom for dirty-page accumulation and runtime overhead. Use MEMSIZE + vm.dirty_bytes when vm.dirty_bytes is configured; otherwise, use MEMSIZE plus the effective write-back allowance implied by vm.dirty_ratio and total host memory. The values of vm.dirty_bytes and vm.dirty_ratio are determined by the node operating system configuration and should be considered when calculating the required container memory limit. If different values are required, they must be changed through node-level operating system configuration by the Kubernetes cluster administrator, platform administrator, or cloud infrastructure team responsible for managing the worker nodes.

Treat this as a sizing estimate rather than a guarantee. If dirty pages in the file cache are the dominant non-SAS-controlled memory consumer, dirty-page settings provide a practical upper-bound estimate for the additional cgroup memory that buffered I/O can contribute. However, write-back behavior is enforced at the kernel and node level, while the compute pod is constrained by its container limit.

This approach preserves headroom for buffered I/O and reduces the likelihood of cgroup OOMs in memory-intensive steps such as PROC SORT, which can drive rapid anonymous-memory allocation while dirty pages are accumulating.

For this method, the relevant compute, batch, and Connect execution contexts, where applicable, should explicitly set MEMSIZE so SAS-managed memory remains bounded in a manner similar to SAS V9, while the launcher container limit is sized to provide additional headroom for dirty pages, runtime overhead, and other cgroup-charged memory.

### Formula-Based Sizing Heuristic

When dirty-page settings are unavailable, unsuitable, or too variable to use directly, a simpler formula-based heuristic can be used instead.

This kernel-agnostic method uses MEMSIZE as the SAS-managed memory target, then adds explicit allowance for fixed runtime overhead and an operational safety margin.

Conceptually, size the launcher container memory limit as:

```text
limit = ( MEMSIZE + fixed overhead ) / ( 1 – safety margin )
```

Example: MEMSIZE = 4.8 GiB, fixed overhead = 0.2 GiB, safety margin = 20% → limit = 6.25 GiB

Example planning inputs are fixed overhead of 0.1–0.2 GiB and a safety margin of 20–30%; adjust these values upward when buffered I/O, shared libraries, additional runtimes, or workload variability materially increase the container footprint.

Starting with 2026.04, SAS Viya uses a related but simpler default relationship tied to the sas-programming-environment container memory limit. MEMSIZE is limited to 80% of that container limit. In formula terms, this corresponds to fixed overhead = 0 and safety margin = 20%, with MEMSIZE derived from the container limit rather than the container limit being derived from MEMSIZE.

This 2026.04 default reserves container headroom, but it does not include a fixed runtime-overhead allowance or workload-specific dirty-page growth. For predictable tier sizing, explicitly set MEMSIZE and size the launcher container memory limit to include the selected MEMSIZE plus workload-appropriate overhead and safety margin. The next section, Tiered Context Design, describes how to apply this approach consistently across compute, batch, and Connect tiers, where applicable.

Direct I/O can reduce the need for a double-digit safety margin by minimizing page-cache growth, but it is not appropriate for every workload or storage topology. See the section Direct I/O (DIO) Tradeoffs and Performance Impact below.

### Tiered Context Design

The [launcher context](https://go.documentation.sas.com/doc/en/sasadmincdc/default/calsrvpgm/n01004viyaprgmsrvs00000admin.htm) defines the sas-programming-environment container CPU and memory requests and limits, while compute, batch, Connect, and related execution contexts, where applicable, define startup options such as MEMSIZE, SORTSIZE, SUMSIZE, WORK, and other runtime settings used when the container starts.

To keep these layers consistent, administrators should define a small set of standardized tiers, such as S, M, L, and XL, across both launcher and execution contexts. Each tier should use one of the sizing methods above to establish coherent container limits and SAS runtime options. When deterministic behavior is desired, each tier should explicitly set MEMSIZE rather than relying on the default derived from the container limit. Users should be directed to the smallest tier that meets the expected workload profile. SAS Viya context permissions can then be used to control which users or groups are allowed to submit code or jobs through higher-capacity compute, batch, or Connect contexts, where applicable.

### Observability and Iterative Tuning

Use SAS Viya monitoring tooling and cloud-platform telemetry, such as [Azure Monitor](https://learn.microsoft.com/en-us/azure/azure-monitor/), to observe peak resident set size (RSS), working set, page-cache growth, dirty-page accumulation, and cgroup OOM events. Then tune fixed-overhead and safety-margin assumptions based on measured workload behavior rather than static estimates. Repeated OOMKilled events, sustained page-cache growth, or peak cgroup usage close to the limit should trigger review of launcher limits, MEMSIZE, workload placement, or Direct I/O suitability.

### Direct I/O (DIO) Tradeoffs and Performance Impact

Direct I/O (DIO) bypasses the Linux page cache and issues unbuffered reads and writes directly to storage. This eliminates dirty-page accumulation for DIO-enabled file access and can make container memory usage more stable and predictable.

Direct I/O reduces page-cache exposure, but it does not reduce anonymous memory, runtime overhead, allocator behavior, or other memory charged to the cgroup.

DIO can improve performance on fast local NVMe or SSD storage by avoiding page-cache flush storms, reducing cache-management overhead, and producing more predictable write latency.

However, DIO can reduce performance on slower or network-attached storage because every read and write is serviced directly by the device, eliminating the buffering and read-ahead benefits of the page cache.

DIO is most appropriate when container memory stability is a primary requirement or when WORK or UTILLOC reside on high-performance storage. Buffered I/O is often preferable when workloads benefit from page-cache acceleration or when the underlying storage latency is high.

## Conclusion

Avoiding cgroup OOMs in SAS Viya requires treating MEMSIZE and the launcher container memory limit as related but distinct controls. MEMSIZE bounds SAS-managed memory, while Kubernetes enforces total cgroup usage, including runtime overhead, page cache, dirty pages, and other memory charged to the container.

Administrators should set MEMSIZE intentionally, size launcher limits for the full container footprint, account for dirty-page behavior or use a conservative formula-based heuristic, and apply standardized tiers with monitoring feedback. SAS Viya 2026.04 improves default alignment between MEMSIZE and container limits, but effective sizing still depends on workload-specific overhead, I/O behavior, and iterative tuning.
