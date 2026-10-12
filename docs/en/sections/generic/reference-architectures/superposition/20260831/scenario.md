## Many Worlds
From a philosophical perspective, any discussion of quantum superposition quickly leads to the Many Worlds Interpretation (MWI), often credited to Hugh Everett in the mid-1950s. Everett, however, was apparently unaware that Erwin Schrödinger had proposed a similar idea a decade earlier. Both approaches aimed to **avoid the idea of a collapsing wave function**. Schrödinger's wave equations contain no collapse; that concept was introduced by Niels Bohr to explain why observers see only one outcome rather than a mixture of possibilities. By definition, collapse destroys the superposition. Everett and Schrödinger argued that detecting only one outcome does not mean the alternatives cease to exist. Schrödinger called collapse "*patently absurd*" in a 1952 paper, emphasizing the "*ridiculousness of expecting a quantum superposition to collapse just because it was observed*."

This brings us to Schrödinger's Cat. In the thought experiment, a cat, a flask of poison, and a radioactive source are sealed in a box. If a detector senses radioactive decay, the flask breaks, releasing the poison and killing the cat. From outside the box, the observer cannot know whether the cat is alive or dead until the box is opened. In Bohr's collapse view, the cat remains in a superposition of alive and dead until observation collapses the wave function into one result. In Schrödinger's view, there are two parallel worlds: in one, the cat lives; in the other, the cat dies. When the box is opened, each world observes its own outcome. **The two worlds were identical until the device determined the cat's fate**. These outcomes are not alternatives; they occur simultaneously. The theory gained wider attention only much later.

Hugh Everett later developed his own version of MWI, replacing parallel universes with the idea of "splitting universes." In Everett's model, the cat begins in a single universe in a superposition of alive and dead. When observed, that universe splits into one where the cat is alive and another where the cat is dead. Every quantum "decision" point creates additional universes.

In the 1970s, David Deutsch revived Schrödinger's version of MWI. In the Deutsch-Schrödinger view, an infinite number of universes — the multiverse — corresponds to all possible solutions to the wave function. Returning to the cat example, many identical universes contain identical researchers running the same experiment. These universes remain identical until the device is triggered; in some, the cat dies, and in others, it lives, after which their histories diverge. Deutsch also argued that universes can briefly interact or interfere before that interaction is suppressed as they evolve, producing observable effects in experiments such as the double-slit experiment.

Whether framed as parallel worlds, splitting universes, or Deutsch's interacting multiverse, each interpretation shares the same central claim: in superposition, multiple outcomes genuinely coexist until measurement. Quantum computers are designed to exploit that principle.

## Superposition in Quantum Computing

!!! quote  "*Quantum computation is… a distinctively new way of harnessing nature… It will be the first technology that allows useful tasks to be performed in collaboration between parallel universes.* ~ David Deutsch"

Most articles on quantum computing introduce superposition by comparing bits and qubits: a classical bit is either 0 or 1, while a qubit can be in a superposition of both. The key consequence is that each added qubit doubles the number of states the system can represent at once. This growth is exponential, not linear. Three qubits, for example, can represent $2^3$, or eight, states simultaneously: 000, 001, 010, 011, 100, 101, 110, and 111. That exponential scaling is where the power begins: 10 qubits can represent $2^{10}$, or 1,024, states at once, and 300 qubits could represent more simultaneous states than there are atoms in the known universe.

Deutsch theorized that quantum computations run simultaneously on identical quantum computers across the parallel universes associated with superposition. In the three-qubit example, that corresponds to eight versions of quantum scientists working on the same problem across eight parallel universes.

## Perspective

Dr. Spyridon Michalakis has talked about these multiple universes as being accessible through changes in perspective. For example, consider the following illustration. In the 1st universe, $|1\rangle$ is pointing up and $|0\rangle$ is horizontal with a superposition at a 45° angle between the two. If we change our perspective 45° now the superposition is vertical, and the 45° angle is $|1\rangle$ or $|0\rangle$. By rotating the perspective, you are in a sense changing from one universe to another (creating new ones or collapsing into one).

![Changing of Perspectives](/sections/generic/reference-architectures/superposition/20260831/img/perspectives.png)

We can show this also mathematically. Our first example uses Dirac notation. Let's start with a single qubit $|0\rangle$ and we change the perspective,

$$|0\rangle \rightarrow \frac{|0\rangle + |1\rangle}{\sqrt{2}}.$$

We divide by the $\sqrt{2}$ to show the 50%–50% probability. We can add another qubit ${|0\rangle}_{1} \otimes {|0\rangle}_{2}$ and then change the perspective again,

$$
{|0\rangle}_{1} \otimes {|0\rangle}_{2} \rightarrow \frac{(|0\rangle + |1\rangle)_{1} \otimes (|0\rangle + |1\rangle)_{2}}{2}.
$$

We can then expand this tensoring out and we get

$$
\frac{(|0\rangle + |1\rangle)_{1} \otimes (|0\rangle + |1\rangle)_{2}}{2} = \frac{|0\rangle_{1} \otimes |0\rangle_{2} + |0\rangle_{1} \otimes |1\rangle_{2} + |1\rangle_{1} \otimes |0\rangle_{2} + |1\rangle_{1} \otimes |1\rangle_{2}}{2}
$$

or written clearer as a superposition of

$$
\frac{|0_{1}0_{2}\rangle + |0_{1}1_{2}\rangle + |1_{1}0_{2}\rangle + |1_{1}1_{2}\rangle}{2}
$$

with 4 simultaneous quantum states 00, 01, 10, 11 from a 2 qubit superposition.

