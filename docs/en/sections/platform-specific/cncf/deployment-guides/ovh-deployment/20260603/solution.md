## Solution overview

### Assumptions

+ An active OVHcloud subscription;
+ A project created in the OVH Public Cloud;
+ If deploying using Terraform, then refer to the [Terraform Setup Guide](/sections/platform-specific/cncf/deployment-guides/ovh-deployment/20260603/terraform-setup-guide.md)

### Solution

For this deployment guide of SAS Viya, the **Public Cloud** technology stack has been chosen, using the Managed Kubernetes Service.


### Provisioning the infrastructure

The infrastructure for deploying SAS Viya is provisioned using Terraform. While all the steps outlined below can also be performed through the OVHcloud UI, Terraform provides greater flexibility and allows for more precise customization.

_Disclaimer:_ The provided snippets are intended as examples and should be adapted to suit each specific use case; they are not designed to be used as ready-made solutions.

**Create the private network**

- A private network is configured for the cluster; if not specified, the cluster defaults to the OVH public cloud network.

- This private network consists of two subnets: one dedicated to the cluster nodes and another for the load balancer.

- Additionally, two gateways are created as part of the setup.

<details>
<summary>📄private-network.tf</summary>

```tf
resource "ovh_cloud_project_network_private" "mypriv_2" {
  service_name  = "<PUBLIC_CLOUD_PROJECT_ID>"  # Replace with your OVHcloud project ID
  vlan_id       = "ID"             # VLAN ID (usually 0)
  name          = "mypriv_2"
  regions       = ["<YOUR_REGION>"]
}

resource "ovh_cloud_project_network_private_subnet" "myprivsub1" {
  service_name  = ovh_cloud_project_network_private.mypriv_2.service_name
  network_id    = ovh_cloud_project_network_private.mypriv_2.id
  region        = "<YOUR_REGION>"
  start         = "10.0.0.2"
  end           = "10.0.255.254"
  network       = "10.0.0.0/16"
  dhcp          = true
}

resource "ovh_cloud_project_network_private_subnet" "myprivsub2" {
  service_name  = ovh_cloud_project_network_private.mypriv_2.service_name
  network_id    = ovh_cloud_project_network_private.mypriv_2.id
  region        = "<YOUR_REGION>"
  start         = "10.1.0.2"
  end           = "10.1.255.254"
  network       = "10.1.0.0/16"
  dhcp          = true
}

resource "ovh_cloud_project_gateway" "gateway1" {
  service_name = ovh_cloud_project_network_private.mypriv_2.service_name
  name         = "my-gateway1"
  model        = "s"  # Gateway model ("s" for small, "m" for medium, etc.)
  region       = ovh_cloud_project_network_private_subnet.myprivsub1.region
  network_id   = tolist(ovh_cloud_project_network_private.mypriv_2.regions_attributes[*].openstackid)[0]
  subnet_id    = ovh_cloud_project_network_private_subnet.myprivsub1.id
}

resource "ovh_cloud_project_gateway" "gateway2" {
  service_name = ovh_cloud_project_network_private.mypriv_2.service_name
  name         = "my-gateway2"
  model        = "s"  # Gateway model ("s" for small, "m" for medium, etc.)
  region       = ovh_cloud_project_network_private_subnet.myprivsub2.region
  network_id   = tolist(ovh_cloud_project_network_private.mypriv_2.regions_attributes[*].openstackid)[0]
  subnet_id    = ovh_cloud_project_network_private_subnet.myprivsub2.id
}
```
</details>

**Create the cluster**

- The script provisions a cluster with three node pools, corresponding to the main workloads outlined earlier.

- It uses the previously created private network and its two subnets.

- The compute and CAS node pools are labeled and tainted.


<details>
<summary>📄cluster.tf</summary>

