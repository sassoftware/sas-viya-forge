## Solution overview

### Assumptions

Access to SAS Quantum Lab on Viya  

The SAS Quantum Lab MACROS that will be used for these examples are:  

**%q_init(q,c);**

- Initializes the quantum circuit to a certain number of qubits and classical bits.
- You perform quantum operations on quantum bits and make measurements of the quantum states onto classical bits.

**%q_x(q); or %q_y(q); or %q_z(q);**

- Applies a quantum rotation along the x, y or z axis of a particular qubit.
- An **X gate** rotates a qubit's state by 180° around the X axis of the Bloch sphere. Because this axis runs along the equator, the rotation swaps the two poles: $|0\rangle$ becomes $|1\rangle$ and $|1\rangle$ becomes $|0\rangle$. This makes X the quantum version of the classical NOT gate, and unlike the Z gate, it changes the measurement probabilities in the computational basis. The states on the X axis itself, $|+\rangle$ and $|-\rangle$, are left in place, since they are the eigenstates of X. X leaves $|+\rangle$ unchanged and only multiplies $|-\rangle$ by an overall $-1$, which has no observable effect. In basis encoding, an X gate is applied to each qubit whose bit is 1, which flips it from $|0\rangle$ to $|1\rangle$.
- A **Y gate** rotates a qubit's state by 180° around the Y axis of the Bloch sphere. Like the X axis, the Y axis runs along the equator, so the rotation swaps the two poles: $|0\rangle$ becomes $i|1\rangle$ and $|1\rangle$ becomes $-i|0\rangle$. This means Y flips the bit like an X gate and also adds a phase, so it combines the effects of both X and Z. Like the X gate, it changes the measurement probabilities in the computational basis. The states on the Y axis itself, $|{+i}\rangle$ and $|{-i}\rangle$, are left in place, since they are the eigenstates of Y. Y leaves $|{+i}\rangle$ unchanged and only multiplies $|{-i}\rangle$ by an overall $-1$, which has no observable effect. In angle and dense encoding, the related $R_Y(\theta)$ rotation turns the qubit by a data-dependent angle around this same axis, which sets the probabilities of measuring 0 and 1.
- A **Z gate** rotates a qubit's state by 180° around the Z axis of the Bloch sphere. The two poles of that axis are the computational basis states, $|0\rangle$ and $|1\rangle$, so the rotation leaves them where they are. Z leaves $|0\rangle$ unchanged and only flips the sign (the phase) of $|1\rangle$. As a result, measuring in the computational basis gives the same probabilities before and after the gate. The effect of Z only appears when the qubit is in a superposition, where it changes the relative phase between the $|0\rangle$ and $|1\rangle$ components. For example, it turns $|+\rangle$ into $|-\rangle$.

**%cx(q,q); or %cy(q,q); or %cz(q,q);**

- Controlled gates for different entanglements. Each has a control and target qubit.
- A **CX gate** (also called CNOT) is a two-qubit gate that applies an X gate to a target qubit only when the control qubit is $|1\rangle$. If the control is $|0\rangle$, nothing happens. If the control is $|1\rangle$, the target flips between $|0\rangle$ and $|1\rangle$. In the computational basis, this works like the classical XOR operation: $|a, b\rangle$ becomes $|a, a \oplus b\rangle$. Because it flips the target, CX changes the measurement probabilities in the computational basis. When the control qubit is in a superposition, CX entangles the two qubits. For example, a Hadamard on the control followed by a CX produces the Bell state $\frac{1}{\sqrt{2}}(|00\rangle + |11\rangle)$. In IQP encoding, a pair of CX gates placed around an $R_Z$ rotation builds the ZZ interaction that encodes products of features.
- A **CY gate** is a two-qubit gate that applies a Y gate to a target qubit only when the control qubit is $|1\rangle$. If the control is $|0\rangle$, nothing happens. If the control is $|1\rangle$, the target flips and also picks up a phase: $|10\rangle$ becomes $i|11\rangle$, and $|11\rangle$ becomes $-i|10\rangle$. Like the CX gate, CY flips the target bit, so it changes the measurement probabilities in the computational basis. It differs from CX only in the extra phase that comes from the Y gate. When the control qubit is in a superposition, CY entangles the two qubits, just as CX does.
- A **CZ gate** is a two-qubit gate that applies a Z gate to a target qubit only when the control qubit is $|1\rangle$. The only state it changes is $|11\rangle$, which it multiplies by $-1$; $|00\rangle$, $|01\rangle$ and $|10\rangle$ are left unchanged. Because the effect depends only on both qubits being $|1\rangle$, CZ is symmetric, so it makes no difference which qubit is the control and which is the target. Like the single-qubit Z gate, CZ only changes phase, so the measurement probabilities in the computational basis stay the same. Its effect appears when the qubits are in a superposition, where the relative phase it adds can entangle them. For example, applying CZ to $|{+}{+}\rangle$ produces an entangled state.

