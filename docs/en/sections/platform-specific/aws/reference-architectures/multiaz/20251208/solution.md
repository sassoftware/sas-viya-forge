## Solution overview

### Assumption

Networking infrastructure has been set up so that end users can reach the SAS Viya platform and the platform can reach its datasources, in all configured Availability Zones.

### Components

The following key components make up the reference architecture:

1. **EKS Node Pools**
  EKS Node Pools are deployed across at least three [Availability Zones](https://docs.aws.amazon.com/eks/latest/best-practices/data-plane.html#_recommendations) to ensure clustered services will always be able to achieve a quorum in case an Availability Zones goes down. All node pools are labeled and tainted according to the [SAS documentation](https://go.documentation.sas.com/doc/en/sasadmincdc/default/dplyml0phy0dkr/p0om33z572ycnan1c1ecfwqntf24.htm#n0wj0cyrn1pinen1wcadb0rx6vbm). If following the recommended workload placement strategy this means at least 5 node pools will be created:
    - Default node pool
    - Stateless node pool
    - Stateful node pool
    - Compute node pool
    - CAS node pool

    !!! note

        SAS recommends deploying the node pools as [Managed Node Groups](https://docs.aws.amazon.com/eks/latest/userguide/managed-node-groups.html) and to deploy the Kubernetes Cluster Autoscaler. This allows EKS to respond to failed Availability Zones by spinning up additional instances in other zones.

2. **RDS Postgres**
  A [multi-AZ RDS Postgres database](https://aws.amazon.com/rds/features/multi-az/) is deployed. This can either be a RDS instance with a standby in a secondary AZ, or an RDS cluster with two readable standby's in a secondary and tertiary AZ. The diagram above shows the first option. In case of an Availability Zone failure, the RDS database will automatically switch over to a secondary Availability Zone allowing the SAS Viya platform to resume connections with minimal delay.

3. **FSx ONTAP**
  Amazon FSx for NetApp ONTAP is deployed with the [Multi-AZ deployment type](https://docs.aws.amazon.com/fsx/latest/ONTAPGuide/high-availability-AZ.html). SAS Viya requires both RWO block storage and RWX shared storage. Amazon FSx for NetApp ONTAP provides both storage requirements with a deployment type that makes this storage available across Availability Zones. This again ensures the SAS Viya platform can still access its storage layer in case of an Availability Zone failure.

4. **Elastic Container Registry**
  Although not strictly required, removing the dependency on upstream container image repositories decreases the time in which you are able to create new container instances in a different Availability Zone. Using an [Elastic Container Registry](https://aws.amazon.com/ecr/) removes this dependency. The ECR should not only [mirror the SAS container registry](https://go.documentation.sas.com/doc/en/sasadmincdc/default/dplyml0phy0dkr/n1h0rgtr10fpnfn1mg0s8fgfuof8.htm), but also any other images required to run the supporting services in the EKS cluster such as the Ingress controller and CSI providers.