## Solution Overview

This deployment guides consists of three sections: deploying the infrastructure, fulfilling the SAS Viya prerequisites and deploying SAS Viya.

### Infrastructure

To deploy the infrastructure we use the [viya4-iac-aws](https://github.com/sassoftware/viya4-iac-aws/tree/main) project, made available on GitHub. The Viya 4 Infrastructure as Code repositories provide a starting point in creating Infrastructure as Code assets based on Terraform. Instructions on how to use this project to deploy infrastructure using the recommended docker method can be found [here](https://github.com/sassoftware/viya4-iac-aws/blob/main/docs/user/DockerUsage.md).

#### IaC preparation

To serve our needs, we make the following adjustments to the default IaC scripts:

1. In the **locals.tf** file, add the following key-value mapping to the user_node_pool block :

    ```
    subnet_ids = module.vpc.private_subnets[np_value.subnet_number]
    ```
    
    This addition allows us, together with the related change in the variables.tf file to specify a specific subnet for each node pool. This is required as we want to be able to deploy node pools in specific availability zones, which are linked to the associated subnets.


2. In the **main.tf** file, add the following key-value mapping to the postgresql module:

    ```
    db_name  = each.value.db_name
    ```

    Although not strictly required, without specifying the db_name variable, no database will be created within the PostgreSQL instance. This can be done manually after the infrastructure deployment has finished, but with this small modification it is taken care of during infrastructure deployment.

3. In the **variables.tf** file, add subnet_number as a variable within the node_pools configurations, for instance insert it above the existing [min_nodes](https://github.com/sassoftware/viya4-iac-aws/blob/main/variables.tf#L308) variable:

    ```
    subnet_number                        = number
    ```

    This add the subnet_number as a valid variable for a node pool.
  
    Also add the subnet number to all the default node pools before the [min_nodes](https://github.com/sassoftware/viya4-iac-aws/blob/main/variables.tf#L325) variable:
    ```
    "subnet_number" = 0
    ```

    Also add db_name as a variable to default PostgreSQL server, for instance above the [administrator_login](https://github.com/sassoftware/viya4-iac-aws/blob/main/variables.tf#L606) variable:
    ```
    db_name                 = "SharedServices"
    ```

    SharedServices is the name of the database SAS Viya expects to find by default for it's internal database server.

    Finally, add a completely new variable for the SVM Administrator password:
    ```
    # The ONTAP administrative password for the svmadmin user that you can use to administer your Storage Virtual Machine using the ONTAP CLI and REST API.
    variable "aws_fsx_ontap_svmadmin_password" {
      description = "The ONTAP administrative password for the fsxadmin user that you can use to administer your Storage Virtual Machine using the ONTAP CLI and REST API."
      type        = string
      default     = "v3RyS3cretPa$sw0rd"
    }
    ```

    This change, along with the related change in the vms.tf file allows us to specify the administrator password for the FSx for ONTAP Storage Virtual Machine. This is required for the Trident storage provisioner which we will deploy later on.

4. In the **vms.tf** file, add route_table_ids to the aws_fsx_ontap_file_system resource, for example before the existing [tags](https://github.com/sassoftware/viya4-iac-aws/blob/main/vms.tf#L36) option:

    ```
    route_table_ids     = module.vpc.private_route_table_ids
    ```

    This change makes sure that the FSx for ONTAP file system will utilize the same routing table as will be configured for the subnets containing the Kubernetes nodes. This ensures that the workloads running on the Kubernetes cluster are able to reach the endpoints of the FSx for ONTAP filesystem.

    Finally add the SVM Administrator password to the aws_fsx_ontap_storage_virtual_machine resource, for instance before the existing [name](https://github.com/sassoftware/viya4-iac-aws/blob/main/vms.tf#L46) option.

    ```
    svm_admin_password  = var.aws_fsx_ontap_svmadmin_password
    ```

    As was mentioned before, this change allows setting the SVM administrator password required for the Trident storage provisioner.

With these changes made, you can now build the Docker container that will run the Terraform process:
```
docker build -t viya4-iac-aws .
```

#### IaC execution

To deploy the infrastructure that supports the reference architecture, we create a terraform.tfvars file a number of sections.
In this example we deploy to us-east-1 in availability zones D and E.

<details>
<summary>General Options</summary>

```
# Set general options
prefix                      = "<specify prefix>"
location                    = "us-east-1"
ssh_public_key              = "/.ssh/<your public key file>"

# Tags for all tagable items in your cluster.
tags = {} # e.g., { "key1" = "value1", "key2" = "value2" }
```
</details>

- These options can be defined as required

<details>
<summary>Networking</summary>

```
# Networking
subnets = {
    "private"       : ["192.168.0.0/18", "192.168.64.0/18"],
    "control_plane" : ["192.168.130.0/28", "192.168.130.16/28"]
    "public"        : ["192.168.129.0/25", "192.168.129.128/25"],
    "database"      : ["192.168.128.0/25", "192.168.128.128/25"]
}

subnet_azs = {
  "private"       : ["us-east-1d", "us-east-1e"],
  "control_plane" : ["us-east-1d", "us-east-1e"],
  "public"        : ["us-east-1d", "us-east-1e"],
  "database"      : ["us-east-1d", "us-east-1e"]
}

## Note that without specifying your CIDR block access rules, 
## ingress traffic to your cluster will be blocked by default
default_public_access_cidrs = [] # e.g., ["123.45.6.89/32"]
```
</details>

- The subnet CIDRs can be configured as desired, as long as the address space for each of the subnets is sufficient for their purpose. The example subnet sizes should be sufficient in most scenarios, but tuning may be required to support specific workloads.
- Also take into account that these CIDR ranges should not overlap with existing CIDR ranges in your network.
- The subnet to availability zone mapping can also be configured as desired.
- The default Public access CIDRs can be left empty, but the public endpoints of the AWS resources that are being created will only accessible through authenticated AWS clients (for example, the AWS Portal, the AWS CLI, etc.). There are multiple options to configure the network CIDRs that have access to the create resources. You can review these [here](https://github.com/sassoftware/viya4-iac-aws/blob/main/docs/CONFIG-VARS.md#admin-access).

<details>
<summary>PostgreSQL</summary>

```
# PostgreSQL
postgres_servers = {
  default = {
    multi_az = true
  },
}
```
</details>

- For the external RDS PostgreSQL server, the only option that has to be changed is the "multi_az" option. Other options can optionally, and in the case of the passwords, should be changed. See the available options [here](https://github.com/sassoftware/viya4-iac-aws/blob/main/docs/CONFIG-VARS.md#postgresql-server).

<details>
<summary>EKS Configuration</summary>

```
# Cluster config
kubernetes_version           = "1.32"
default_nodepool_node_count  = 2
default_nodepool_vm_type     = "r6in.xlarge"
default_nodepool_custom_data = ""

# Cluster Node Pools config
node_pools = {
  cascontroller_0 = {
    "vm_type"       = "r6idn.xlarge"
    "cpu_type"      = "AL2023_x86_64_STANDARD"
    "os_disk_type"  = "gp2"
    "os_disk_size"  = 200
    "os_disk_iops"  = 0
    "subnet_number" = 0
    "min_nodes"     = 2
    "max_nodes"     = 2
    "node_taints"   = ["workload.sas.com/class=cascontroller:NoSchedule"]
    "node_labels"   = {
      "workload.sas.com/class" = "cascontroller"
    }
    "custom_data"                          = "./files/custom-data/additional_userdata.sh"
    "metadata_http_endpoint"               = "enabled"
    "metadata_http_tokens"                 = "required"
    "metadata_http_put_response_hop_limit" = 1
  },
  cascontroller_1 = {
    "vm_type"       = "r6idn.xlarge"
    "cpu_type"      = "AL2023_x86_64_STANDARD"
    "os_disk_type"  = "gp2"
    "os_disk_size"  = 200
    "os_disk_iops"  = 0
    "subnet_number" = 1
    "min_nodes"     = 0
    "max_nodes"     = 2
    "node_taints"   = ["workload.sas.com/class=cascontroller:NoSchedule"]
    "node_labels"   = {
      "workload.sas.com/class" = "cascontroller"
    }
    "custom_data"                          = "./files/custom-data/additional_userdata.sh"
    "metadata_http_endpoint"               = "enabled"
    "metadata_http_tokens"                 = "required"
    "metadata_http_put_response_hop_limit" = 1
  },
  casworker_0 = {
    "vm_type"       = "r6idn.2xlarge"
    "cpu_type"      = "AL2023_x86_64_STANDARD"
    "os_disk_type"  = "gp2"
    "os_disk_size"  = 200
    "os_disk_iops"  = 0
    "subnet_number" = 0
    "min_nodes"     = 2
    "max_nodes"     = 2
    "node_taints"   = ["workload.sas.com/class=casworker:NoSchedule"]
    "node_labels"   = {
      "workload.sas.com/class" = "casworker"
    }
    "custom_data"                          = "./files/custom-data/additional_userdata.sh"
    "metadata_http_endpoint"               = "enabled"
    "metadata_http_tokens"                 = "required"
    "metadata_http_put_response_hop_limit" = 1
  },
  casworker_1 = {
    "vm_type"       = "r6idn.2xlarge"
    "cpu_type"      = "AL2023_x86_64_STANDARD"
    "os_disk_type"  = "gp2"
    "os_disk_size"  = 200
    "os_disk_iops"  = 0
    "subnet_number" = 1
    "min_nodes"     = 0
    "max_nodes"     = 2
    "node_taints"   = ["workload.sas.com/class=casworker:NoSchedule"]
    "node_labels"   = {
      "workload.sas.com/class" = "casworker"
    }
    "custom_data"                          = "./files/custom-data/additional_userdata.sh"
    "metadata_http_endpoint"               = "enabled"
    "metadata_http_tokens"                 = "required"
    "metadata_http_put_response_hop_limit" = 1
  },
  compute_0 = {
    "vm_type"       = "m6idn.xlarge"
    "cpu_type"      = "AL2023_x86_64_STANDARD"
    "os_disk_type"  = "gp2"
    "os_disk_size"  = 200
    "os_disk_iops"  = 0
    "subnet_number" = 0
    "min_nodes"     = 2
    "max_nodes"     = 5
    "node_taints"   = ["workload.sas.com/class=compute:NoSchedule"]
    "node_labels"   = {
      "workload.sas.com/class"        = "compute"
      "launcher.sas.com/prepullImage" = "sas-programming-environment"
    }
    "custom_data"                          = ""
    "metadata_http_endpoint"               = "enabled"
    "metadata_http_tokens"                 = "required"
    "metadata_http_put_response_hop_limit" = 1
  },
  compute_1 = {
    "vm_type"       = "m6idn.xlarge"
    "cpu_type"      = "AL2023_x86_64_STANDARD"
    "os_disk_type"  = "gp2"
    "os_disk_size"  = 200
    "os_disk_iops"  = 0
    "subnet_number" = 1
    "min_nodes"     = 0
    "max_nodes"     = 5
    "node_taints"   = ["workload.sas.com/class=compute:NoSchedule"]
    "node_labels"   = {
      "workload.sas.com/class"        = "compute"
      "launcher.sas.com/prepullImage" = "sas-programming-environment"
    }
    "custom_data"                          = ""
    "metadata_http_endpoint"               = "enabled"
    "metadata_http_tokens"                 = "required"
    "metadata_http_put_response_hop_limit" = 1
  },
  stateless_0 = {
    "vm_type"       = "m6in.xlarge"
    "cpu_type"      = "AL2023_x86_64_STANDARD"
    "os_disk_type"  = "gp2"
    "os_disk_size"  = 200
    "os_disk_iops"  = 0
    "subnet_number" = 0
    "min_nodes"     = 4
    "max_nodes"     = 5
    "node_taints"   = ["workload.sas.com/class=stateless:NoSchedule"]
    "node_labels"   = {
      "workload.sas.com/class" = "stateless"
    }
    "custom_data"                          = ""
    "metadata_http_endpoint"               = "enabled"
    "metadata_http_tokens"                 = "required"
    "metadata_http_put_response_hop_limit" = 1
  },
  stateless_1 = {
    "vm_type"       = "m6in.xlarge"
    "cpu_type"      = "AL2023_x86_64_STANDARD"
    "os_disk_type"  = "gp2"
    "os_disk_size"  = 200
    "os_disk_iops"  = 0
    "subnet_number" = 1
    "min_nodes"     = 0
    "max_nodes"     = 5
    "node_taints"   = ["workload.sas.com/class=stateless:NoSchedule"]
    "node_labels"   = {
      "workload.sas.com/class" = "stateless"
    }
    "custom_data"                          = ""
    "metadata_http_endpoint"               = "enabled"
    "metadata_http_tokens"                 = "required"
    "metadata_http_put_response_hop_limit" = 1
  },
  stateful_0 = {
    "vm_type"       = "m6in.xlarge"
    "cpu_type"      = "AL2023_x86_64_STANDARD"
    "os_disk_type"  = "gp2"
    "os_disk_size"  = 200
    "os_disk_iops"  = 0
    "subnet_number" = 0
    "min_nodes"     = 3
    "max_nodes"     = 3
    "node_taints"   = ["workload.sas.com/class=stateful:NoSchedule"]
    "node_labels"   = {
      "workload.sas.com/class" = "stateful"
    }
    "custom_data"                          = ""
    "metadata_http_endpoint"               = "enabled"
    "metadata_http_tokens"                 = "required"
    "metadata_http_put_response_hop_limit" = 1
  },
  stateful_1 = {
    "vm_type"       = "m6in.xlarge"
    "cpu_type"      = "AL2023_x86_64_STANDARD"
    "os_disk_type"  = "gp2"
    "os_disk_size"  = 200
    "os_disk_iops"  = 0
    "subnet_number" = 1
    "min_nodes"     = 0
    "max_nodes"     = 3
    "node_taints"   = ["workload.sas.com/class=stateful:NoSchedule"]
    "node_labels"   = {
      "workload.sas.com/class" = "stateful"
    }
    "custom_data"                          = ""
    "metadata_http_endpoint"               = "enabled"
    "metadata_http_tokens"                 = "required"
    "metadata_http_put_response_hop_limit" = 1
  }
}
```
</details>

- The node pool configuration can be adjusted to follow the specific sizing document for your environment. What is important is to create separate node pools in separate subnets. This is why the additional "subnet_number" was added to the node pool definition.

<details>
<summary>Storage</summary>

```
# Storage
storage_type                    = "ha"
storage_type_backend            = "ontap"
aws_fsx_ontap_deployment_type   = "MULTI_AZ_1"
```
</details>

- The storage options above are mandatory for this specific scenario and should not be changed.

<details>
<summary>Jump Server</summary>

```
# Jump Server
create_jump_vm = true
```
</details>

- Creating a Jump VM is not required, but can be useful in cases where network access to Kubernetes API is restricted.

Once the terraform.tfvars file has been configured to your liking, you can start the Terraform process as described [here](https://github.com/sassoftware/viya4-iac-aws/blob/main/docs/user/DockerUsage.md).

When the Terraform process is finished, the both node pools will have instances running. To make sure SAS will only run in one availability zone at a time, the node pools in the secondary availability zone should be scaled down to zero.

You can use the AWS CLI for this. For example:

```
aws eks update-nodegroup-config \
    --cluster-name <your cluster name> \
    --nodegroup-name cascontroller_1 \
    --scaling-config minSize=0,maxSize=2,desiredSize=0
```

### Prerequisites

The provisioning of prerequisites is no different from default deployments and is described in the [SAS Viya Operations Guide](https://go.documentation.sas.com/doc/en/sasadmincdc/default/itopssr/titlepage.htm).

The exception here is the installation of Trident, which provides volume provisioning on FSx for ONTAP for both RWO block devices and RWX shared filesystems. The deployment of Trident for FSx for ONTAP is described [here](https://docs.netapp.com/us-en/trident/trident-use/trident-fsx.html).

Once Trident has been installed on the EKS cluster, we need to create the StorageClasses SAS Viya is going to use. We need to create both an RWO and RWX storage class:

<details>
<summary>storageclass-san.yaml</summary>

```
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ontap-san
provisioner: csi.trident.netapp.io
parameters:
  fsType: "ext4"
  backendType: "ontap-san"
  provisioningType: "thin"
  snapshots: "true"
```
</details>

<details>
<summary>storageclass-nas.yaml</summary>

```
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ontap-nas
provisioner: csi.trident.netapp.io
parameters:
  backendType: "ontap-nas"
  provisioningType: "thin"
  snapshots: "true"
  media: "ssd"
```

</details>
 

The storage class "ontap-san" will serve as the RWO storage class, while the "ontap-nas" storage class will server as the RWX storage class.

These storage class definitions rely on backends which we will define next:

<details>
<summary>backendconfig-san.yaml</summary>

```
apiVersion: trident.netapp.io/v1
kind: TridentBackendConfig
metadata:
  name: backend-tbc-ontap-san
  namespace: trident
spec:
  version: 1
  storageDriverName: ontap-san
  backendName: tbc-ontap-san
  svm: <svm name>
  managementLIF: <SVM Management Endpoint>
  credentials:
    name: backend-tbc-ontap-secret
```
</details>

<details>
<summary>backendconfig-nas.yaml</summary>

```
apiVersion: trident.netapp.io/v1
kind: TridentBackendConfig
metadata:
  name: backend-tbc-ontap-nas
  namespace: trident
spec:
  version: 1
  storageDriverName: ontap-nas
  backendName: tbc-ontap-nas
  svm: <svm name>
  managementLIF: <SVM Management Endpoint>
  dataLIF: <SVM Management Endpoint>
  useREST: false
  credentials:
    name: backend-tbc-ontap-secret
```
</details>

These backend configurations need to be supplied with the name of the Storage Virtual Machine and the associated management endpoint.

- The SVM name is always \<prefix\>-ontap-svm
- The SVM management endpoint is provided in the output of the IaC process as the "rwx_filestore_endpoint"

The final object to create is a secret that contains the credentials to authenticate to the Storage Virtual Machine:

<details>
<summary>trident-tbc-secret.yaml</summary>

```
apiVersion: v1
kind: Secret
metadata:
  name: backend-tbc-ontap-secret
type: Opaque
stringData:
  username: vsadmin
  password: v3RyS3cretPa$sw0rd
```
</details>

The secret shown above is the default value, which should be adjusted to the actual value configured in your terraform.tfvars file.

### Deploying SAS Viya

The deployment of SAS Viya is documented in the [SAS Viya Platform Operations guide](https://go.documentation.sas.com/doc/en/itopscdc/default/dplyml0phy0dkr/n0ccazdmcu0ry2n1uxgvzpxcmx54.htm). Customization of a SAS Viya deployment is done through the use of kustomize and controlled with a central kustomization.yaml.

For this deployment, a number of customizations are required. We will link to the relevant documentation and supply additional information if required:

- [Add a Backup Controller for CAS](https://go.documentation.sas.com/doc/en/itopscdc/default/dplyml0phy0dkr/n08u2yg8tdkb4jn18u8zsi6yfv3d.htm#p058i4oxkpgelen1nxx149psumhz)
    - A backup controller ensures the loss of a single node does not cause the loss of the entire CAS server
- [Change the Number of Workers for CAS](https://go.documentation.sas.com/doc/en/itopscdc/default/dplyml0phy0dkr/n08u2yg8tdkb4jn18u8zsi6yfv3d.htm#p1e5ki5ufxjdcjn1wo86hu5181zw)
    - Having at least two CAS workers ensures the loss of a single node does not cause the loss of the entire CAS server
- [Change the SAS Configuration Server Storage Class](https://go.documentation.sas.com/doc/en/sasadmincdc/default/dplyml0phy0dkr/n08u2yg8tdkb4jn18u8zsi6yfv3d.htm?fromDefault=#p0m4j2zjifk7win1ptquhmmkgz7y)
    - The SAS Configuration Server should use block storage. Therefore configure it to use the ontap-san storage class.
- [Change the SAS Message Broker Storage Class](https://go.documentation.sas.com/doc/en/sasadmincdc/default/calsrvinf/n00000sasmessagebroker0admin.htm#n1rlhb75e4wis7n1mlkoyxlktzmn)
    - The SAS Message Broker should use block storage. Therefore configure it to use the ontap-san storage class.
- [Change the SAS Redis Server Storage Class](https://go.documentation.sas.com/doc/en/sasadmincdc/default/calsrvinf/p07zdbfbdi338nn13a37u396on0x.htm#p0er087c34boyin1xah5t8kjgsbn)
    - The SAS Redis Server should use block storage. Therefore configure it to use the ontap-san storage class.
- [Configure OpenSearch](https://go.documentation.sas.com/doc/en/sasadmincdc/default/dplyml0phy0dkr/n1krog58in1e5bn13yfy9zxt52sd.htm#n0k7rszvues2zgn1h6xnhr4qplnp)
    - OpenSearch should use block storage. Therefore configure it to use the ontap-san storage class.
    - OpenSearch should be enabled for High Availability.
- [Configure the RWX storage class](https://go.documentation.sas.com/doc/en/sasadmincdc/default/dplyml0phy0dkr/n1krog58in1e5bn13yfy9zxt52sd.htm#n152lwdwdf825yn1ev1lphbk88aa)
    - The storage class for RWX volumes is controlled through a single RWXStorageClass resource. This should be set to use ontap-nas.

Once these customizations have been configured, you can deploy SAS Viya as described [here](https://go.documentation.sas.com/doc/en/sasadmincdc/default/dplyml0phy0dkr/p127f6y30iimr6n17x2xe9vlt54q.htm).