**%crx(q,q,theta); or %cry(q,q,theta); or %crz(q,q,theta);**

- Controlled rotation gates that perform entanglements with rotations.

**%q_barrier();**

- Used to separate quantum compilation blocks.  

**%q_measure_all();**

- Measure quantum states onto classical bits.  

**%q_show_circuit();**

- Display the quantum circuit.  

**%q_statevector();**

- Compute the statevector of the circuit.  

### Solution

#### Encoding Methods

There are many ways to encode classical data, and each has its own strengths and limitations. The right choice depends on the problem, the type of data and the quantum hardware modality. This post examines five common methods: basis, amplitude, angle, IQP and dense angle encoding. For each one, we use the SAS Quantum Lab macros to build the circuit, draw it, and display the resulting state vector or expectation values.

##### Basis Encoding

Basis encoding is the simplest method to implement and understand. It maps the binary representation of the data directly onto the computational basis states of the qubits. Each bit becomes one qubit, either |0⟩ or |1⟩. The method can encode a single number or a set of features.

**Single Numbers**

- Decimal 3 = binary 11 → |11⟩
- Decimal 7 = binary 111 → |111⟩

**Multiple Features**

- Variable 1 = decimal 5 = binary 0101
- Variable 2 = decimal 8 = binary 1000
- Variable 3 = decimal 3 = binary 0011

Each value is padded to the bit width of the largest value, which is 4 bits here. The binary strings are then concatenated into 0101 1000 0011 and encoded as the state |010110000011⟩. Encoding these three variables therefore takes 12 qubits.

**Example 1: Encoding a single integer.**

We encode the integer 7. Its binary form, 111, needs three qubits. Three qubits have 2³ = 8 possible basis states, and only |111⟩ has a non-zero amplitude. Every qubit starts in |0⟩, so an X gate (the quantum NOT gate) is applied to each qubit that must be flipped to |1⟩. Here that is all three qubits, giving |111⟩.

```sas
/******************************************************/
/*              Basis Encoding                        */
/******************************************************/
%let data = 5 8 3;
/* w = bits needed for the largest value; nq = total qubits */
data _null_;
    nv = countw("&data", ' ');
    mx = 0;
    do k = 1 to nv;
        mx = max(mx, input(scan("&data", k, ' '), best32.));
    end;
    w = 1;
    do while (2**w <= mx);
        w + 1;
    end;
    call symputx('nv', nv);
    call symputx('w',  w);
    call symputx('nq', nv * w);
run;
%put &=nv &=w &=nq;
data basis_enc;
    %q_init(&nq, &nq);
    length bits $1024;
    /* concatenate each value's w-bit binary string */
    bits = '';
    do k = 1 to &nv;
        v = input(scan("&data", k, ' '), best32.);
        bits = cats(bits, put(v, binary&w..));
    end;
    /* first bit = left-most qubit (n-1-i), same as the Python */
    do i = 1 to &nq;
        if substr(bits, i, 1) = '1' then do;
            q = &nq - i;
            %q_x(q);
        end;
    end;
    %q_barrier();
    %q_measure_all();
run;
title 'Circuit For Basis Encoding';
%q_show_circuit(circuit= basis_enc);
%q_statevector(circuit= basis_enc, out=statevec);
proc print data = statevec noobs label;
label   _state_ = 'Quantum State'
        _amp_real_ = 'Real Amplitude'
        _amp_imag_ = 'Imaging Amplitude'
        _phase_ = 'Phase'
        _probability_ = 'Probability';
title 'State Vector for Basis Encoding';
run;
``` 
!!! note "Circuit Explained"  
    Below is the quantum circuit output. Notice the three X-gates. Qubits are initialized in the zero state, the X-gate flips the state to 1. In this case the binary value of 3 is 111 so the quantum state is |111⟩.

