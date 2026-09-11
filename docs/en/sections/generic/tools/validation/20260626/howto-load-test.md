---
title: Performing Load Tests
---

# Performing Load Tests

Performance scaling analysis evaluates how a system’s performance (e.g., speed, throughput) changes as more users get on the system and use the applications. 

It identifies bottlenecks and helps identify aspects of the system that need to be tuned to ensure system efficacy under increased load 

## Running tests with varied number of users:
This section assumes that you are running [SAS validation scenarios inside of kubernetes](https://github.com/sassoftware/sas-validation-scenarios/blob/main/documentation/GETTING-STARTED-WITH-LOCUST-ON-KUBERNETES.md)

The sas-validation-scenarios, by default run with a single user. Results are saved in the results folder as a CSV file with a prefix denoting the number of users the scenario ran with. By default this therefore results in names such as 1_logonoff.csv

Unlike the execution-logs folder, the results folder in the artifacts dir does not gets overwritten after each runWorkload.sh execution. This allows us to collect the results from different runWorkload.sh runs for analysis in SAS Visual Analytics to see scaling patterns and odd behaviors.

Note: The exceptions and failures files from the locust master pods are named as the _exception.csv and _failures.csv and placed in the execution-logs folder.

To run with a different number of users follow the steps below:

> [NOTE]
> 
>  This process will be automated soon where we will have a script to generate the CRD manifest file using an overrides file. For now this has to be done manually using the following sed command.

```
# initial number of users
win=1
# new number of users
wout=3

sed -i "" "s/users ${win}/users ${wout}/g" k8s-cr-st-runsleep01.yaml
sed -i "" "s/workerReplicas: ${win}/workerReplicas: ${wout}/g"  k8s-cr-st-runsleep01.yaml

# run the runWorkload.sh script again. 
./runWorkload.sh
```


