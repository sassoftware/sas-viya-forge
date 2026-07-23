## Scenario

This is a guide on deploying SAS Viya on OVHcloud's Managed Kubernetes Service using Terraform.


### Platform Overview

OVHcloud is the largest European cloud provider headquartered in France and it operates its own datacenters and network backbone across Europe, Canada, and the Asia-Pacific region. The three main technology stacks that they offer are the following:

**Public Cloud**

Their OpenStack-based cloud platform offering on-demand compute, storage, and networking resources. It's a pay-as-you-go model similar to AWS or Azure, where infrastructure is shared among customers. The Managed Kubernetes Service that is used for the deployment is included in this stack.

**Hosted Private Cloud**

A dedicated VMware/Nutanix environment hosted in OVHcloud's datacenters but reserved exclusively for a single customer. 

**Bare Metal Cloud**

Provides access to dedicated physical servers without a virtualization layer. Servers are available on hourly or monthly billing cycles and offer direct access to all hardware resources. OVHcloud designs and manufactures a significant portion of its own server hardware. 

All three stacks are deployed across OVHcloud's owned datacenter and network infrastructure, with a stated focus on data residency options within the European Union.

### Components

This diagram illustrates the SAS Viya System, along with its components.

![viya-diagram](/sections/platform-specific/cncf/deployment-guides/ovh-deployment/20260603/img/arch-diagram.png)

Managed Kubernetes Service (4) consisting of the following node pools (3):

+ CAS 
+ Compute 
+ Stateless and stateful 

Storage

+ RWO storage (5)
+ RWX storage - OVH File Storage/NFS (6)

Networking

+ Load Balancer (2)
+ Private Network (8) 

Database

+ External PostgreSQL database (7)

Other components

+ Private Registry (1)