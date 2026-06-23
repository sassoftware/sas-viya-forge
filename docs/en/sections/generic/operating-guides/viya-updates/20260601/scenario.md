## Scenario

### Terminology

To understand how SAS manages updates, it is important to understand the [terminology](https://go.documentation.sas.com/doc/en/itopscdc/default/itopscon/p0advvni2iul2en1ln5pp420xm9p.htm) used in this guide.

- Cadence: Refers to the frequency that versioned SAS Viya 4 software is released to customers. Cadence names are Stable (released every month) and Long-Term Support (released every six months).
- Version: A number that indicates the year and month when the SAS Viya 4 software is released to customers. The format is yyyy.mm, such as 2025.08.
- Release: A specific number that indicates the exact timestamp the SAS Viya 4 software is released to customers. Releases can be used to differentiate between two different patch updates of the same version.

As you can see above, we differentiate two different types of updates: Version updates and Patch updates.

- Version update: An update that changes the deployed version of SAS Viya from one version to another.
- Patch update: An update within the same deployed version of SAS Viya.

### When to update?

There are a number of reasons why you might want to update your SAS Viya software. We will list the most common reasons for updating:

#### Updating to a new version
1. **New Functionality**: SAS constantly releases new functionality into their existing products. New functionality is only introduced in new versions of the software and is not retroactively added into previous versions of the software. To get access to this new functionality, upgrading to a new version is therefore required.
2. **SAS Viya Support**: SAS supports the current version and the previous three versions of the SAS Viya software for both the Stable and Long-Term Support cadences. It is therefore required to regularly update your SAS Viya platform to remain supported under [Standard Support](https://support.sas.com/en/technical-support/services-policies/sas-viya-platform.html#viya-support-levels). For deployments following the Stable cadence, this means updating at least every 
3. **Third-Party Support**: Even though your SAS version may still be receiving standard support, some of your third-party dependencies such as Kubernetes, the Ingress controller, or data sources may stop being supported before your SAS version stops being supported. This is especially common when you deploy the Long-Term Stable cadence, which remains in support for a long period of time. In order to be able to use newer versions of these dependencies, you may have to update SAS Viya to a later version.

#### Applying a Patch update
1. **Fix critical issues in existing functionality**: When critical issues are discovered in existing SAS Viya functionality, SAS may produce a Patch for these issue in between versions. You may learn that these updates exist through a [SAS Knowledge Base](https://sas.service-now.com/csm/en?id=kb_search&spa=1) article or through interaction with SAS Technical Support.

### Security Issues
SAS provides security vulnerability remediation through SAS Viya cadence releases and patch updates. Determining whether you need to apply a Patch update, or update to a new version will depend on your security posture and the availability of security fixes in these releases.

For major CVE announcements, SAS publishes [security bulletins](https://support.sas.com/en/security-bulletins.html) which are official SAS statements and advisories about the applicability and recommended remediation of these CVEs.

SAS provides data about security vulnerabilities addressed in each cadence version and patch updates. Licensed customers may request access to this data by contacting SAS Technical Support. For any further detail and resources around SAS Viya security, also contact [SAS Technical Support](http://support.sas.com/ctx/supportform/createForm).