## Introduction

This document explains the mechanics behind cgroup-level out of memory (OOM) events in SAS Viya compute sessions and provides two practical methods for sizing the sas-programming-environment container memory limit: a dirty-page-aware method that explicitly accounts for Linux write-back behavior, and a formula-based method that can be applied without relying on kernel dirty-page settings or node-memory-derived calculations. This document expects you to be familiar with compute pod provisioning, launcher and compute contexts.

The discussion focuses on the memory behavior of SAS Viya compute sessions running in containers. Additional runtimes, such as Python and R, are out of scope; however, their memory consumption still contributes to the same cgroup boundary and can directly cause a cgroup OOM and leave the pod in an OOMKilled state.