![Circuit for basis encoding of 7](/sections/generic/implementation-guides/q-encoding/20261008/img/fig04_basis_7_circuit.png)  

!!! note "Statevectors Explained"  
    Below is the statevector output. It provides every possible state that three qubits can be in. Since we are encoding the the number 3 100% of the probability is on the qubit combination of 111 or the quantum state |111⟩.

![State vector for basis encoding of 7](/sections/generic/implementation-guides/q-encoding/20261008/img/fig05_basis_7_statevector.png)

Encoding the number 11 works the same way. Its binary form, 1011, needs four qubits. X gates are applied to q3, q1 and q0, and q2 stays in |0⟩. This produces |1011⟩ with probability 1.

![Circuit for basis encoding of 11](/sections/generic/implementation-guides/q-encoding/20261008/img/fig06_basis_11_circuit.png)

![State vector for basis encoding of 11](/sections/generic/implementation-guides/q-encoding/20261008/img/fig07_basis_11_statevector.png)

**Example 2: Encoding multiple features.** Next, we encode the three variables from above: 5 (0101), 8 (1000) and 3 (0011). The combined bit string, 010110000011, needs 12 qubits.

![Circuit for basis encoding of 5, 8, 3](/sections/generic/implementation-guides/q-encoding/20261008/img/fig08_basis_583_circuit.png)

A 12-qubit register has 2¹² = 4,096 possible basis states. X gates appear only on the qubits whose bit is 1 (q10, q8, q7, q1 and q0), which produces |010110000011⟩. The full state vector would list all 4,096 states, so the printed output is filtered to `_probability_ ne 0`. Only the encoded state remains, with probability 1.

![Filtered state vector for basis encoding of 5, 8, 3](/sections/generic/implementation-guides/q-encoding/20261008/img/fig09_basis_583_statevector.png)

Basis encoding is limited to non-negative integers, and the qubit count grows with both the number of features and their bit width.

##### Amplitude Encoding

Amplitude encoding stores a vector of 2ⁿ values in the amplitudes of an n-qubit state. Every quantum system is described by a wave function ψ, and the squared magnitudes of its amplitudes give the measurement probabilities. Because the data is stored in the amplitudes themselves, a dataset of M samples with N features each needs only

$$
n = \log_2(NM)
$$

qubits. This exponential compression is the method's main advantage. The amplitudes must satisfy the Born rule, which says the squared magnitudes sum to 1:

$$
|\alpha_1|^2 + |\alpha_2|^2 + |\alpha_3|^2 + \dots + |\alpha_N|^2 = 1
$$

The data must therefore be normalized. For our three variables (5, 8, 3), the normalization factor is

$$
\frac{1}{\sqrt{5^2 + 8^2 + 3^2}} = \frac{1}{\sqrt{98}} = 0.10102
$$

Multiplying each value by this factor gives (0.50508, 0.80812, 0.30305). The length of the vector must also be a power of 2, so a zero amplitude is added as padding. The four amplitudes fit on 2 qubits:

| Variable | Amplitude | Basis state |
|---|---|---|
| Var 1 | 0.5051 | \|00⟩ |
| Var 2 | 0.8081 | \|01⟩ |
| Var 3 | 0.3030 | \|10⟩ |
| Padding | 0.0000 | \|11⟩ |


