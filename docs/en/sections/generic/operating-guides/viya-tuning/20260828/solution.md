## Solution overview

### Getting Started
For administrators who are new to Viya or Kubernetes, determining where to begin can feel overwhelming. A
practical starting point is to listen to what users are experiencing. User feedback often provides the first
indication that something within the platform has changed.

Questions to consider include:

- Are users seeing application errors?
- Are web applications responding more slowly than before?
- Are jobs taking longer to execute or failing unexpectedly?
- Did the issue begin after a recent change?

Once symptoms have been identified, administrators can begin collecting operational data. The focus should 
initially be on gathering evidence rather than immediately attempting to determine root cause.

Useful sources of information include:

- Kubernetes commands and platform diagnostics
- Monitoring applications used for collecting metrics and logs
- SAS Viya auditing data
- Kubernetes management tools

The objective is to correlate user-reported symptoms with observable platform behavior. This often leads
administrators toward the services or infrastructure components that require additional investigation.

### Initial Areas of Focus
When investigating potential performance issues, there are several areas that administrators should
focus on first.

#### Pod Restarts and Terminations
One of the benefits of Kubernetes is its ability to automatically restart failed containers. While this
improves platform availability, unexpected pod restarts should always be reviewed.

Frequent restarts can negatively affect application performance and may interrupt active user sessions. In
many cases, restart activity is one of the first indicators that a service is experiencing resource
constraints or an application-level issue. Administrators should review restart history and determine whether
the restart occurred after the environment became operational. Any unexpected restart should be investigated.

Example command:

```bash
$ kubectl --namespace viya get pods

NAME                                               READY   STATUS     RESTARTS         AGE 
sas-analytics-events-5f6d9fdfb8-9rgg2              1/1     Running    0                6d1h
sas-analytics-execution-5c6995447b-582pc           1/1     Running    5                6d1h
sas-analytics-gateway-7d4b599747-v7bfs             1/1     Running    0                6d1h
sas-analytics-resources-7b447489b7-zfxp9           1/1     Running    4 (6d1h ago)     6d1h
sas-annotations-6548497886-8w62j                   1/1     Running    0                6d1h
sas-app-registry-5b6578b8bf-mcjbb                  1/1     Running    0                6d1h
sas-arke-7876656d98-kvssl                          1/1     Running    0                6d1h
sas-audit-f4dbdbbb9-6qb4d                          1/1     Running    5 (18m ago)      6d1h
sas-authorization-598575986c-cmlf7                 1/1     Running    1 (11h ago)      6d1h
sas-batch-75745d84f6-6j8qk                         1/1     Running    0                6d1h
sas-cas-control-5d6dbb955f-xxrj6                   1/1     Running    3 (6d1h ago)     6d1h
sas-cas-operator-78bf8cf557-dq7vm                  1/1     Running    0                6d1h
sas-cas-server-default-controller                  3/3     Running    0                6d1h
sas-catalog-services-5f59464c8c-wcttd              1/1     Running    3 (2d21h ago)    6d1h
sas-collaboration-77dd496b69-zw7mw                 1/1     Running    0                6d1h
sas-compute-6f55fbf56-dbspw                        1/1     Running    9 (10h ago)      6d1h
```

Focus on the **RESTARTS** column. Values greater than zero should be reviewed if the restart occurred after
the system was initially started.

When further investigation is required, use the following command:

```bash
$ kubectl --namespace viya describe pod sas-compute-6f55fbf56-dbspw

Name:             sas-compute-6f55fbf56-dbspw
Namespace:        viya
Start Time:       Fri, 30 Jan 2026 21:47:19 -0500
Labels:           app=sas-compute
Status:           Running
Containers:
  sas-compute:
    Image:          cr.sas.com/viya-4-x64_oci_linux_2-docker/sas-compute:1.92.9-20260120.1768940469351
    State:          Running
      Started:      Thu, 05 Feb 2026 13:06:42 -0500
    Last State:     Terminated
      Reason:       OOMKilled
      Exit Code:    1
      Started:      Thu, 05 Feb 2026 05:04:27 -0500
      Finished:     Thu, 05 Feb 2026 13:06:41 -0500
    Ready:          True
    Restart Count:  9
    Limits:
      cpu:     2
      memory:  2Gi
```

