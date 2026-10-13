## Solution overview

This guide uses a blue-green approach to upgrade Python environments managed by SAS Configurator for Open Source (sas-pyconfig):

- **Blue** is the current, fully pinned profile that production workloads use today.
- **Green** is the new profile that contains the upgraded Python version or packages.

You build the green profile alongside the blue profile, validate it, and then move each runtime to it one at a time. The blue profile stays installed and unchanged, so you roll back by pointing a runtime back to blue.

SAS Compute (for example, from SAS Data and AI Studio) and SAS Model Studio select their Python environment through a path setting, so you can test the green profile before production workloads use it. CAS and MAS support only one Python environment at a time and must be restarted to use a new one. For CAS and MAS, you pre-validate in SAS Compute as fully as possible, record baseline results on blue, and then cut over and test during a planned change window.

The upgrade has four phases:

1. Prepare
2. Dry run
3. Compatibility testing and cutover
4. Rollback (if needed)

### Assumptions

- SAS Viya is deployed, and sas-pyconfig is enabled and already manages at least one Python profile.
- You have the administrative access needed to change the sas-pyconfig configuration, run the sas-pyconfig job, set SAS Viya environment variables, edit the CAS `extlang.xml` configuration within Kubernetes, and restart CAS and MAS.
- The SAS Viya deployment can reach the package repository used to install Python packages.
- [uv](https://docs.astral.sh/uv/) is installed on the workstation where you resolve the new environment definition.
- The current (blue) profile is fully pinned, with every package listed at an exact version, so rerunning the sas-pyconfig job does not change it.
- You have a test suite of representative programs, models, forecasts, and decision flows, plus representative data for comparing results.
- You have an inventory of the programs, models, forecasts, and decision flows that use each Python profile.
- If you use separate development and production SAS Viya deployments, both run the same SAS Viya version.
- A change window is available for the CAS and MAS restarts.

### Solution

#### Phase 1: Prepare

1. **Record the current state.** Save the pinned package list, Python version, and sas-pyconfig configuration for the blue profile in version control. This is your rollback reference.
2. **Identify affected assets.** Use your inventory to list every program, model, forecast, and decision flow that depends on the blue profile, along with the runtime each one uses.
3. **Choose a test location.** If you have a development SAS Viya deployment, do all testing there first. Otherwise, you must test in production with the green profile while production workloads stay on blue.

#### Phase 2: Dry run

A dry run confirms that the new environment resolves, can be built in SAS Viya, and installs successfully before any workload uses it. Two conditions must both be met:

- **Dependency resolution:** All Python packages must be compatible with each other.
- **Operating system dependencies:** Any operating system libraries the packages need must be available in SAS Viya.

A dependency set that resolves on your workstation does not prove the environment can be built in SAS Viya. The Python version, package artifacts, platform markers, native libraries, architecture, and package sources must also match the target deployment.

1. **Create and resolve the environment locally.** The following example creates a project named `green_py` and resolves its dependencies. Resolving locally first catches dependency conflicts before you build in SAS Viya. The Python version and package list below is used only as an example. Replace the the version and package list with your own.

   > **Note**
   >
   > Resolve against the same package repository that sas-pyconfig installs from. If you use a private repository, add `--index-url <repository-url>` to the command. Otherwise, uv resolves against PyPI, and the pinned versions might not be available in your repository.
   
   ```shell
   uv init green_py --python 3.13
   uv add --project green_py pandas polars pyarrow scikit-learn xgboost saspy sasctl swat
   ```

2. **Generate a pinned package list.** Export the exact package versions that uv resolved for the `green_py` environment.

   ```shell
   uv export --project green_py --no-hashes --no-emit-project -o constraints.txt
   uv pip compile green_py/pyproject.toml --python-version 3.13 --python-platform x86_64-manylinux_2_28 --no-header --no-annotate -o requirements.txt
   ```

3. **Convert the pinned list into the space-separated format sas-pyconfig expects.** Use whichever command matches your shell.

   **Bash**

   ```shell
   grep -vE '^[[:space:]]*(#|$)' requirements.txt | tr '\n' ' '
   ```

   **PowerShell**

   ```powershell
   (Get-Content requirements.txt |
       Where-Object { $_ -notmatch '^\s*(#|$)' }) -join ' '
   ```

   **Python**

   ```python
   with open("requirements.txt") as f:
       packages = " ".join(
           line.strip()
           for line in f
           if line.strip() and not line.lstrip().startswith("#")
       )
   print(packages)
   ```

4. **Add the green profile to sas-pyconfig.** Define a new profile with the Python version and the pinned package list from the previous step. Keep the blue profile in the configuration unchanged. To define a new Python profile, see the [SAS Configurator for Open Source documentation](https://go.documentation.sas.com/doc/en/dplyexternlang/latest/p0kaxaz5x6y3oin1vqnednekblm7.htm).

5. **Build the green profile.** Run the sas-pyconfig job and review the log in the sas-pyconfig pod to confirm the green profile installed successfully.

> **Note**
>
> If a package needs operating system libraries that are not available in SAS Viya, sas-pyconfig cannot install it. Remove the package from the list, or find an alternative that does not need those libraries, and repeat the build.

#### Phase 3: Compatibility testing and cutover

Test each runtime against the green profile. SAS Compute and SAS Model Studio move to green only after their tests pass. CAS and MAS are pre-validated in SAS Compute, then cut over and tested during a change window, with rollback to blue if testing fails. Steps marked **Cutover** promote green for that runtime.

> **Note**
>
> Testing in SAS Compute is an important first check. It catches many Python, package, model loading, and prediction issues before you change CAS or MAS. However, passing in SAS Compute does not guarantee the same behavior in CAS or MAS. Runtime-specific configuration, permissions, data access, concurrency, and integrations must still be validated in each target runtime.

> **Tip**
>
> Keep your inventory of programs, models, forecasts, and decision flows current, including the Python profile each one uses. Compare it with the environment definitions in version control to find what an update will affect.

##### SAS Compute

1. In a test session, point `PROC_PYPATH` at the green profile without changing the global setting:

   ```sas
   options set=PROC_PYPATH="/opt/sas/viya/home/sas-pyconfig/green_py/bin/python3";
   ```

2. Run your test suite and confirm that the code runs correctly and produces the expected output.
3. **Cutover:** Change the global `PROC_PYPATH` environment variable to the green profile.

##### SAS Model Studio

1. Set an unused `DM_PYPATH` environment variable to the green profile and select it in test pipelines. If no unused variable is available, change the main `DM_PYPATH` environment variable in a development deployment or during a change window.
2. Run representative pipelines that use Python and confirm that the results are correct.
3. **Cutover:** Change the main `DM_PYPATH` environment variable to the green profile, or update production pipelines to use the variable that points to green.

##### CAS

1. **Pre-validate in SAS Compute.** Confirm that representative production models that CAS uses can be loaded and scored in the green profile.
2. **Create blue test predictions.** Score representative data in CAS with the blue profile and save the output.
3. **Cutover:** During a planned change window, update `extlang.xml` to point to the green profile and restart CAS.
4. **Test forecasting and external-language workloads** that depend on the CAS Python configuration.
5. **Create green test predictions.** Score the same representative data in CAS with the green profile and save the output.
6. **Compare blue and green predictions.** Determine whether any prediction differences are within acceptable ranges.
7. **Resolve failures.** Decide which models must be retrained, re-serialized, or replaced. If any production workload fails and cannot be fixed within the change window, roll back to blue, resolve the issue, and repeat the cutover later.
8. **Roll back to blue if failures cannot be resolved.**

##### MAS

1. **Pre-validate in SAS Compute.** Confirm that representative production models and decisions that MAS uses can be loaded and scored in the green profile.
2. **Create blue test predictions.** Score representative data in MAS with the blue profile and save the output.
3. **Cutover:** During a planned change window, change the `MAS_PYPATH` environment variable to point to the green profile and restart MAS.
4. **Create green test predictions.** Score the same representative data in MAS with the green profile and save the output.
5. **Compare blue and green predictions.** Determine whether any prediction differences are within acceptable ranges.
6. **Resolve failures.** Decide which models must be retrained, re-serialized, or replaced.
7. **Roll back to blue if failures cannot be resolved within the change window.**

#### Phase 4: Rollback

Because the blue profile stays installed and unchanged, rolling back means pointing each affected runtime back to it. Roll back only the runtimes that are failing.

| Runtime | Rollback action |
|---|---|
| SAS Compute | Change the global `PROC_PYPATH` environment variable back to the blue profile. |
| SAS Model Studio | Change the relevant `DM_PYPATH` variable back to the blue profile. |
| CAS | Update `extlang.xml` to point to the blue profile and restart CAS. |
| MAS | Change `MAS_PYPATH` back to the blue profile and restart MAS. |