```sas
/******************************************************/
/*              Amplitude Encoding                    */
/******************************************************/
%let data = 5 8 3;
data _null_;
    n = countw("&data", ' ');
    w = 1;                        /* minimum 1 qubit */
    do while (2**w < n);
        w + 1;
    end;
    call symputx('w', w);
run;
%put &=w;
data amp_enc;
    %q_init(&w, &w);
    /* vec = np.zeros(2**n_qubits); vec[:len(data)] = data */
    array v[0:%eval(2**&w - 1)] _temporary_;
    do k = 0 to %eval(2**&w - 1);
        v[k] = 0;
    end;
    do k = 1 to countw("&data", ' ');
        v[k-1] = input(scan("&data", k, ' '), best32.);
    end;
    /* vec = vec / np.linalg.norm(vec) */
    norm = 0;
    do k = 0 to %eval(2**&w - 1);
        norm + v[k]**2;
    end;
    norm = sqrt(norm);
    do k = 0 to %eval(2**&w - 1);
        v[k] = v[k] / norm;
    end;
    /* rotation angles (Qiskit order: index = q1 q0, q1 = MSB) */
    theta_top = 2*arcos(sqrt(v[0]**2 + v[1]**2));      /* split on q1      */
    if v[0]=0 and v[1]=0 then theta_0 = 0;
    else theta_0 = 2*atan2(v[1], v[0]);                /* q0 when q1 = |0> */
    if v[2]=0 and v[3]=0 then theta_1 = 0;
    else theta_1 = 2*atan2(v[3], v[2]);                /* q0 when q1 = |1> */
    /* qc.prepare_state(vec, range(n_qubits)) */
    %q_ry(1, theta_top);
    %q_x(1);                        /* control on q1 = |0> */
    %q_cry(1, 0, theta_0);          /* control, target, angle */
    %q_x(1);
    %q_cry(1, 0, theta_1);          /* control on q1 = |1> */
    %q_barrier();
    %q_measure_all();
run;
title 'Circuit for Amplitude Encoding';
%q_show_circuit(circuit=amp_enc);
%q_statevector(circuit=amp_enc, out=statevec);
proc print data = statevec noobs label;
label   _state_ = 'Quantum State'
        _amp_real_ = 'Real Amplitude'
        _amp_imag_ = 'Imaging Amplitude'
        _phase_ = 'Phase'
        _probability_ = 'Probability';
title 'State Vector for Amplitude Encoding';
run;
```

The SAS Quantum Lab prepares this state in three steps:

- Zero-pad the data vector to length 2ⁿ, then normalize it.
- Compute the rotation angles from the normalized amplitudes. The two non-trivial angles, 0.616 and 2.02 radians, appear in the circuit. The third is 0 because both of its amplitudes are zero.
- Apply one RY gate and two controlled-RY gates to set the amplitudes.

![Circuit for amplitude encoding](/sections/generic/implementation-guides/q-encoding/20261008/img/fig10_amplitude_circuit.png)

![State vector for amplitude encoding](/sections/generic/implementation-guides/q-encoding/20261008/img/fig11_amplitude_statevector.png)

The state vector shows the expected amplitudes: 0.505|00⟩, 0.808|01⟩, 0.303|10⟩ and 0|11⟩. Their probabilities are 0.255, 0.653, 0.092 and 0, and they sum to 1.

##### Angle Encoding

Angle encoding maps each feature to a rotation angle on its own qubit, so N features need n = N qubits. Each feature is applied as a rotation about the X, Y or Z axis, and the choice of axis depends on the data and the algorithm. In variational algorithms, these rotations are often starting values that are refined iteratively as the model minimizes its cost function. Each qubit is encoded independently, so the final state is the Kronecker (tensor) product of the individual qubit states.

```sas
/******************************************************/
/*                   Angle Encoding                   */
/******************************************************/
%let rotation = X;           /* X, Y, or Z */
%let data     = 5 8 3;
%let n        = %sysfunc(countw(&data, %str( )));
%let rmac     = q_r%lowcase(&rotation);   /* q_rx, q_ry, or q_rz */
data angle_enc;
    %q_init(&n, &n);
    do i = 1 to &n;
        x = input(scan("&data", i, ' '), best32.);
        q = &n - i;               /* equivalent to n - 1 - i (i is 1-based here) */
        %&rmac(q, x);             /* qubit first, then angle */
    end;
    %q_barrier();
    %q_measure_all();
run;
title 'Circuit for Angle Encoding';
%q_show_circuit(circuit=angle_enc);
%q_statevector(circuit=angle_enc, out=statevec);
proc print data = statevec noobs label;
label   _state_ = 'Quantum State'
        _amp_real_ = 'Real Amplitude'
        _amp_imag_ = 'Imaging Amplitude'
        _phase_ = 'Phase'
        _probability_ = 'Probability';
title 'State Vector for Angle Encoding';
run;
```

