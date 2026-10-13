## Solution overview

This Best Practice describes six practices for designing, governing, and maintaining shared Python environments in SAS Viya. Together, they keep each environment minimal, separated by workload, access-controlled, built from trusted package sources, promoted through immutable versions, and rebuildable from a version-controlled definition. Following them limits the impact of package changes, reduces security exposure, and allows any shared environment to be traced back to and rebuilt in a known, validated state.

### Assumptions

- Python is configured for use with SAS Viya as described in the SAS Viya documentation.
- The reader has administrative access to configure Python for SAS Viya, or works with an administrator who does.
- Python code runs in one or more SAS Viya runtimes, such as SAS Compute, CAS, or MAS.
- A version control system, such as git, is available for storing environment definitions.

### Solution

#### 1. Create purpose-built, minimal environments

Create the smallest environment necessary for a defined workload. Avoid relying on a single, large default Python environment for all users and applications.

Minimal environments:

- Reduce dependency conflicts
- Limit the security and maintenance surface
- Make validation and troubleshooting easier
- Reduce the risk that one package update affects unrelated workloads

> **CAS, MAS and Python**
>
> CAS and MAS each support only one Python environment at a time. Each environment must include every package needed for model scoring and, for CAS, any open source modeling used with SAS Visual Forecasting. As a result, these environments may be larger than others.

#### 2. Separate environments by workload and lifecycle

Create separate environments for workloads with different dependency, validation, performance, or release requirements. Examples include:

- Data engineering
- LLM application development
- Machine learning model training
- Forecasting model training and scoring
- Interactive or general development
- Production batch execution
- Production model scoring

Development, training, and production should not share an environment by default. They can use the same validated package versions, but each production environment should contain only what its workload needs. For example, a production scoring environment should include only the packages required to score models or modeling pipelines.

#### 3. Apply role-based access and separation of duties

Control who can:

- Discover a Python environment
- Use a Python environment to execute code
- Modify its package definitions
- Build or update it
- Approve it for production use
- Assign it to workloads or users

Users should be able to execute code only with authorized Python environments. Changes to controlled or production environments should be restricted to designated administrators, administrator-trusted users, or automated deployment processes.

#### 4. Use trusted package sources and enforce package governance

Connect environment creation to an approved package management service or internal repository that supports:

- Package allowlists and denylists
- Vulnerability and malware scanning
- Approved package sources
- Dependency and license review
- Package provenance and auditability
- Retention of previously approved package artifacts

Create production Python environments only from trusted, controlled package sources. Avoid depending directly on public repositories, such as PyPI, during production builds.

#### 5. Use immutable, versioned promotion with side-by-side versioning and controlled cutover deployment

Do not update an active shared environment in place. Instead, build a new, versioned environment and validate it alongside the currently approved one, ideally in a separate development SAS Viya deployment.

Where a runtime can select between multiple environments, use a blue-green deployment: keep the current environment active, validate the new one alongside it, and switch over only after validation passes. The previous environment remains available for rollback.

#### 6. Ensure environments can be rebuilt

Maintain a version-controlled definition for each environment. The definition should capture:

- Python version
- Direct dependencies
- Resolved dependency versions
- Package sources
- Operating system and architecture constraints
- Native or system-level dependencies
- Build configuration
- Security scan and validation results

Treat the environment itself as a generated artifact, not as the authoritative definition. Files or information that can help include:

- **Requested definition**
  - `pyproject.toml`, or
  - direct dependencies and constraints, and
  - supported Python range
- **Resolved deployment definition**
  - `pylock.toml`, or
  - a pinned `requirements.txt`

---

Whether you are working on a personal project or in a shared SAS Viya deployment, keeping dependencies minimal and maintaining version-controlled definitions improves reproducibility, security, and maintainability. For personal development outside a shared deployment, such as in SAS Viya Workbench, each project should generally have its own isolated Python environment and version-controlled definition.

> **Note**
>
> Always store both your requested and fully resolved environment definitions in git (for example, `pyproject.toml` with `pylock.toml` or a pinned `requirements.txt`). Record which environment each program and model uses in a central inventory.

To capture the installed Python package versions in an existing SAS Viya deployment, use `pip freeze`. This provides a useful package inventory and can help with environment reconstruction, but you must supplement it with the Python version, target platform, package sources, system dependencies, and SAS configuration.

Run the following code in a Python Code step in SAS Data and AI Studio or the SAS Extension for VS Code to save the installed packages of the environment set by `PROC_PYPATH` to `requirements.txt`.

*The code adds the environment name and Python version as comments at the top of the file. These are for reference only, and pip ignores them when reading the file.*

**Create requirements.txt**

```python
import os
import platform
import subprocess
import sys
from pathlib import Path

python_executable = Path(sys.executable)
environment_name = python_executable.parent.parent.name

# This informational only and will not be used by pip
metadata = (
    f"# environment_name={environment_name}\n"
    f"# python={platform.python_version()}\n"
)

dependencies = subprocess.run(
    [sys.executable, "-m", "pip", "freeze"],
    capture_output=True,
    text=True,
    check=True,
)

contents = metadata + dependencies.stdout
print(contents)

with open("requirements.txt", "w", encoding="utf-8") as file:
    file.write(contents)
```