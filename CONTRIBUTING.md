# Contributing

SAS Viya Forge is designed to be open to contributions from the wider SAS community.
Using the following guidelines, you are able to contribute to the assets on this site.

This site is built using [Material for MkDocs](https://squidfunk.github.io/mkdocs-material/). This means that all pages are creating from plain text markdown documents.
These documents are stored in a Git repository. The source code of this page can be found on [Github](https://github.com/sassoftware/sas-viya-forge) or using the Github link in the banner of this site.

To ensure consistency, each document type comes with its own predefined layout which contributors need to follow when adding content. We provide an easy script to create the required files for your contribution. See the instructions below.

## Instructions

Contributing to content can most easily be done in the following way:

1. **Fork the Github source.** See [Create a fork](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/working-with-forks/fork-a-repo) for instructions or use this direct [link](https://github.com/sassoftware/sas-viya-forge/fork). Note that you will need to define the Owner of the forked the repository. If you already have a fork of the repository, make sure it is [up-to-date](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/working-with-forks/syncing-a-fork) with the upstream repository.
2. [**Clone the repository**](https://docs.github.com/en/repositories/creating-and-managing-repositories/cloning-a-repository) to create a local copy on your machine. 
3. **Create a new branch.** Using the git commandline tool:
```
git checkout -b <name of your branch>
```
4. **Create the required files.** Run the generate-new-document script. See the paragraph below for detailed instructions.
```
./generate-new-document.sh
```
or, if you run on Windows:
```
.\generate-new-document.ps1
```
4. **Make your desired changes** to the documents created by the script.
5. **Preview the site** Also see the section "Previewing your contribution"
```
./preview-site.sh
```
or, if you run on Windows:
```
.\preview-site.ps1
```
5. **Stage the files to be committed:**
```
git add .
```
Alternatively if you want to selectively add modified files you can also run
```
git add <file-or-directory>
```
6. **Commit your changes to the branch**
```
git commit -m "Add a descriptive message here"
```
7. **Push your changes to your Github repository**
```
git push origin <name of your branch>
```
7. **Open a merge request.** 

When you initially push your new branch to your repository, Github will provide you with a useful link to directly open a merge request:
```
remote: 
remote: Create a pull request for 'cleanup' on GitHub by visiting:
remote:      https://github.com/st-jan/sas-viya-forge/pull/new/cleanup
remote: 
```

See [Creating a pull request](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request) for instructions on other ways to create pull requests.

Your content will then be reviewed by SAS. We either will suggest improvements to the submitted content or merge it into the documentation.
Once your merge request has completed, an automated process will rebuild the site and make it available instantly.

Note that a maintainer will run a merge request pipeline to validate the site will build with the newly contributed changes.
The warning message stating your changes cannot be merged is expected and will automatically be removed once this pipeline has run.

### The generate-new-document script

The generate-new-document.sh script creates all the necessary template files needed for a new contribution. It accepts various arguments, based on the type of content you want to contribute.

```
Usage: ./generate-new-document.sh <options>
Generates a new document directory with the specified name and type.
Options:
  -n, --name          Specify the document filename (mandatory)
  -t, --type          Specify the document type (mandatory).
                      Valid values are best-practice, guide, reference-architecture, pathway
  -g, --guide-type    Specify the guide type (mandatory if document type is 'guide').
                      Valid values are decision, implementation, deployment, operating
  -d, --day           Specify the day in the lifecycle (mandatory if document type is 'best-practice').
                      Valid values are 0, 1, 2
  -p, --platform      Specify the platform (optional)
                      Valid values are AWS, Azure, GCP, OpenShift
  -b, --valid-from    Specify the valid from SAS Viya version (mandatory)
  -e, --valid-to      Specify the valid to SAS Viya version (optional)
  -s, --subject       Specify the subject (optional).
                      Valid values are Security, Reliability, Cost, Performance & Scale, Efficiency
  -x, --external      Specify if the document links to external content (optional)
  -h, --help          Display this help message
```

- The name of the document should a short name that can be used as folder and filenames. For example, for a document on High Availability deployment on AKS, the name could be ha-azure.
    - The title of the document can be provided within the generated templates.
- The type, guide-type and day options are explained in the next section "Content Types"
- The valid-from and valid-to options are explained in the section "Versioning"
- The external option is explained in the section "External Content"

## Content Types

Content is organized in four categories for which we accept submissions.

* Best Practices
* Guides
* Reference Architectures
* Pathways

### Best Practices

A Best Practice is the widely accepted **Task Sequence(s)** that is the most effective way to achieve a desired outcome. A Best Practice is best suited for a clearly deliniated and limited scope that usually covers a single requirement that needs to be met. For more elaborate scenarios, a Guide is more appropriate.

Best Practices are organized by System Lifecycle phases, Day 0, Day 1 and Day 2. Day 0 Best-Practices relate to designing and preparing for deployment. Day 1 Best-Practices deal with implementation of your environment or functionality. Day 2 Best Practices deal with operating and maintaining your environment.

#### Document Layout

Best Practices need to adhere to the following layout:

* Introduction
* Use Case Description
    * What is the problem I am trying to solve?
    * What is the functionality that I am documenting?
* Solution Overview
    * How is this problem best resolved?
    * What is the recommended process to achieve the required functionality?
* Conclusion
* References
    * References may include reference documentation, but also other documents on this site such as Guides.

If you use the generate-new-document script provided, you will automatically use this layout.

### Guides

Guides are typically longer than a Best Practice and encompass an entire or multiple scenarios.
Guides are organized by type. The following guide types are open to submissions:

* Decision Guides (Day 0)
* Deployment Guides (Day 0)
* Implementation Guides (Day 1)
* Operating Guides (Day 2)

#### Document Layout

Guides need to adhere to the following layout:

* Introduction
* Use Case Description
    * Decision Guides - For what non-functional requirement am I making a decision?
    * Deployment Guides - What non-functional requirement am I trying to meet?
    * Implementation Guides - What functional requirement am I implementing?
    * Operating Guides - What operation do I need to perform?
* Solution Overview
    * Decision Guides - What are the viable choices and how do I make a decision amongst them?
    * Deployment Guides - How do I deploy my System to meet the requirement?
    * Implementation Guides - What Task Sequence(s) will lead to meeting the requirement?
    * Operating Guides - How do I perform the required operation?
* Conclusion
* References
    * References may include reference documentation, but also other documents on this site such as Best-Practices.

The solution description can consist of multiple sections for larger guides.

If you use the generate-new-document script provided, you will automatically use this layout.

### Reference Architectures

A Reference Architecture is the most optimal architecture to support one or more non-functional requirements.

#### Document Layout

Reference Architectures need to adhere to the following layout:

* Introduction
* Use Case Description
    * What non-functional requirement does this reference architecture address?
* Solution Overview
    * What architectural decisions need to be made to meet the requirement?
    * What is the recommended decision for each of these?
* Frequently Asked Questions
* References
    * References may include reference documentation, but also other documents on this site such as Guides and Best-Practices.

If you use the generate-new-document script provided, you will automatically use this layout.

### Pathways

A Pathway is combination of **Reference Architectures**, **Best Practices** and **Guides** to progress through a **System Lifecycle**. For example, the "Running SAS Viya using multiple Availability Zones on EKS" Pathway consists of a Reference Architecture, a Deployment Guide and an Operating Guide for this particular requirement.

Given the fact that Pathways do not provide unique content themselves but link existing content together, the index.md file should only include links to existing documents such as Reference Architectures, Guides and Best-Practices.

If you use the generate-new-document script provided, you will automatically use this layout.

### External Content

SAS already has many channels in which information is shared that already fits within the definitions provided within this project.
To enable easy integration of this content, external content can be added.

To add external content, run the generate-new-document script as you would if you were adding the appropriate document type yourself. By adding the -x or --external option, you will be provided with a template that allows you to specify a link to external content.

## Versioning

Documents may be valid for one or multiple versions of SAS Viya or may have no relation to the version of SAS Viya at all.
To ensure it is clear to the reader what the validity of a certain document is, documents need to be versioned. This is done in two ways:

1. Documents are placed in versioned folders. The name of the folder refers to the date on which the document was added. For instance: 20250619    
    This date is automatically generated when you use the generate-new-document script.

2. Each document contains at lease one, possibly two version tags:
    - ``Valid From``  
        What is the earliest SAS Viya version for which this document is valid. If this document is valid for all versions, specify 2024.01.
    - ``Valid To`` (optional)  
        What is the latest SAS Viya version for which this document is valid. Note that document may start out with no Valid To tag and only have one added once there is a better solution available due to new functionality being introduced in later versions of SAS Viya.

## Images and Diagrams

The sections folder that was created for you contains an img folder where you can store images. The scenario.md file contains an example of how to include an image.
The syntax for including images in Markdown is the following:

\!\[\<Image Description\>\]\(\<Image Source\>\)

The image source URL has been generated for you. You only need to update the image description and filename.
Images can be placed in other files within the same sections folder as well, using the same syntax.


### Diagrams

To achieve consistency amongst the content, there is a strong preference to create diagrams using [draw.io](https://app.diagrams.net/).
If you have an explicit need to use another diagramming tool, please provide an explanation in your PR.

## Previewing your contribution

You can preview your contribution by running the preview-site.sh script.
To do this, first create a Python virtual environment inside your cloned repository:

```
python3 -m venv venv
source venv/bin/activate
```

Now, you can run the preview-site.sh script, which will install the necessary dependencies and run a local http server:

```
./preview-site.sh
```

To stop the preview, simply hit CTRL+C.

## Contributor License Agreement
Contributions to this project must be accompanied by a signed [Contributor Agreement](ContributorAgreement.txt).
You (or your employer) retain the copyright to your contribution.
This simply permits the project maintainers to use and redistribute your contributions as part of the project.