The circuit applies RX(5), RX(8) and RX(3) to qubits q2, q1 and q0. The state vector is the tensor product of the three rotated qubits.

![Circuit for angle encoding](/sections/generic/implementation-guides/q-encoding/20261008/img/fig12_angle_circuit.png)

![State vector for angle encoding](/sections/generic/implementation-guides/q-encoding/20261008/img/fig13_angle_statevector.png)

To show how the tensor product is formed, we can run the same code on each variable by itself (5, then 8, then 3). Each run uses a single qubit.

**For Var1 = 5**

![Angle encoding of 5](/sections/generic/implementation-guides/q-encoding/20261008/img/fig14_angle_var1.png)

**For Var2 = 8**

![Angle encoding of 8](/sections/generic/implementation-guides/q-encoding/20261008/img/fig15_angle_var2.png)

**For Var3 = 3**

![Angle encoding of 3](/sections/generic/implementation-guides/q-encoding/20261008/img/fig16_angle_var3.png)

We can check these results independently by applying the RX(θ) matrix to |0⟩:

$$
R_X(\theta)\,|0\rangle = \cos\left(\frac{\theta}{2}\right)|0\rangle - i\,\sin\left(\frac{\theta}{2}\right)|1\rangle
$$

The NumPy calculations below reproduce each single-qubit state. Taking the Kronecker product of the three single-qubit states gives the full 3-qubit state. It matches the SAS state vector exactly. These calculations use rotations about the X axis. To use the Y or Z axis instead, change the rotation macro variable to Y or Z. Angles such as 5 and 8 radians are larger than 2π, so they wrap around the Bloch sphere. In practice, features are usually scaled to the range [0, π] before encoding, so that distinct values map to distinct states.

**For Var1 = 5**

```python
a = np.array([[np.cos(5/2), -1j*np.sin(5/2)],[-1j*np.sin(5/2),np.cos(5/2)]]).dot([1,0])
# [-0.80114362+0.j          0.        -0.59847214j]
```

**For Var2 = 8**

```python
b = np.array([[np.cos(8/2), -1j*np.sin(8/2)],[-1j*np.sin(8/2),np.cos(8/2)]]).dot([1,0])
# [-0.65364362+0.j         0.        +0.7568025j]
```

**For Var3 = 3**

```python
c = array([[np.cos(3/2), -1j*np.sin(3/2)],[-1j*np.sin(3/2),np.cos(3/2)]]).dot([1,0])
# [0.0707372+0.j         0.       -0.99749499j]
```

Then we can take the Kronecker (Tensor) product of these to get the final state

```python
np.kron(np.kron(a, b), c)
# [ 0.03704241+0.j          0.        -0.52235063j  0.        -0.0428885j
#  -0.60478868+0.j          0.        +0.02767151j  0.39020757+0.j
#   0.03203866+0.j          0.        -0.45179063j]
```

##### Instantaneous Quantum Polynomial Encoding (IQP)

IQP encoding first applies a Hadamard gate to every qubit. This moves each qubit from the computational basis into the |+⟩/|−⟩ basis, an equal superposition of |0⟩ and |1⟩. Each feature is then encoded with an RZ rotation on its qubit. Finally, two-qubit RZZ gates are applied to each pair of qubits, with angles equal to the product of the two features. Because these gates entangle the qubits based on products of features, IQP encoding is well suited to problems where interactions between features matter.

