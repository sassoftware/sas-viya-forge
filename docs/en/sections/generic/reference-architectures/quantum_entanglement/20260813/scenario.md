## EPR: Is Quantum Mechanics Complete?

In 1935, Albert Einstein, Boris Podolsky, and Nathan Rosen proposed a thought experiment intended to show that quantum mechanics might be incomplete. Their argument considered two systems prepared with correlated position and momentum and then separated.

Depending on which observable is measured on system A, the corresponding observable for system B can be predicted. EPR assumed locality: a measurement choice made at A should not instantaneously disturb a distant system B. They also proposed a criterion of reality: if a physical quantity can be predicted with certainty without disturbing the system, that quantity corresponds to an element of physical reality.

Under those assumptions, EPR argued that both position and momentum should correspond to elements of reality for system B, even though quantum mechanics does not assign simultaneous definite values to both. Their conclusion was not that an experiment had violated the uncertainty principle. Their conclusion was that the quantum-mechanical description might omit additional variables needed for a complete account.

!!! note "Important distinction"  
    One cannot combine outcomes from incompatible experimental arrangements and claim that both observables were measured precisely on the same particle in the same run. The EPR argument concerns completeness, locality, and counterfactual predictions, not a direct experimental violation of the uncertainty principle.

## Bell's Theorem and Experimental Tests

In 1964, John Bell showed that local hidden-variable models place limits on correlations observed when two separated experimenters choose among different measurement settings. Quantum mechanics predicts correlations that can exceed those limits for suitable entangled states and measurement choices.

### The experiment in one page

- A source prepares an entangled pair and sends one system to Alice and the other to Bob.
- Alice and Bob independently choose one of two measurement settings.
- Each measurement produces one of two outcomes, represented as $+1$ or $-1$.
- After many trials, Alice and Bob compare their records and calculate correlations for each pair of settings.
- A local hidden-variable model must satisfy a Bell inequality. Quantum mechanics predicts a violation for selected settings.

### A standard CHSH form

A widely used Bell inequality is the Clauser-Horne-Shimony-Holt, or CHSH, inequality. Let $E(a,b)$ denote the correlation between Alice's outcome using setting $a$ and Bob's outcome using setting $b$. Define

$$
S=E(a,b)+E(a,b')+E(a',b)-E(a',b').
$$

Local hidden-variable models obey

$$
|S|\le 2.
$$

Quantum mechanics allows values as large as

$$
|S|=2\sqrt{2}.
$$

Repeated Bell tests have observed violations consistent with quantum predictions. The result rules out local hidden-variable explanations under the assumptions used to derive and test the inequality. It does not establish that controllable information travels faster than light, and it does not rule out every possible interpretation or every nonlocal hidden-variable theory.