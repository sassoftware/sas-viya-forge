## Solution overview

### Assumption

Networking infrastructure has been set up so that end users can reach the SAS Viya platform and the platform can reach its datasources, in all configured Availability Zones.

### Components

The following key components make up the refererence architecture:

1. **AKS Node Pools**
  AKS Node Pools are deployed across at least three Availability Zones to ensure clustered services will always be able to achieve a quorum in case an Availability Zones goes down. All node pools are labeled and tainted according to the [SAS documentation](https://go.documentation.sas.com/doc/en/sasadmincdc/default/dplyml0phy0dkr/p0om33z572ycnan1c1ecfwqntf24.htm#n0wj0cyrn1pinen1wcadb0rx6vbm). If following the recommended workload placement strategy this means at least 5 node pools will be created:
    - Default node pool
    - Stateless node pool
    - Stateful node pool
    - Compute node pool
    - CAS node pool

2. **Azure DB for PostgreSQL**
  A [zone-redundant Azure DB for PostgreSQL database](https://learn.microsoft.com/en-us/azure/reliability/reliability-postgresql-flexible-server?toc=%2Fazure%2Fpostgresql%2Ftoc.json&bc=%2Fazure%2Fpostgresql%2Fbreadcrumb%2Ftoc.json#availability-zone-support) is deployed. In case of an Availability Zone failure, database will automatically failover to a secondary Availability Zone allowing the SAS Viya platform to resume connections with minimal delay.

3. **Azure Files**
  Azure Files is deployed with [zone-redundant storage](https://learn.microsoft.com/en-us/azure/storage/files/files-redundancy?tabs=azure-portal#zone-redundant-storage). SAS Viya requires both RWO block storage and RWX shared storage. Azure Files provides a resilient RWX shared storage platform. This ensures the SAS Viya platform can still access its storage layer in case of an Availability Zone failure.

4. **Azure Disk Storage**
  For RWO block storage, Azure Disks are used. When Azure Disks are provisioned with [Zone-redundant storage (ZRS)](https://learn.microsoft.com/en-us/azure/virtual-machines/disks-redundancy#zone-redundant-storage-for-managed-disks), Azure synchronously replicates your Azure managed disk across three Azure Availability Zones in the region you select. This again ensures the SAS Viya platform can still access its storage layer in case of an Availability Zone failure.

4. **Azure Container Registry**
  Although not strictly required, removing the dependency on upstream container image repositories decreases the time in which you are able to create new container instances in a different Availability Zone. Using an [Azure Container Registry](https://azure.microsoft.com/en-us/products/container-registry) removes this dependency. The ACR should not only [mirror the SAS container registry](https://go.documentation.sas.com/doc/en/sasadmincdc/default/dplyml0phy0dkr/n1h0rgtr10fpnfn1mg0s8fgfuof8.htm), but also any other images required to run the supporting services in the ACR cluster such as the Ingress controller and CSI providers.