```sas
/******************************************************/
/*                      IQP Encoding                  */
/******************************************************/
%let data      = 5 8 3;
%let n_repeats = 2;
%let pattern   = ;     /* blank = all pairs; else e.g. 0:1 1:2 */
%let n         = %sysfunc(countw(&data, %str( )));
/* Default pattern = all (i,j) pairs with i < j */
data _null_;
    length pat $32767;
    pat = symget('pattern');
    if pat = ' ' then
        do i = 0 to &n - 2;
            do j = i + 1 to &n - 1;
                pat = catx(' ', pat, cats(i, ':', j));
            end;
        end;
    call symputx('pattern', pat);
run;
data iqp_enc;
    %q_init(&n, &n);
    array x[0:%eval(&n - 1)] _temporary_;
    do i = 0 to &n - 1;
        x[i] = input(scan("&data", i + 1, ' '), best32.);
    end;
    do r = 1 to &n_repeats;
        do i = 0 to &n - 1;                       /* qc.h(n-1-i) */
            q = &n - 1 - i;
            %q_h(q);
        end;
        do i = 0 to &n - 1;                       /* qc.rz(data[i], n-1-i) */
            q = &n - 1 - i;
            theta = x[i];
            %q_rz(q, theta);
        end;
        do p = 1 to countw("&pattern", ' ');      /* qc.rzz(data[i]*data[j], ...) */
            i = input(scan(scan("&pattern", p, ' '), 1, ':'), 8.);
            j = input(scan(scan("&pattern", p, ' '), 2, ':'), 8.);
            a = &n - 1 - i;
            b = &n - 1 - j;
            theta = x[i] * x[j];
            %q_cx(a, b);                          /* RZZ(theta) = CX . RZ(theta) . CX */
            %q_rz(b, theta);
            %q_cx(a, b);
        end;
    end;
    %q_barrier();
    %q_measure_all();
run;
title 'Circuit for IQP Encoding';
%q_show_circuit(circuit=iqp_enc);
/* z_expvals: one Z per feature, in feature order (ZII, IZI, IIZ for n=3) */
data _null_;
    length plist $32767 s $200;
    do i = 1 to &n;
        s = repeat('I', &n - 1);
        substr(s, i, 1) = 'Z';
        plist = catx(' ', plist, s);
    end;
    call symputx('paulis', plist);
run;
%q_observe(circuit=iqp_enc, paulis=&paulis, out=zvals, detail=1);
proc print data=zvals noobs label;
    label   _pauli_ = 'Pauli Observables'
            _coefficient_ = 'Coefficient'
            _expectation_ = 'Expectation Value'
            _weighted_ = 'Weighted Expectation Value';
title 'Pauli Observables and Expectation Values';
run;
%q_statevector(circuit=iqp_enc, out=statevec);
proc print data = statevec noobs label;
label   _state_ = 'Quantum State'
        _amp_real_ = 'Real Amplitude'
        _amp_imag_ = 'Imaging Amplitude'
        _phase_ = 'Phase'
        _probability_ = 'Probability';
title 'State Vector for IQP Encoding';
run;
```

The SAS macros build each RZZ(θ) gate as the sequence CX · RZ(θ) · CX, which is mathematically identical. That is why the circuit diagram shows CNOT–RZ–CNOT blocks rather than a single RZZ gate. The RZ angles inside those blocks, 40, 15 and 24, are the feature products 5×8, 5×3 and 8×3. Because the RZZ angles are products of features, they grow quickly. Here they reach 40 radians, which wraps around the Bloch sphere more than six times. In practice, features are usually scaled to a small range such as [0, π] or [−1, 1] before encoding, so that the product terms stay meaningful and distinct.

**n_repeats = 1**

![Circuit for IQP encoding, one repetition](/sections/generic/implementation-guides/q-encoding/20261008/img/fig17_iqp_r1_circuit.png)

![Expectation values for IQP encoding, one repetition](/sections/generic/implementation-guides/q-encoding/20261008/img/fig18_iqp_r1_expectations.png)

![State vector for IQP encoding, one repetition](/sections/generic/implementation-guides/q-encoding/20261008/img/fig19_iqp_r1_statevector.png)

!!! note "What Are Expectation Values?"  
    An expectation value is the average result you would get from measuring an observable on a quantum state many times. Mathematically, it is $\langle \psi | O | \psi \rangle$, where $|\psi\rangle$ is the state and $O$ is the observable. For a Pauli-Z measurement on a single qubit, the expectation value ranges from $+1$ (the qubit is definitely in $|0\rangle$) to $-1$ (definitely in $|1\rangle$). A value near $0$ means an equal superposition. In an encoding workflow, expectation values of operators such as ZII, IZI and IIZ show how the encoded data shows up in each qubit. They are also the usual outputs passed to classical models in hybrid quantum-classical algorithms. Values like 1.6E-16 come from floating-point rounding and should be read as zero.