The example above shows a pod whose previous state was **OOMKilled**, indicating that the
container exceeded its configured memory limit and Kubernetes restarted the container. Pod terminations like
this negatively impact not just overall system performance, but can potentially cause runtime failures for
active user sessions or jobs.

Additional information on avoiding OOMKill events in the SAS Programming Runtime or Compute engine can be found [here](/guides/operating-guides/avoiding-cgroup-ooms/20260713/index.md).

#### Pod CPU and Memory Utilization
Resource utilization provides another important view of system health. Sustained increases in CPU or memory
utilization may indicate that services are approaching their operational limits.

High resource utilization does not automatically indicate a problem. However, when utilization consistently
approaches configured limits, the risk of application slowdowns, instability, or container restarts increases.
Understanding these trends helps administrators identify which services are under the greatest workload
pressure.

The `kubectl top pods` command provides a quick view of current CPU and memory consumption across all pods:

```bash
$ kubectl --namespace viya top pods

NAME                                               CPU(cores)   MEMORY(bytes)
sas-analytics-events-5f6d9fdfb8-9rgg2              12m          312Mi
sas-analytics-execution-5c6995447b-582pc           245m         1843Mi
sas-analytics-gateway-7d4b599747-v7bfs             8m           289Mi
sas-audit-f4dbdbbb9-6qb4d                          198m         1901Mi
sas-authorization-598575986c-cmlf7                 34m          756Mi
sas-compute-6f55fbf56-dbspw                        1823m        1976Mi
```

The example below illustrates CPU and memory consumption relative to resource
limits. As utilization approaches configured limits, Kubernetes may eventually terminate and restart
containers to relieve resource pressure.

![Viya Monitoring](/sections/generic/operating-guides/viya-tuning/20260828/img/viya_monitoring.png)

### Next Steps
Now that you understand what to look for, the following steps should be taken to address any
identified issues.

#### Prerequisites
Before making any other changes, apply the settings from the [SAS Viya Tuning repository](/tools/tuning/0-intro/index.md).
This repository contains recommended resource configurations that serve as the baseline for a well-tuned Viya
deployment. These settings should always be applied first, as subsequent adjustments build on this foundation.

#### Apply High Availability Settings
Configure each stateless service with a minimum of 2 replicas. High availability is recommended not only
because it improves platform resilience in the event a service crashes, but also because it enhances
performance - incoming requests are load balanced across multiple instances of each service, reducing
contention and improving response times. For more information on configuring high availability, refer to the [SAS Administration Guide](https://go.documentation.sas.com/doc/en/sasadmincdc/default/dplyml0phy0dkr/n08u2yg8tdkb4jn18u8zsi6yfv3d.htm#n14iqy05lb736yn1e01m2hmzu1xr).

#### If Issues Persist
If problems remain after applying the tuning baseline and HA settings, review the [SAS Administration Tuning Guide](https://go.documentation.sas.com/doc/en/sasadmincdc/default/caltuning/titlepage.htm) to ensure other  areas are covered. Further increases to pod memory or CPU limits may also be considered, but should be done carefully to avoid causing any unexpected issues. Focus increases on services that are showing sustained high utilization, frequent restarts, or OOMKilled termination events.

### Summary
Understanding platform behavior is an essential responsibility for every SAS Viya administrator. By monitoring
pod health, investigating restart activity, and reviewing resource utilization, administrators can more
effectively identify potential issues and understand how their environment is evolving over time.

Successful platform operations depend on continuous observation, measurement, and analysis rather than
reacting only when problems occur. When issues are identified, a structured remediation approach — starting
with the SAS Viya Tuning repository baseline, applying high availability settings, and continued monitoring of
resource utilization — provides a clear and repeatable path to resolution.
