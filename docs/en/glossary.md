# Glossary

The following terms are used throughout SAS Viya Forge and in its Assets.

## Content
SAS Viya Forge delivers content in one of four formats:

<div class="grid cards" markdown>

-   **Reference Architecture**

    ---

    The most optimal architecture to support one or more non-functional requirements.

-   **Best-Practice**

    ---

    The widely accepted **Task Sequence(s)** as the most effective way to achieve a desired outcome.

-   **Guide**

    ---

    A combination of **Best Practices** that are chained together within a given scope.

    ---

    * Typically mapped to a **System Lifecycle** phase.
    * Examples include: Decision Guides, Sizing Guides, Implementation Guides, Tuning Guides, Usage Guides and Operations Guides

-   **Pathway**

    ---
    
    A combination of **Reference Architectures**, **Best Practices** and **Guides** to progress through a **System Lifecycle**

</div>

## Functional Terms

<div class="grid cards" markdown>

-   **Product Feature**

    ---

    A capability of the software (may be software version specific)

-   **Product**

    ---

    The SAS Product. The parent concept to the set of Product Features.

-   **Task**

    ---

    An activity or action to be performed (Ex. Sign on, Open Report, etc.) by applying **Product Features**
    
    ---

    * May be end user or administrator/operator focused
    * Should include expected/acceptable response times

-   **Task Sequence**

    ---

    A sequence of 1 or more **Tasks** that make up a single user work flow (Signon->open report->subset data->view results->close report)

    ---

    * Should include expected/acceptable response times

-   **Scenario**

    ---

    A combination of one or more **Task Sequences** to achieve a desired outcome (ex. Define Data, Extract Data, Create Model Pipeline, etc.)

    ---

    * May span users/user personas

-   **Workload**

    ---
  
    The set of all **Scenarios** that could be run on a **System**.

    ---

    * This may span products

</div>

## Non-Functional Terms

<div class="grid cards" markdown>

-   **Infrastructure**
    
    ---
    
    A set of (virtual) hardware resources that supports the (non-functional) requirements dictated by the **environmental context**

-   **Deployment**

    ---

    ​A set of software that supports the functionality used in all required **scenarios** (to achieve desired outcomes)
    The set of functionality can change as software versions change​

-   **System**

    ---

    A combination of a **deployment** and **infrastructure** that provides **Value** through fulfilling both functional and ​non-functional requirements ​(as defined by the **environmental context**)

-   **System Lifecycle**

    ---

    The stages a system progresses through that includes Design (Day 0), Implementation (Day 1) and Operation (Day 2)

-   **System Lifecycle Management**

    ---

    The set of activities required to managed a **System** throughout its entire **Lifecycle**

</div>

## Environmental Context

The context in which an environment operates that drives its non-functional requirements. SAS Viya Forge recognizes five pillars of non-functional requirements:

<div class="grid cards" markdown>

-   **Security**  
    
    ---
    
    Maximize the security of your environments, design for privacy, and align with regulatory requirements and standards.​

-   **Reliability**  
    
    ---
    
    Design and operate resilient and highly available environments

-   **Cost**  
    
    ---

    Maximize the business value of your infrastructure investment

-   **Performance & Scale**  
    
    ---
    
    Design and tune your resources for optimal performance and scale.

-   **Efficiency**  
    
    ---
    
    Efficiently deploy, operate, monitor, and manage your environment

</div>

## Value Stages
The value of a **System** refers to the benefits and usefulness that it provides to its users and stakeholders. **Value** is typically achieved from a **System** in one or more stages. SAS Viya Forge recognizes four stages:

<div class="grid cards" markdown>

-   **Identify**

    ---

    Discover what value possibilities exist

-   **Enable**

    ---

    Map business value to solutions, enabling **Value** to be realized quickly and efficiently

-   **Ensure**

    ---

    Constantly remove barriers and measure success

-   **Increase**

    ---

    Increase and/or add **Value** by driving feedback and iterating

</div>