IQP results are usually reported as expectation values rather than raw state vectors, because entanglement makes individual amplitudes difficult to interpret. With a single repetition, every ⟨Z⟩ expectation value is zero, apart from floating-point round-off of about 10⁻¹⁶. This is expected. Every gate after the Hadamard layer is diagonal in the computational basis, so it changes only the phases of the amplitudes, not their magnitudes. The state vector confirms this: all eight basis states have probability 0.125, and the data appears only in the phases. Increasing the number of repetitions (n_repeats = 2) inserts another Hadamard layer that converts these phase differences into measurable changes in the probabilities and expectation values.

**n_repeats = 2**

![Circuit for IQP encoding, two repetitions](/sections/generic/implementation-guides/q-encoding/20261008/img/fig20_iqp_r2_circuit.png)

![Expectation values for IQP encoding, two repetitions](/sections/generic/implementation-guides/q-encoding/20261008/img/fig21_iqp_r2_expectations.png)

![State vector for IQP encoding, two repetitions](/sections/generic/implementation-guides/q-encoding/20261008/img/fig22_iqp_r2_statevector.png)

##### Dense Encoding

Dense angle encoding extends angle encoding by placing two features on each qubit instead of one. The first feature of each pair sets an RY rotation, which tilts the qubit away from the z-axis. The second sets an RZ rotation, which rotates it around the z-axis. A qubit's position on the Bloch sphere is described by two angles, so both can carry data. N features therefore need only ⌈N/2⌉ qubits, half as many as standard angle encoding.

Using the same three variables, the data is padded with a zero to give an even number of features: (5, 8, 3, 0). The features are then paired. (5, 8) is encoded on qubit q1 and (3, 0) on qubit q0, so only two qubits are needed. The circuit shows an RY gate followed by an RZ gate on each qubit.

```sas
/******************************************************/
/*          Dense Encoding                            */
/******************************************************/
%let data = 5 8 3;
/* number of qubits = ceil(features / 2), computed from the data */
data _null_;
    nf = countw("&data", ' ');
    call symputx('nf', nf);
    call symputx('n', ceil(nf / 2));
run;
%put &=nf &=n;
data dense_enc;
    %q_init(&n, &n);
    array x[0:%eval(2*&n - 1)] _temporary_;
    do i = 0 to 2*&n - 1;
        x[i] = 0;                                   /* zero-pad odd length */
    end;
    do i = 0 to &nf - 1;
        x[i] = input(scan("&data", i + 1, ' '), best32.);
    end;
    do k = 0 to &n - 1;
        q = &n - 1 - k;
        a = x[2*k];
        b = x[2*k + 1];
        %q_ry(q, a);                                /* feature 2k   */
        %q_rz(q, b);                                /* feature 2k+1 */
    end;
    %q_barrier();
    %q_measure_all();
run;
title 'Circuit for Dense Encoding';
%q_show_circuit(circuit=dense_enc);
/* X, Y, Z on each qubit, in feature-pair order */
data _null_;
    length plist $32767 s $200;
    do k = 1 to &n;
        do p = 'X', 'Y', 'Z';
            s = repeat('I', &n - 1);
            substr(s, k, 1) = p;
            plist = catx(' ', plist, s);
        end;
    end;
    call symputx('paulis', plist);
run;
%q_observe(circuit=dense_enc, paulis=&paulis, out=dense_vals, detail=1);
proc print data=dense_vals noobs label;
    label   _pauli_ = 'Pauli Observables'
            _coefficient_ = 'Coefficient'
            _expectation_ = 'Expectation Value'
            _weighted_ = 'Weighted Expectation Value';
title 'Pauli Observables and Expectation Values';
run;
%q_statevector(circuit=dense_enc, out=statevec);
proc print data = statevec noobs label;
label   _state_ = 'Quantum State'
        _amp_real_ = 'Real Amplitude'
        _amp_imag_ = 'Imaging Amplitude'
        _phase_ = 'Phase'
        _probability_ = 'Probability';
title 'State Vector for Dense Encoding';
run;
```
!!! note "Circuit Explained"  
    Below is the quantum circuit output. Notice that 4 values are being encoded onto two qubits using rotations on different axes.

