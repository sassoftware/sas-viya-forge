# Contributing

SAS Viya Forge is designed to be open to contributions from the wider SAS community.
Using the following guidelines, you are able to contribute to the assets on this site as well. To ensure consistency, each document type comes with its own predefined layout which contributors need to follow when adding content. This layout is also defined below.

## Technical

This site is built using [Material for MkDocs](https://squidfunk.github.io/mkdocs-material/). This means that all pages are creating from plain text markdown documents.
These documents are stored in a Git repository. The source code of this page can be found on [Github](https://github.com/sassoftware/sas-viya-forge) or using the Github link in the banner of this site.

Contributing to content can most easily be done in the following way:

1. Fork the Github source.
2. Create a new branch: 
```
git checkout -b new-feature
```
3. Make your desired changes.
4. Stage the files to be committed:
```
git add <file-or-directory>
```
5. Commit your changes to the branch
```
git commit -m "Add a descriptive message here"
```
6. Open a merge request
```
git push -o merge_request.create origin my-branch
```

Your content will then be reviewed by SAS. We either will suggest improvements to the submitted content or merge it into the documentation.
Once your merge request has completed, an automated process will rebuild the site and make it available instantly.

## Organizing Content

Content is organized in four categories for which we accept submissions.

* Best Practices
* Guides
* Reference Architectures
* Pathways

### Best Practices

Best Practices are organized by System Lifecycle phases, Day 0, Day 1 and Day 2.
A new Best Practice can be added by creating a new folder under a specific day.
You can find the best practices in docs -> en -> best-practices.

The folder underneath the best practices folder tree should only contain an index.md file that contains the title and tags and an introduction.md file, which contains the unique introduction into this document. A best practice will typically only have two other sections, that should be place in a separate "sections" folder, which allows them to be re-used if necessary.

The sections folder is divided into a generic and platform-specific folder. This allows for multiple versions of the same guide to be provided for each of the different cloud providers.

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

### Guides

Guides are organized by type. The following guide types are open to submissions:

* Deployment Guides
* Design Guides
* Implementation Guides
* Operating Guides

A new Guide can be added by creating a new folder under one of these types.
You can find the Guides in docs -> en -> guides.

Guides are typically longer than a Best Practice and encompass an entire or multiple scenarios.
Guides may also include content that is shared amongst multiple guides. For example, an Implementation Guide on Disaster Recovery in Azure will contain the same explanation on how Disaster Recovery works in general and only differentiates itself from the Implementation Guide on Disaster Recovery in AWS on the cloud-vendor specific instructions.

This is where the sections folder discussed above is helpful again.

Example:

```
# Deploying with Disaster Recovery on AWS

{\% include 'guides/deployment-guides/dr-aws/20250309/introduction.md' %}

{\% include 'sections/generic/deployment-guides/dr/20250309/usecase.md' %}

{\% include 'sections/platform-specifics/aws/deployment-guides/dr/20250309solution.md' %}
```

#### Document Layout

Guides need to adhere to the following layout:

* Introduction
* Use Case Description
    * Design Guides - What non-functional requirement am I designing for?
    * Deployment Guides - What non-functional requirement am I trying to meet?
    * Implementation Guides - What functional requirement am I implementing?
    * Operating Guides - What operation do I need to perform?
    * Validation Guides - What Scenario am I trying to validate?
* Solution Overview
    * Design Guides - How do I design my System to meet the requirement?
    * Deployment Guides - How do I deploy my System to meet the requirement?
    * Implementation Guides - What Task Sequence(s) will lead to meeting the requirement?
    * Operating Guides - How do I perform the required operation?
    * Validation Guides - How do I validate the Scenario?
* Conclusion
* References
    * References may include reference documentation, but also other documents on this site such as Best-Practices.

The solution description can consist of multiple sections for larger guides.


### Reference Architectures

A new Reference Architecture can be added by creating a new folder underneath the reference-architectures top-level folder.
You can find the Reference Architectures in docs -> en -> reference-architectures.

Like Guides, Reference Architectures typically contain multiple sections. They are therefore organized the same way as we do for Guides. Sections are stored in the "sections" folder, while the folder underneath the reference-architectures top-level folder should only contain an index.md file that contains the title and tags and an introduction.md file. All the other sections should included in the index.md file.

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

### Pathways

A new Reference Architecture can be added by creating a new folder underneath the pathways top-level folder.
You can find the Pathways in docs -> en -> pathways.

This folder should again only contain an index.md file that contains the title and tags and an introduction.md file. Given the fact that Pathways do not provide unique content themselves but link existing content together, the index.md file should only include links to existing documents such as Reference Architectures, Guides and Best-Practices.

## External Content

SAS already has many channels in which information is shared that already fits within the definitions provided within this project.
To enable easy integration of this contentm, external content can be added. To add external content, you create the index.md file as described above.
However, instead of adding the content into this repository as well, only a description of the content is provided in the index.md file with a link to the external content.

Example:

```
# Troubleshooting HTTPS Certificate Issues in SAS Viya - Expired certificates

Expired certificates can disrupt secure communication, leading to service outages and security risks. The following blog post explores how to identify and troubleshoot expired certificates in SAS Viya.

## External Content

[Troubleshooting HTTPS Certificate Issues in SAS Viya: Expired certificates](https://sww2.sas.com/blogs/wp/gate/119947/troubleshooting-https-certificate-issues-for-your-sas-viya-platform-expired-certificates/fradae/2024/12/19)
```

### Tags
When you add external content, please provide one of the following tags:

* External Content - Internal Link
    * This tag is added when the external content is only accessible from the SAS internal network
* External Content - External Link
    * This tag is added when the external content is accessible on the public internet

__Note:__ During the first phase of this project external content with internal links will be allowed. When this website will be published externally, only content that is accessible over the public internet will be allowed.



## Versioning

Documents may be valid for one or multiple versions of SAS Viya or may have no relation to the version of SAS Viya at all.
To ensure it is clear to the reader what the validity of a certain document is, documents need to be versioned. This is done in two ways:

1. Documents are placed in versioned folders. The name of the folder refers to the date on which the document was added.  
    For instance: 20250619
2. Each document contains at lease one, possibly two version tags:
    - ``Valid From``  
        What is the earliest SAS Viya version for which this document is valid
    - ``Valid To`` (optional)  
        What is the latest SAS Viya version for which this document is valid. Note that document may start out with no Valid To tag and only have one added once there is a better solution available due to new functionality being introduced in later versions of SAS Viya.

## Images and Diagrams

Images can be stored alongside the documents in which they are included in a separate img folder. Note that the link provided to the image is relative to the top-level document in which it is included. So for example

ApplicationGateway.png exists at:

```
/docs/en/sections/platform-specific/azure/deployment-guides/application-gateway/20250429/img/ApplicationGateway.png
```

Is included in:

```
/docs/en/sections/platform-specific/azure/deployment-guides/application-gateway/20250429/usecase.md
```

usecase.md is itself included in:

```
docs/en/guides/deployment-guides/application-gateway/20250429/index.md
```

Therefore, the link to the image is:

```
../../../../sections/platform-specific/azure/deployment-guides/application-gateway/20250429/img/ApplicationGateway.png
```

### Diagrams

To achieve consistency amongst the content, there is a strong preference to create diagrams using [draw.io](https://app.diagrams.net/).
If you have an explicit need to use another diagramming tool, please provide an explanation in your PR.

## Contributor License Agreement
Contributions to this project must be accompanied by a signed [Contributor Agreement](ContributorAgreement.txt).
You (or your employer) retain the copyright to your contribution.
This simply permits the project maintainers to use and redistribute your contributions as part of the project.
