---
title: Running Locust
---

# Running Locust

There are two ways to execute these tests and both these methods have their own benefits. Identify the method that works best for you and follow the instructions in each of the methods to get started.

## Inside Kubernetes – Running Locust deployed within the cluster 

Running load tests directly within a Kubernetes (K8s) environment can offer significant technical and operational advantages over external testing methods. By treating load tests as native cluster workloads, organizations can achieve high scalability and precise environment parity.

High Scalability
Kubernetes enables massive, distributed load generation by leveraging existing cluster resources:

Horizontal Scaling: Spin up hundreds of worker pods to simulate thousands of concurrent users, distributing load across multiple nodes.
Dynamic Resource Allocation: Assign specific CPU and memory limits to tests, with the cluster automatically cleaning up resources once a test completes.
If you have a Kubernetes cluster where you can create a namespace, install an operator, deploy tests, and have sufficient resources (such as node availability), you can run these tests using this framework. This approach unlocks additional benefits like node autoscaling and other native Kubernetes capabilities to handle tests at scale.

To get started, refer to [Getting Started with Running Locust on Kubernetes](https://github.com/sassoftware/sas-validation-scenarios/blob/main/documentation/GETTING-STARTED-WITH-LOCUST-ON-KUBERNETES.md)

## Outside Kubernetes – Running Locust locally on your laptop

This is the easiest way to get started.

While the sas-validation-scenarios framework typically runs on a Kubernetes cluster, there may be cases where you want to execute tests locally on your desktop or a virtual machine using the command-line Locust interface.

Running tests locally outside a Kubernetes (K8s) cluster reduces operational complexity, allows easier access to local development environments, and simplifies debugging without managing distributed K8s jobs, while still supporting distributed testing across virtual machines or local processes.

Developers can run tests directly from a laptop or local machine, facilitating faster script development, easier access to file systems, and better debugging capabilities.

While Kubernetes is excellent for running distributed, massive-scale tests, running locally or on external VMs offers a more agile environment for initial load testing or single user testing, simplify debugging, accelerate scenario development, and provide better visibility into test behavior.

To get started refer to [Getting Started with Running Locust Locally Outside of Kubernetes Using Locust Commands](https://github.com/sassoftware/sas-validation-scenarios/blob/main/documentation/GETTING-STARTED-WITH-RUNNING-LOCUST-LOCALLY.md)