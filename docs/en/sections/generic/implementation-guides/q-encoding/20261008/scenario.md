## Quantum Encoding

Machine learning is one of the most promising applications of quantum computing. Quantum computers use superposition and entanglement, so in principle they may be able to explore complex solution spaces more efficiently than classical computers. However, quantum computers operate on quantum states, not classical data. Classical data must therefore be converted into a quantum representation that preserves the relationships between data points. This step is called embedding or encoding. It can become a bottleneck, because preparing quantum states from classical data can be expensive in both time and circuit resources.

| Type of Data | Classical Algorithm (C) | Quantum Algorithm (Q) |
| --- | --- | --- |
| Classical (C) | CC: Classical ML on Classical Data | QC: Quantum ML on Classical Data |
| Quantum (Q) | CQ: Classical ML on Quantum Data | QQ: Quantum ML on Quantum Data |

Quantum machine learning is often grouped into four categories, based on whether the data and the algorithm are classical (C) or quantum (Q). This post focuses on QC, quantum algorithms applied to classical data, because that is where most practical machine learning problems fall. The other categories are also growing in importance. CQ techniques use classical machine learning to optimize quantum circuits, for example by reducing gate count and circuit depth. QQ approaches generate quantum data that matches a problem's distribution and feed it directly into quantum machine learning algorithms, which removes the need to encode classical data at all.

In the QC setting, the goal is to use quantum mechanics to solve machine learning problems faster or to handle problems that are classically intractable. Encoding classical data into quantum states also maps it into a high-dimensional Hilbert space. That feature space can be very difficult, and sometimes impossible, to work with efficiently on a classical computer.

![Classical data mapped onto the Bloch sphere and into feature space](/sections/generic/implementation-guides/q-encoding/20261008/img/fig02_feature_space.png)

This mapping lets a quantum computer examine data in ways that may not be feasible classically. Once the data is encoded as quantum states on the qubits, a parameterized circuit called an ansatz processes it. The ansatz implements algorithms such as quantum neural networks, quantum support vector machines and variational eigensolvers. The qubits are then measured, and any classical post-processing is applied to the results.

![Quantum embedding, ansatz circuit and post-processing pipeline](/sections/generic/implementation-guides/q-encoding/20261008/img/fig03_embedding_pipeline.png)