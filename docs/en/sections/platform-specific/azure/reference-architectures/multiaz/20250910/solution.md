## Solution overview

### Assumption

Networking infrastructure has been set up so that end users can reach the SAS Viya platform and the platform can reach its data sources, regardless of in which Availability Zone the application is running.

### Components

The following key components make up the reference architecture:

1. **AKS Node Pools**
  Separate AKS Node Pools are deployed in at least two Availability Zones. All node pools are labeled and tainted according to the [SAS documentation](https://go.documentation.sas.com/doc/en/sasadmincdc/default/dplyml0phy0dkr/p0om33z572ycnan1c1ecfwqntf24.htm#n0wj0cyrn1pinen1wcadb0rx6vbm). If following the recommended workload placement strategy this means at least 10 node pools will be created:
    - 2 default node pools
    - 2 stateless node pools
    - 2 stateful node pools
    - 2 compute node pools
    - 2 CAS node pools

    Five of these node pools will be scaled down to zero nodes in normal operation. In case of an Availability Zone failure, these node pools can be scaled up to the required number of nodes.

2. **Azure DB for PostgreSQL**
  A [zone-redundant Azure DB for PostgreSQL database](https://learn.microsoft.com/en-us/azure/reliability/reliability-postgresql-flexible-server?toc=%2Fazure%2Fpostgresql%2Ftoc.json&bc=%2Fazure%2Fpostgresql%2Fbreadcrumb%2Ftoc.json#availability-zone-support) is deployed. In case of an Availability Zone failure, database will automatically failover to a secondary Availability Zone allowing the SAS Viya platform to be restarted with minimal delay.

3. **Azure NetApp Files**
  Azure NetApp Files is deployed with [cross-zone replication of volumes](https://learn.microsoft.com/en-us/azure/azure-netapp-files/replication). SAS Viya requires both RWO block storage and RWX shared storage. Azure NetApp Files provides a resilient RWX shared storage platform. This again ensures the SAS Viya platform can be restarted with minimal delay in case of an Availability Zone failure.

4. **Azure Disk Storage**
  For RWO block storage, Azure Disks are used. When Azure Disks are provisioned with [Zone-redundant storage (ZRS)](https://learn.microsoft.com/en-us/azure/virtual-machines/disks-redundancy#zone-redundant-storage-for-managed-disks), Azure synchronously replicates your Azure managed disk across three Azure Availability Zones in the region you select. This again ensures the SAS Viya platform can be restarted with minimal delay in case of an Availability Zone failure.

4. **Azure Container Registry**
  Although not strictly required, removing the dependency on upstream container image repositories decreases the time in which you are able to restart your environment in a different Availability Zone. Using an [Azure Container Registry](https://azure.microsoft.com/en-us/products/container-registry) removes this dependency. The ACR should not only [mirror the SAS container registry](https://go.documentation.sas.com/doc/en/sasadmincdc/default/dplyml0phy0dkr/n1h0rgtr10fpnfn1mg0s8fgfuof8.htm), but also any other images required to run the supporting services in the ACR cluster such as the Ingress controller and CSI providers.