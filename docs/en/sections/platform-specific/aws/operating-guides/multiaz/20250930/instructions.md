## Instructions

If you implemented a SAS Viya environment following the Reference Architecture for SAS Viya Multi Availability Zone Deployments on AWS, you should at this moment have a Viya environment that runs within a single Availability Zone, but is enabled to quickly fail over to a secondary Availability Zone when the primary zone goes down.

### Operating in Normal Conditions

When you want to start or stop your Viya environment under normal conditions, where the primary Availability Zone is available, you can follow the default instructions in the [Servers and Services](https://go.documentation.sas.com/doc/en/sasadmincdc/default/calchkadm/n00001ongoingtasks00000admin.htm) section of the Viya Administration Guide. The Viya environment will operate like any other Viya environment.

### Operating when the primary Availability Zone is down

When the primary Availability Zone of your Viya environment is down, you can quickly recover your Viya environment into a running state by scaling up the node groups in the secondary Availability Zone. All supported components like the PostgreSQL server and storage provider should already be available in the secondary Availability Zone.

You can use the AWS CLI for this. For example:

```
aws eks update-nodegroup-config \
    --cluster-name <your cluster name> \
    --nodegroup-name cascontroller_1 \
    --scaling-config minSize=2,maxSize=2,desiredSize=2
```

It is also advisable to scale down the node groups in the primary Availability Zone to prevent them from being accidentally started when the Availability Zone recovers:

```
aws eks update-nodegroup-config \
    --cluster-name <your cluster name> \
    --nodegroup-name cascontroller_0 \
    --scaling-config minSize=0,maxSize=2,desiredSize=0
```

You do not need to perform additional operations like starting and stopping the Viya environment unless the Viya environment was stopped prior to the Availability Zone going down. In this case you need to run a start job as described in the product documentation.