```tf
resource "ovh_cloud_project_kube" "my_cluster" {
  service_name = "<PUBLIC_CLOUD_PROJECT_ID>"
  name         = "viya_cluster"
  region       = "<YOUR_REGION>"
  version      = "1.34"

  private_network_id       = tolist(ovh_cloud_project_network_private.mypriv_2.regions_attributes[*].openstackid)[0]
  nodes_subnet_id          = ovh_cloud_project_network_private_subnet.myprivsub1.id
  load_balancers_subnet_id = ovh_cloud_project_network_private_subnet.myprivsub2.id
}

resource "ovh_cloud_project_kube_nodepool" "node_pool_1" {
  service_name  = ovh_cloud_project_kube.my_cluster.service_name
  kube_id       = ovh_cloud_project_kube.my_cluster.id
  name          = "services"
  flavor_name   = "b3-16"
  desired_nodes = 4
  
}

resource "ovh_cloud_project_kube_nodepool" "node_pool_2" {
  service_name  = ovh_cloud_project_kube.my_cluster.service_name
  kube_id       = ovh_cloud_project_kube.my_cluster.id
  name          = "compute"
  flavor_name   = "b3-32"
  desired_nodes = 2
  template {
    metadata {
      annotations = {

      }
      finalizers = []
      labels = {
        "workload.sas.com/class" = "compute"
      }
    }

    spec {
      unschedulable = false
      taints = [
        {
          effect = "NoSchedule"
          key    = "workload.sas.com/class"
          value  = "compute"
        }
      ]
    }
  }
}

resource "ovh_cloud_project_kube_nodepool" "node_pool_3" {
  service_name  = ovh_cloud_project_kube.my_cluster.service_name
  kube_id       = ovh_cloud_project_kube.my_cluster.id
  name          = "cas"
  flavor_name   = "r3-128"
  desired_nodes = 1
    template {
    metadata {
      annotations = {

      }
      finalizers = []
      labels = {
        "workload.sas.com/class" = "cas"
      }
    }

    spec {
      unschedulable = false
      taints = [
        {
          effect = "NoSchedule"
          key    = "workload.sas.com/class"
          value  = "cas"
        }
      ]
    }
  }
}

output "kubeconfig_file" {
  value     = ovh_cloud_project_kube.my_cluster.kubeconfig
  sensitive = true
}
```
</details>

**Create an external PostgreSQL database**

- This script is used to provision an external PostgreSQL database instance

- It uses the previously created private network and one of the subnets

- The instance also contains an IP Restriction list which currently gives permission to two IP addresses (current IP address and the OVHcloud Platform IP address) but this can be modified 

- The kubeconfig file is passed as an output

<details>
<summary>📄database.tf </summary>

```tf
resource "ovh_cloud_project_database" "database" {
  service_name = "<PUBLIC_CLOUD_PROJECT_ID>"
  engine       = "postgresql"
  flavor       = "db1-4"

  nodes {
    network_id = "<NETWORK_ID>"
    region     = "<YOUR_REGION>"
    subnet_id  = "<SUBNET_ID>"
  }

  plan        = "essential"
  version     = "17"
  description = "scarce-kao"

  ip_restrictions {
    ip          = "<OVH_IP>"
    description = "OVHcloud Dataplatform"
  }
  ip_restrictions {
    ip          = "<CURRENT_IP>"
    description = "current ip"
  }

  disk_size = 160
}
```

</details>

**Create the file storage**

- This creates the file storage services

- Add the additional steps that might be needed (create the storage classes etc)

<details>
<summary>📄file-storage.tf</summary>

```tf
data "openstack_networking_network_v2" "private_network" {
  name   = "<YOUR_PRIVATE_NETWORK_NAME>"
  region = "<YOUR_REGION_NAME>"
}

data "openstack_networking_subnet_v2" "private_subnet" {
  name   = "<YOUR_PRIVATE_SUBNET_NAME>"
  region = "<YOUR_REGION_NAME>"
}

resource "openstack_sharedfilesystem_sharenetwork_v2" "sharenetwork" {
  name             = "<YOUR_SHARE_NAME>"
  region           = "<YOUR_REGION_NAME>"
  share_type       = "standard-1az"
  share_proto      = "NFS"
  size             = 150
  share_network_id = openstack_sharedfilesystem_sharenetwork_v2.sharenetwork.id
}

resource "openstack_sharedfilesystem_share_access_v2" "share_access" {
  share_id     = openstack_sharedfilesystem_share_v2.share.id
  region       = "<YOUR_REGION_NAME>"
  access_type  = "ip"
  access_to    = "<IP_ADDRESS>"
  access_level = "rw"
}
```
</details>

**Create the managed private registry**

- This creates the managed private registry

<details>
<summary>📄private-registry.tf</summary>

```tf
data "ovh_cloud_project_capabilities_containerregistry_filter" "regcap" {
  service_name = "<PUBLIC_CLOUD_PROJECT_ID>"
  plan_name    = "SMALL"
  region       = "<YOUR_REGION_NAME>"
}

resource "ovh_cloud_project_containerregistry" "my_registry" {
  service_name = data.ovh_cloud_project_capabilities_containerregistry_filter.regcap.service_name
  plan_id      = data.ovh_cloud_project_capabilities_containerregistry_filter.regcap.id
  region       = data.ovh_cloud_project_capabilities_containerregistry_filter.regcap.region
  name         = "harborregistry"
}
```

