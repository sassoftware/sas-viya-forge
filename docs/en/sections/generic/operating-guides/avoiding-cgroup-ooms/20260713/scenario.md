## Scenario

### From SAS V9 Memory Semantics to Kubernetes cgroup Enforcement

When an workload moves from SAS 9 to SAS Viya on Kubernetes, the way a compute process allocates and releases memory dynamically during step execution remains the same, but the enforcement boundary changes fundamentally.

In a traditional SAS V9 deployment, transient growth can often be absorbed at the host level through virtual memory and swap. This smooths short-duration demand spikes and permits a degree of memory overcommit for SAS V9 compute sessions with intermittent activity, such as interactive sessions.

In SAS Viya, the corresponding compute process runs inside a Kubernetes-managed container with a configured hard cgroup memory limit and no meaningful swap safety net. Memory accounting also includes page-cache consumption, including dirty pages created by buffered I/O. As a result, memory pressure that might be tolerated on a conventional host can terminate a compute pod once total cgroup usage exceeds the container limit. 

### Why cgroup OOMs Occur

A container enters an OOMKilled state when total memory charged to its cgroup exceeds the configured limit. A compute pod can be terminated even when the node on which the pod runs still has available memory. In SAS Viya, [MEMSIZE](https://go.documentation.sas.com/doc/en/pgmsascdc/default/lesysoptsref/n09y5anvvpzrmnn0ztkyf59qgzvr.htm) constrains only part of the compute footprint; runtime overhead, shared libraries, thread stacks, allocator fragmentation, kernel-attributed memory, and page-cache consumption can all contribute to actual usage. 

By default, both SAS V9 and the SAS Viya Compute Server use buffered I/O through the Linux page cache. This can improve throughput through read-ahead and write-behind behavior. Data written through the page cache is temporarily stored in memory as dirty pages until it is written to storage by the kernel. During write-intensive workloads, dirty pages can accumulate and increase memory charged to the container. If the sas-programming-environment container limit is not sized appropriately relative to MEMSIZE, SORTSIZE, SUMSIZE, runtime overhead, and anticipated page-cache growth, buffered I/O can significantly increase cgroup OOM risk.

### 2026.04 MEMSIZE Behavior Change and Migration Considerations

During migration from SAS V9 to SAS Viya 4, MEMSIZE is often carried forward from existing configuration practices or set according to workload expectations developed on traditional hosts. Using MEMSIZE values for container memory limits may not be sufficient for the Kubernetes memory enforcement model described above.

With SAS Viya 2026.04, Compute Server MEMSIZE behavior aligns more closely with Kubernetes memory enforcement. Instead of MEMSIZE driving the sas-programming-environment container memory limit, the container controls the default MEMSIZE behavior. If MEMSIZE is not specified, it defaults to 80% of the sas-programming-environment container memory limit. If MEMSIZE is specified and exceeds 80% of the container memory limit, it is reduced to 80% of that limit. See [SAS Viya 2026.04 MEMSIZE implementation guide](/guides/implementation-guides/MEMSIZE_2026_04/20260410/index.md) for additional details.

This 80% behavior provides default headroom within the container, but that reserved headroom may still be insufficient for runtime overhead, page-cache growth, dirty pages, and workload variability. Administrators should continue sizing launcher limits and execution-context memory options together rather than assuming the default MEMSIZE adjustment alone will prevent cgroup OOMs.
