## Entanglement in Quantum Computing

### Assumptions

Everything presented is industry standard and vendor agnostic. The illustrations below were created using the IBM Quantum Composer. This choice was made purely for convenience.

## Bell States

The Bell states are four maximally entangled two-qubit states. They form an orthonormal basis for the two-qubit state space:

$$
|\Phi^+\rangle=\frac{|00\rangle+|11\rangle}{\sqrt{2}},\qquad
|\Phi^-\rangle=\frac{|00\rangle-|11\rangle}{\sqrt{2}},
$$

$$
|\Psi^+\rangle=\frac{|01\rangle+|10\rangle}{\sqrt{2}},\qquad
|\Psi^-\rangle=\frac{|01\rangle-|10\rangle}{\sqrt{2}}.
$$

| State | Nonzero basis states | Computational-basis relation | Relative phase |
|---|---|---|---|
| $\Phi^+$ | 00 and 11 | Same outcomes | Equal |
| $\Phi^-$ | 00 and 11 | Same outcomes | Opposite |
| $\Psi^+$ | 01 and 10 | Opposite outcomes | Equal |
| $\Psi^-$ | 01 and 10 | Opposite outcomes | Opposite |

The plus and minus signs describe relative phase, not positive and negative probability. For every Bell state, the two nonzero computational-basis amplitudes have magnitude $1/\sqrt{2}$, so each corresponding outcome has probability $1/2$.

## Preparing and Visualizing the Bell States

The IBM Quantum Composer screenshots show the circuit, ideal computational-basis probabilities, and Q-sphere for each Bell state. Every circuit begins in $|00\rangle$, applies a Hadamard gate to qubit 0, and then applies a CNOT with qubit 0 as control and qubit 1 as target. Additional Pauli gates select the desired Bell state.

!!! note "How to read the screenshots"  
    The circuit appears across the top. The probability chart at lower left shows which computational-basis outcomes can be measured. The Q-sphere at lower right shows the nonzero basis-state amplitudes and their phases. Color differences in the Q-sphere distinguish relative phase, which the probability chart alone cannot reveal.

### $|\Phi^+\rangle$: matching outcomes, equal phase

The basic H-CNOT circuit prepares $|\Phi^+\rangle$. The probability chart contains 50% at $00$ and 50% at $11$. The Q-sphere displays $|00\rangle$ and $|11\rangle$ with the same phase, corresponding to two positive amplitudes.

$$
H_0\rightarrow\operatorname{CNOT}_{0\rightarrow1},\qquad
|\Phi^+\rangle=\frac{|00\rangle+|11\rangle}{\sqrt{2}}.
$$

![IBM Quantum Composer view of Phi-plus](/sections/generic/reference-architectures/quantum_entanglement/20260813/img/phi-plus.png)

*Figure 1. IBM Quantum Composer view of $|\Phi^+\rangle$: outcomes 00 and 11 with equal probability and equal phase.*

### $|\Phi^-\rangle$: matching outcomes, opposite phase

Applying $Z$ to qubit 0 after the H-CNOT block changes the relative sign of the $|11\rangle$ component. The probability chart remains 50% at $00$ and 50% at $11$ because relative phase does not change computational-basis probabilities. The Q-sphere distinguishes $|\Phi^-\rangle$ from $|\Phi^+\rangle$ by showing opposite phases for the two nonzero components.

$$
H_0\rightarrow\operatorname{CNOT}_{0\rightarrow1}\rightarrow Z_0,
\qquad |\Phi^-\rangle=\frac{|00\rangle-|11\rangle}{\sqrt{2}}.
$$

![IBM Quantum Composer view of Phi-minus](/sections/generic/reference-architectures/quantum_entanglement/20260813/img/phi-minus.png)

*Figure 2. IBM Quantum Composer view of $|\Phi^-\rangle$: outcomes 00 and 11 with equal probability and opposite phase.*

### $|\Psi^+\rangle$: opposite outcomes, equal phase

Applying $X$ to qubit 1 after the H-CNOT block converts same-bit correlation into opposite-bit correlation. The probability chart shifts to 50% at $01$ and 50% at $10$. The Q-sphere shows the $|01\rangle$ and $|10\rangle$ components with the same phase.

$$
H_0\rightarrow\operatorname{CNOT}_{0\rightarrow1}\rightarrow X_1,
\qquad |\Psi^+\rangle=\frac{|01\rangle+|10\rangle}{\sqrt{2}}.
$$

![IBM Quantum Composer view of Psi-plus](/sections/generic/reference-architectures/quantum_entanglement/20260813/img/psi-plus.png)

*Figure 3. IBM Quantum Composer view of $|\Psi^+\rangle$: outcomes 01 and 10 with equal probability and equal phase.*

### $|\Psi^-\rangle$: opposite outcomes, opposite phase