</details>


### Intermediary Steps

In order to be able to run the post deployment configuration scripts, some additional steps are needed:
- Output the `kubeconfig` file through Terraform;
- Create a new Terraform working directory and install the `kubernetes` and `contour` providers;

### Post deployment infrastructure configuration

**Install Contour**

- This script is used to install contour through a Helm chart


<details>
<summary>📄contour.tf</summary>

```tf
resource "kubernetes_namespace_v1" "contour" {
  metadata {
    name = "projectcontour"
  }
}

resource "helm_release" "contour" {
  name       = "contour"
  repository = "https://projectcontour.github.io/helm-charts/"
  chart      = "contour"
  namespace  = kubernetes_namespace_v1.contour.metadata[0].name
  version    = "0.5.0"

  depends_on = [kubernetes_namespace_v1.contour]
}
```
</details>

**Install OpenLDAP (optional)**

- For testing purposes we can deploy OpenLDAP

- This script is used to deploy OpenLDAP through a Helm chart

<details>
<summary>📄openldap.tf</summary>

```tf
resource "kubernetes_namespace_v1" "openldap" {
  metadata {
    name = "openldap"
  }
}

resource "helm_release" "openldap" {
  name       = "openldap"
  repository = "<REPO>"
  chart      = "openldap"
  namespace  = kubernetes_namespace_v1.openldap.metadata[0].name
  version    = "4.2.2" 

  set {
    name  = "global.ldapDomain"
    value = "<DOMAIN>"
  }

  set {
    name  = "global.adminPassword"
    value = var.openldap_admin_password
  }

  depends_on = [kubernetes_namespace_v1.openldap]
}
```
</details>

### Prerequisites

The provisioning of prerequisites is no different from default deployments and is described in the [SAS Viya Operations Guide](https://go.documentation.sas.com/doc/en/sasadmincdc/default/itopssr/titlepage.htm).

The difference is that the OVH Managed Kubernetes Service has the following storage classes provisioned by default. The storage classes ending in "-luks" are the encrypted variants of the regular storage.

```
NAME                              PROVISIONER                RECLAIMPOLICY   VOLUMEBINDINGMODE
csi-cinder-classic                cinder.csi.openstack.org   Delete          Immediate
csi-cinder-classic-luks           cinder.csi.openstack.org   Delete          Immediate
csi-cinder-high-speed             cinder.csi.openstack.org   Delete          Immediate
csi-cinder-high-speed-gen2        cinder.csi.openstack.org   Delete          Immediate
csi-cinder-high-speed-gen2-luks   cinder.csi.openstack.org   Delete          Immediate
csi-cinder-high-speed-luks        cinder.csi.openstack.org   Delete          Immediate
```

For instance, the definition of the default storage class, `csi-cinder-high-speed`, looks like this:

```
allowVolumeExpansion: true
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  labels:
    mks.ovh/version: 1.34.6-2
  name: csi-cinder-high-speed
parameters:
  availability: nova
  fsType: ext4
  type: high-speed
provisioner: cinder.csi.openstack.org
reclaimPolicy: Delete
volumeBindingMode: Immediate
```


When using the NFS file storage, we first need to install the NFS client external provisioner and create our own storage class:

```
allowVolumeExpansion: true
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: nfs-storage-class
parameters:
  archiveOnDelete: "false"
provisioner: cluster.local/nfs-client-nfs-subdir-external-provisioner
reclaimPolicy: Delete
volumeBindingMode: Immediate

```

### Deployment

The deployment of SAS Viya is documented in the [SAS Viya Platform Operations guide](https://go.documentation.sas.com/doc/en/sasadmincdc/default/itopssr/titlepage.htm). Customization of a SAS Viya deployment is done through the use of kustomize and controlled with a central `kustomization.yaml`.

For this deployment, a number of customizations are required.

+ [Configure the RWX storage class](https://go.documentation.sas.com/doc/en/sasadmincdc/default/dplyml0phy0dkr/n1krog58in1e5bn13yfy9zxt52sd.htm#n152lwdwdf825yn1ev1lphbk88aa)

The storage class for RWX volumes is controlled through a single RWXStorageClass resource. This should be set to use nfs-storage-class.

Once these customizations have been configured, you can deploy SAS Viya as described [here](https://go.documentation.sas.com/doc/en/sasadmincdc/default/dplyml0phy0dkr/p127f6y30iimr6n17x2xe9vlt54q.htm).