![Circuit for dense encoding](/sections/generic/implementation-guides/q-encoding/20261008/img/fig23_dense_circuit.png)

![Expectation values for dense encoding](/sections/generic/implementation-guides/q-encoding/20261008/img/fig24_dense_expectations.png)

![State vector for dense encoding](/sections/generic/implementation-guides/q-encoding/20261008/img/fig25_dense_statevector.png)

Each qubit is encoded independently, so its expectation values can be calculated directly. For an RY angle *a* and an RZ angle *b*:

$$
\langle X\rangle = \sin a \cos b, \qquad \langle Y\rangle = \sin a \sin b, \qquad \langle Z\rangle = \cos a
$$

For q1 (a = 5, b = 8), this gives ⟨X⟩ = 0.1395, ⟨Y⟩ = −0.9487 and ⟨Z⟩ = 0.2837. For q0 (a = 3, b = 0), it gives ⟨X⟩ = 0.1411, ⟨Y⟩ = 0 and ⟨Z⟩ = −0.9900. These values match the SAS output exactly. ⟨Z⟩ depends only on the RY feature, and the RZ feature can be seen only through ⟨X⟩ and ⟨Y⟩. This is why all three Pauli observables are measured. ⟨Y⟩ on q0 is zero because the padded feature is 0.

The state vector shows the same encoding as measurement probabilities. The probability of measuring q1 in |0⟩ is cos²(5/2) = 0.642, and the probability of measuring q0 in |1⟩ is sin²(3/2) = 0.995. Their product, 0.639, is the probability of |01⟩, the most likely outcome. The RZ rotations do not change any probabilities. They affect only the phases (−0.858 and −2.283 radians), which is another reason expectation values are the more informative output for this encoding.

The trade-off is that the two features on a qubit share a single quantum state. The encoding is more compact, but the features are less independent than when each one has its own qubit. As with angle encoding, features are usually scaled to [0, π] before encoding. This matters especially for the RY feature: ⟨Z⟩ = cos a repeats every 2π, so unscaled values such as 5 and 8 radians can map different inputs to the same expectation value.

#### Qubits vs. Data Size (Big-O)

In the table, *N* is the number of features, *b* is the number of bits per value, and *r* is the number of IQP repetitions.

| Encoding | Qubits | Big-O (qubits) | Gate count / depth | Example (5, 8, 3) |
|---|---|---|---|---|
| Basis | N·b, where b = ⌈log₂(max+1)⌉ | O(N·b) | O(N·b) X gates, depth 1 | 12 |
| Amplitude | ⌈log₂ N⌉ | O(log N) | O(N) gates for general state preparation | 2 |
| Angle | N | O(N) | O(N), depth 1 | 3 |
| Dense angle | ⌈N/2⌉ | O(N), half the qubits of angle encoding | O(N), depth 2 | 2 |
| IQP (all pairs) | N | O(N) | O(r·N²), with N(N−1)/2 RZZ gates per repeat | 3 (3 RZZ) |

## Conclusion

Encoding is the essential first step in processing classical data on a quantum computer, and it underpins applications in quantum machine learning, quantum AI and quantum chemistry. This post covered five widely used methods: basis, amplitude, angle, IQP and dense angle encoding. Many other schemes exist, and designing effective encodings is an active area of research.

The methods differ mainly in how they trade qubits against circuit depth. Amplitude encoding is the only one that needs exponentially fewer qubits than features, but that comes at the cost of a deeper state-preparation circuit of roughly O(N) gates. Basis, angle and dense angle encoding use a number of qubits that grows linearly with the data, but their circuits are shallow and have constant depth. IQP encoding uses as many qubits as angle encoding and adds O(N²) entangling gates to capture interactions between pairs of features. The best choice depends on the hardware available and on how much the problem depends on those interactions.