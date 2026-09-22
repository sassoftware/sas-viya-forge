## Scenario


SAS Viya compute environments often perform I/O-intensive operations against NFS-backed storage. Common patterns include large sequential table scans, metadata-heavy library access, concurrent analytic jobs, shared SAS libraries, and write-intensive output.

For file access, administrators should balance throughput, IOPS, latency, availability, recovery behavior, operational manageability, and cost. Because SAS Viya may run many compute servers concurrently, the storage architecture must scale to support pod and user growth. A design that works for a single job may fail when the file service, node network bandwidth, Linux NFS client, or CSI integration becomes the limiting factor.

Data persistence also matters. Persisted SAS datasets should align with availability, RTO, and RPO objectives. Temporary job files, including SASWORK-like activity, may be optimized for performance.