To further illustrate we can use vectors and matrices. Recall from an earlier blog that the vector representation of an initialized qubit is $|0\rangle = \begin{bmatrix} 1 \\ 0 \end{bmatrix}$, meaning 100% $|0\rangle$ and 0% $|1\rangle$. A Hadamard gate is used to create a superposition of the qubit and its unitary matrix is $\frac{1}{\sqrt{2}}\begin{bmatrix} 1 & 1 \\ 1 & -1 \end{bmatrix}$. If we apply the Hadamard gate to each qubit we would perform

$$
\frac{1}{\sqrt{2}}\begin{bmatrix} 1 & 1 \\ 1 & -1 \end{bmatrix}\begin{bmatrix} 1 \\ 0 \end{bmatrix} = \begin{bmatrix} \frac{1}{\sqrt{2}} \\ \frac{1}{\sqrt{2}} \end{bmatrix}
$$

twice, once for each qubit. We start off with a qubit 100% in the $|0\rangle$ and end with a qubit 50% in $|0\rangle$ and 50% $|1\rangle$. Now if we were to tensor these two together we get

$$
\begin{bmatrix} \frac{1}{\sqrt{2}} \\ \frac{1}{\sqrt{2}} \end{bmatrix} \otimes \begin{bmatrix} \frac{1}{\sqrt{2}} \\ \frac{1}{\sqrt{2}} \end{bmatrix} = \frac{1}{2}\begin{bmatrix} 1 \\ 1 \\ 1 \\ 1 \end{bmatrix},
$$

where the 1st entry in the column vector corresponds to 00, the 2nd 01, the 3rd 10 and the 4th 11. We can also do this the opposite way by tensoring the two Hadamard gates together, then tensoring the two qubits together and finally multiplying the combined gates and qubits. Tensoring the Hadamard gate together we arrive at

$$
\frac{1}{\sqrt{2}}\begin{bmatrix} 1 & 1 \\ 1 & -1 \end{bmatrix} \otimes \frac{1}{\sqrt{2}}\begin{bmatrix} 1 & 1 \\ 1 & -1 \end{bmatrix} = \frac{1}{2}\begin{bmatrix} 1 & 1 & 1 & 1 \\ 1 & -1 & 1 & -1 \\ 1 & 1 & -1 & -1 \\ 1 & -1 & -1 & 1 \end{bmatrix}.
$$

Then tensoring the two qubits results in

$$
\begin{bmatrix} 1 \\ 0 \end{bmatrix} \otimes \begin{bmatrix} 1 \\ 0 \end{bmatrix} = \begin{bmatrix} 1 \\ 0 \\ 0 \\ 0 \end{bmatrix},
$$

notice that 100% is for $|00\rangle$ because we have not applied the Hadamard gate yet. When we multiply the tensored Hadamard gates with the tensored qubits we get

$$
\frac{1}{2}\begin{bmatrix} 1 & 1 & 1 & 1 \\ 1 & -1 & 1 & -1 \\ 1 & 1 & -1 & -1 \\ 1 & -1 & -1 & 1 \end{bmatrix}\begin{bmatrix} 1 \\ 0 \\ 0 \\ 0 \end{bmatrix} = \frac{1}{2}\begin{bmatrix} 1 \\ 1 \\ 1 \\ 1 \end{bmatrix},
$$

same as above. The multiplier of $\frac{1}{2}$ is computed as $\frac{1}{2} = \frac{1}{2^{\frac{n}{2}}} = \frac{1}{2^{\frac{2}{2}}}$, where *n* is the number of qubits. For this example n=2 qubits. Our possible values are $|00\rangle + |01\rangle + |10\rangle + |11\rangle$ and converted to decimal $|0\rangle + |1\rangle + |2\rangle + |3\rangle$, which will be important further on in this post when we perform some quantum calculations.

With the math out of the way, let's illustrate some real qubits. When you place an initialized qubit into superposition this changing of perspective is what happens. When we initialize a qubit it's typically initialized in the $|0\rangle$ state which is also on the z-axis of the Bloch Sphere and this basis is called the computational basis, north is $|0\rangle$ and south is $|1\rangle$. Bloch Spheres are important tools used to visualize a qubit. We create a superposition by applying a Hadamard gate to the qubit. This changes the basis from the computational basis to the Hadamard basis ($|+\rangle$ and $|-\rangle$) with an equal probability of the computational basis being $0.707|0\rangle + 0.707|1\rangle$ which is the same as $\frac{1}{\sqrt{2}}|0\rangle + \frac{1}{\sqrt{2}}|1\rangle$, which is the same as $\frac{|0\rangle + |1\rangle}{\sqrt{2}}$. You square $0.707^2 = 0.50$ or $\left(\frac{1}{\sqrt{2}}\right)^{2} = \frac{1}{2}$. Because the qubit is measuring complex amplitudes the amplitudes are normalized and squared in order to get the probabilities. The images below are the visual representations of the qubits using the Bloch Spheres. The qubit on the left is initialized to $|0\rangle$. The qubit on the right has applied a Hadamard gate to change basis and end up in the $|+\rangle$ state with an equal superposition on the computational basis. Notice how we have changed the frame references from the z-axis or computational basis to the x-axis or the Hadamard basis.

![Bloch sphere of a qubit initialized to |0⟩, pointing to the north pole](/sections/generic/reference-architectures/superposition/20260831/img/bloch-qubit0.png){ width="35%" }
![Bloch sphere after a Hadamard gate, pointing along the x-axis into the |+⟩ state](/sections/generic/reference-architectures/superposition/20260831/img/bloch-hadamard.png){ width="35%" }