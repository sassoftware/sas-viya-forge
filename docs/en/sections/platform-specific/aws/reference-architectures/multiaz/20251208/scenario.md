![Architecture Overview](../../../sections/platform-specific/aws/reference-architectures/multiaz/20251208/img/AWS_MultiAZ_Reference_202510.png)

## Scenario

The reference architecture for multi Availability Zone deployments in AWS provides the recommended approach to deploy Viya in these environments.

This architecture provides enhanced recovery in case of the following disruptions:

- **Single Pod failures**: by running multiple instances of all services, the system is protected against pod failures.
- **Single Node failures**: by spreading multiple instances over multiple nodes, the system is protected against node failures.
- **Availability Zone failures**: by spreading multiple instances over multiple Availability Zones, the system is protected against Availability Zones failures.

Note that protection against single pod and node failures can also be achieved in single Availability Zone setups.

This reference architecture can be combined with other reference architectures to provide additional resilience in the form of Backup / Restore and Disaster Recovery functionalities.

### End-User experience

When an Availability Zone goes down, users will possibly experience a service disruption if their session was running in the affected Availability Zones. After establishing a new session, users can resume working as normal. They should however be aware that:

- **Compute sessions** will have terminated and any work that was in-progress at the time of the disruption will have to be restarted.
- **CAS data** will have to be reloaded into memory before it can be used again.

### Considerations for cross Availability Zone deployments

Although cross Availability Zone deployments of SAS Viya provide the highest level of availability, this deployment topology does come with a number of caveats:

- **Performance Cost**: Although cross AZ latency is lower than cross region latency, the increase compared to same zone deployments can have a negative impact on the performance of high performance analytical platforms like SAS Viya.
- **Infrastructure Cost**: In order to maintain the same level of performance when compared to single AZ deployments, additional infrastructure needs to be deployed that can handle the application load even when an Availability Zone goes down.
- **Data Transfer Cost**: Data transmitted between Availability Zones will be charged. For analytical applications such as SAS Viya, this cost may be significant.

If the availability requirements of the Viya environments do not necessitate an active-active multi Availability Zone setup. An active-passive setup may be more performant and cost-effective.
The previous version of this reference architecture and the accompanying deployment guide document this scenario.

- [Reference Architecture](../../../reference-architectures/multiaz-aws/20250908/index.md)
- [Deployment Guide](../../../guides/deployment-guides/multiaz-aws/20251208/index.md)

