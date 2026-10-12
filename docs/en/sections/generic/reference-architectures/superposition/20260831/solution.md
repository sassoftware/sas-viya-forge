## Many Worlds Example

Now that we have gone through a good explanation of what superposition is, some theories, a little math, and a visualization let's take a look at actually using it. For this example I created a linear equation and solved it in parallel across superposition states. According to the Deutsch-Schrödinger MWI the linear equation is run in parallel across multiple universes. The linear equation to be solved is very simply $y = x^{2} + 1$, because the difficulty of the equation isn't the point here, what matters is that it's solved across superposition. We use a quantum variable $|x\rangle$ that will be in a superposition of all the numbers between 0 and 7. Therefore, the equation will be solved for all values of x between 0 and 7, not sequentially one at a time as conventional computers do, but across quantum superpositional states. We can then think of the quantum variable actually being $|x\rangle = \frac{1}{\sqrt{8}}(|0\rangle + |1\rangle + ... + |7\rangle)$. The expected output is $|x\rangle|y\rangle = |x\rangle|x^{2} + 1\rangle$ where $|x\rangle$ is entangled with $|y\rangle$. Three is the minimum number of qubits to compute with 8 numbers (0–7) in binary: *ceiling(log₂(8)) = 3*. Then we apply a Hadamard gate to all 3 qubits to create superpositions. Finally, we define the equation to solve and initialize the quantum variable y to the equation.   

Below is the quantum circuit that solves this linear equation.  Notice, the Hadamard gate applied to qubits 0–2 to put them into superposition, with the rest of the circuit acting on these superpositions and creating entanglements. In addition to the three qubits storing the *x* values, there are 6 additional auxiliary qubits used for the various calculations such as $x^2$ and $y = x^2 + 1$. There are a total of 9 qubits & 9 classic bits needed to solve this problem. The classical bits are what store the measured quantum information.

![Quantum circuit with Hadamard gates on qubits 0–2 followed by the arithmetic block, using 9 qubits total](/sections/generic/reference-architectures/superposition/20260831/img/circuit.png)

Finally, the circuit is executed to run as a quantum job 1,024 times. Remember all quantum processes need to run multiple times due to the  results being probabilistic.

![Histogram of measurement results showing eight roughly equal bars for x = 0…7 over 1,024 runs](/sections/generic/reference-architectures/superposition/20260831/img/histogram.png)

Each bar represents the solution y for each value of x. For the 1st bar x=0, the 2nd x=1, and so on until x=7. Notice that when we hover over the bar we see both the value of x and y. Recall the binary-to-decimal conversion from earlier — the representation for variable x is $|x\rangle = \frac{1}{\sqrt{8}}(|0\rangle + |1\rangle + ... + |7\rangle)$, and this is simply that conversion. It can also be thought of in binary as $|x\rangle = \frac{1}{\sqrt{8}}(|000\rangle + |001\rangle + ... + |111\rangle)$, hence, all the possible states of 3 qubits; 000, 001, 010, 011, 100, 101, 110, 111. When we add the entanglement with *y* it becomes a quantum system Ψ. Considering both *x* and *y*, the fully expanded final state for the equation becomes

$$
|\psi\rangle = \frac{1}{\sqrt{8}}\big(|0\rangle|1\rangle + |1\rangle|2\rangle + |2\rangle|5\rangle + |3\rangle|10\rangle + |4\rangle|17\rangle + |5\rangle|26\rangle + |6\rangle|37\rangle + |7\rangle|50\rangle\big)
$$

in decimal, or if you want to look at it as binary,

$$
|\psi\rangle = \frac{1}{\sqrt{8}}\big(|000\rangle|000001\rangle + |001\rangle|000010\rangle + |010\rangle|000101\rangle + |011\rangle|001010\rangle + |100\rangle|010001\rangle + |101\rangle|011010\rangle + |110\rangle|100101\rangle + |111\rangle|110010\rangle\big).
$$

| x (binary) | y = x²+1 | y (6-bit binary) | amplitude |
|:----------:|:--------:|:----------------:|:---------:|
| 0 (000) | 1 | 000001 | $1/\sqrt{8}$ |
| 1 (001) | 2 | 000010 | $1/\sqrt{8}$ |
| 2 (010) | 5 | 000101 | $1/\sqrt{8}$ |
| 3 (011) | 10 | 001010 | $1/\sqrt{8}$ |
| 4 (100) | 17 | 010001 | $1/\sqrt{8}$ |
| 5 (101) | 26 | 011010 | $1/\sqrt{8}$ |
| 6 (110) | 37 | 100101 | $1/\sqrt{8}$ |
| 7 (111) | 50 | 110010 | $1/\sqrt{8}$ |

## Conclusion

Quantum superposition is one of the key phenomena that gives quantum computers their potential power. Whether explained through the multiverse, splitting universes, or another interpretation, superposition allows quantum computers to represent and evaluate many possible solutions at once. Whatever the underlying explanation, its computational impact is undeniable.

It is important to note that this example did not solve the equation sequentially for each value of *x*, as a conventional computer would. Instead, it used three qubits in superposition to evaluate all eight values from 0 to 7 in parallel across superpositional states or, from the MWI perspective, across $2^3$, or eight, universes.

