
!!! note "Scope"  
    This document emphasizes durable concepts rather than rapidly changing vendor rankings or raw qubit counts. System specifications should be verified directly with providers when used in presentations or purchasing decisions.

## Objective
SAS is advancing a quantum computing initiative to bring quantum capabilities to SAS Viya. The goal is to make quantum computing more intuitive, efficient, and cost-effective, reducing the barriers to adoption and accelerating the path from experimentation to business value. This document provides a high-level introduction to the major quantum computing modalities and computational models.

## 1. Introduction

Quantum computing is not based on a single hardware architecture. Different systems encode and manipulate quantum information using atoms, ions, photons, electron or nuclear spins, superconducting circuits, or proposed topological states. These physical implementations are often called **qubit modalities**.

The physical modality is only one part of a quantum computer. Systems also differ in their **computational model**: the way a problem is represented, controlled, and executed. Major models include gate-based quantum computing, analog quantum simulation, and quantum annealing. Some hardware platforms support more than one model.

No modality or model is best for every application. Each involves trade-offs among state preparation, coherence, gate or control fidelity, connectivity, measurement, operating environment, programmability, scalability, and accessibility. Comparing platforms therefore requires more than comparing raw qubit counts.

!!! note "Three terms to keep separate"  
    **Modality** identifies the physical carrier of quantum information.   
    **Computational model** describes how a computation is expressed and executed.  
    **Architecture** describes how qubits, controls, couplers, measurement, and supporting systems are organized within a particular implementation.

### 1.1 How to read this guide

1. Section 2 compares the principal physical qubit modalities.
2. Section 3 explains the major computational models.
3. Section 4 shows how modality and model interact in practice.
4. Section 5 provides a concise framework for evaluating systems without relying on a single headline metric.