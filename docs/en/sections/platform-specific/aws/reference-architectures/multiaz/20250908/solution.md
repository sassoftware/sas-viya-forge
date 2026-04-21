## Solution overview

### Assumption

Networking infrastructure has been set up so that end users can reach the SAS Viya platform and the platform can reach its data sources, regardless of in which Availability Zone the application is running.

### Components

The following key components make up the reference architecture:

1. **EKS Node Pools**
  Separate EKS Node Pools are deployed in subnets in at least two Availability Zones. All node pools are labeled and tainted according to the [SAS documentation](https://go.documentation.sas.com/doc/en/sasadmincdc/default/dplyml0phy0dkr/p0om33z572ycnan1c1ecfwqntf24.htm#n0wj0cyrn1pinen1wcadb0rx6vbm). If following the recommended workload placement strategy this means at least 10 node pools will be created:
    - 2 default node pools
    - 2 stateless node pools
    - 2 stateful node pools
    - 2 compute node pools
    - 2 CAS node pools

    Five of these node pools will be scaled down to zero nodes in normal operation. In case of an Availability Zone failure, these node pools can be scaled up to the required number of nodes.

2. **RDS PostgreSQL**
  A [multi-AZ RDS PostgreSQL database](https://aws.amazon.com/rds/features/multi-az/) is deployed. This can either be a RDS instance with a standby in a secondary AZ, or an RDS cluster with two readable standby's in a secondary and tertiary AZ. In case of an Availability Zone failure, the RDS database will automatically switch over to a secondary Availability Zone allowing the SAS Viya platform to be restarted with minimal delay.

3. **FSx ONTAP**
  Amazon FSx for NetApp ONTAP is deployed with the [Multi-AZ deployment type](https://docs.aws.amazon.com/fsx/latest/ONTAPGuide/high-availability-AZ.html). SAS Viya requires both RWO block storage and RWX shared storage. Amazon FSx for NetApp ONTAP provides both storage requirements with a deployment type that makes this storage available across Availability Zones. This again ensures the SAS Viya platform can be restarted with minimal delay in case of an Availability Zone failure.

4. **Elastic Container Registry**
  Although not strictly required, removing the dependency on upstream container image repositories decreases the time in which you are able to restart your environment in a different Availability Zone. Using an [Elastic Container Registry](https://aws.amazon.com/ecr/) removes this dependency. The ECR should not only [mirror the SAS container registry](https://go.documentation.sas.com/doc/en/sasadmincdc/default/dplyml0phy0dkr/n1h0rgtr10fpnfn1mg0s8fgfuof8.htm), but also any other images required to run the supporting services in the EKS cluster such as the Ingress controller and CSI providers.