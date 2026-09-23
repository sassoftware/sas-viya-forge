## Objective
SAS is advancing a quantum computing initiative to bring quantum capabilities to SAS Viya. The goal is to make quantum computing more intuitive, efficient, and cost-effective, reducing the barriers to adoption and accelerating the path from experimentation to business value. This document provides a high-level introduction to the quantum physical property called entanglement that is used in quantum computing.

## What Is Quantum Entanglement?

> Entanglement is not faster-than-light messaging. It is a property of a joint quantum state whose correlations cannot be reproduced by a local classical model.

Quantum entanglement occurs when the joint state of two or more quantum systems cannot be written as separate states for the individual systems. The systems must be described together. Measurements on them can display correlations that cannot be reproduced by a local classical model.

Entanglement does not mean that every property of one system can be inferred from every measurement on another. The correlation depends on the entangled state and on the observables being measured. For the Bell state below, measuring both qubits in the computational basis always produces matching outcomes:

$$
|\Phi^+\rangle=\frac{|00\rangle+|11\rangle}{\sqrt{2}}
$$

Each individual result is random. In repeated ideal measurements, half of the outcomes are $00$ and half are $11$. The useful structure lies in the joint distribution: the two outcomes match. If the measurement basis changes, the correlation must be analyzed in that basis.

!!! note "The defining mathematical test"  
    A pure bipartite state is entangled when it cannot be factored as
    $|\Psi_{AB}\rangle=|\psi_A\rangle\otimes|\phi_B\rangle$.
    The complete joint state is well defined even when neither subsystem has its own pure state.

### Information in correlations

A useful analogy is a quantum book whose information is stored primarily in relationships among pages rather than on any page by itself. Reading one page reveals little about the whole. The structure becomes visible only when multiple pages are examined together. Likewise, an entangled state can contain information in correlations that is absent from either subsystem alone.

### Correlation is not communication

Entanglement cannot by itself transmit a controllable message faster than light. Alice cannot choose the random result recorded at one detector, and the other detector's local results are also random. The correlation appears only after the records are compared through an ordinary classical channel.

## Why Entanglement Matters in Quantum Information

Entanglement gives a quantum processor access to joint states and correlations that cannot be represented as independent qubit states. Combined with superposition, relative phase, interference, and controlled operations, it can be an important resource in quantum algorithms and protocols.

- Quantum teleportation uses shared entanglement and classical communication to transfer an unknown quantum state.
- Superdense coding uses a shared Bell pair so that operations on one qubit can encode two classical bits for later joint decoding.
- Quantum networking uses entanglement as a resource for distributed quantum tasks.
- Quantum error-correcting codes encode logical information across correlated physical qubits.
- Many quantum algorithms generate entanglement, but entanglement alone does not guarantee computational advantage.

A useful explanation of quantum computation should avoid saying that the processor tries every answer in parallel and simply reads out the correct one. Measurement returns limited classical information. The algorithm must shape amplitudes and phases so that interference increases the probability of useful outcomes and suppresses others.