Applying $X$ to qubit 1 and $Z$ to qubit 0 after the H-CNOT block prepares $|\Psi^-\rangle$. The probability chart remains 50% at $01$ and 50% at $10$, while the Q-sphere shows opposite phases. As with the two $\Phi$ states, probability alone cannot distinguish the plus and minus versions.

$$
H_0\rightarrow\operatorname{CNOT}_{0\rightarrow1}\rightarrow X_1\rightarrow Z_0,
\qquad |\Psi^-\rangle=\frac{|01\rangle-|10\rangle}{\sqrt{2}}.
$$

![IBM Quantum Composer view of Psi-minus](/sections/generic/reference-architectures/quantum_entanglement/20260813/img/psi-minus.png)

*Figure 4. IBM Quantum Composer view of $|\Psi^-\rangle$: outcomes 01 and 10 with equal probability and opposite phase.*

### What the four screenshots demonstrate

| State | Gates after H-CNOT | Nonzero outcomes | Q-sphere phase relation |
|---|---|---|---|
| $\Phi^+$ | None | 00 and 11 | Equal |
| $\Phi^-$ | $Z_0$ | 00 and 11 | Opposite |
| $\Psi^+$ | $X_1$ | 01 and 10 | Equal |
| $\Psi^-$ | $X_1$ and $Z_0$ | 01 and 10 | Opposite |

The probability charts separate the $\Phi$ family from the $\Psi$ family: $\Phi$ states produce matching computational-basis outcomes, while $\Psi$ states produce opposite outcomes. The Q-spheres separate the plus states from the minus states by revealing relative phase. This is why statevector or phase-sensitive visualization is needed in addition to measurement probabilities.

### Equivalent circuit constructions

These are clean, consistent circuits, but they are not the only valid preparations. Equivalent circuits may move Pauli operations to different positions, initialize another computational-basis state before the H-CNOT block, or differ by a physically irrelevant global phase. The qubit-order convention must always be stated when comparing circuits or statevectors across software packages.

## The Mathematics of $|\Phi^+\rangle$

Begin with two qubits in the product state

$$
|00\rangle=|0\rangle\otimes|0\rangle.
$$

Apply a Hadamard gate to qubit 0:

$$
(H\otimes I)|00\rangle
=\left(\frac{|0\rangle+|1\rangle}{\sqrt{2}}\right)\otimes|0\rangle
=\frac{|00\rangle+|10\rangle}{\sqrt{2}}.
$$

Then apply the CNOT. When the control is 0, the target is unchanged. When the control is 1, the target is flipped:

$$
\operatorname{CNOT}\left(\frac{|00\rangle+|10\rangle}{\sqrt{2}}\right)
=\frac{|00\rangle+|11\rangle}{\sqrt{2}}
=|\Phi^+\rangle.
$$

The final state cannot be written as a tensor product of independent single-qubit pure states. That nonfactorability is the mathematical signature of entanglement for this pure state.

### Amplitude, probability, and phase

Each nonzero Bell-state amplitude has magnitude $1/\sqrt{2}$, and

$$
\left|\frac{1}{\sqrt{2}}\right|^2=\frac{1}{2}.
$$

A negative amplitude does not mean a negative probability. It indicates relative phase, which becomes observable when amplitudes later interfere. The attached probability charts therefore show identical distributions for $\Phi^+$ and $\Phi^-$, and likewise for $\Psi^+$ and $\Psi^-$, while the Q-spheres reveal the phase differences.

### What local measurements see

For $|\Phi^+\rangle$, the reduced state of either individual qubit is maximally mixed:

$$
\rho_0=\rho_1=\frac{I}{2}.
$$

The complete two-qubit state is pure and fully specified, while either qubit considered alone produces an unbiased random result in the computational basis.

## Interpretations versus operational descriptions

The Many-Worlds Interpretation is one interpretation of quantum mechanics, not a separate experimentally confirmed mechanism for quantum computation. Language about spawning universes or correlating universes may be used as metaphor, but it should not replace the operational account based on state preparation, unitary evolution, entanglement, interference, and measurement.

!!! note "Practical framing"  
    Entanglement is a resource, not a speedup certificate. Whether a quantum computation provides an advantage depends on the algorithm, problem structure, hardware errors, resource requirements, measurement strategy, and classical baseline.

## Conclusion

Quantum entanglement is a property of a joint state that cannot be decomposed into independent states for its components. It produces correlations that can violate Bell inequalities while respecting the no-signalling requirement that prevents controllable faster-than-light communication.

The IBM Quantum Composer screenshots make the four Bell states visually distinct. The probability charts identify matching versus opposite computational-basis outcomes, while the Q-spheres expose the relative phase that distinguishes plus from minus states. A common H-CNOT block prepares $|\Phi^+\rangle$, and simple local Pauli operations generate the remaining three states.

In quantum computing, entanglement is most powerful when used with superposition, phase, interference, and carefully designed operations. The goal is not merely to create correlated qubits, but to construct a computation in which those correlations contribute to an answer that can be extracted reliably.