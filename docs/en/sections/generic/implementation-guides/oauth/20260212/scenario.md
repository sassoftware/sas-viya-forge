## Scenario

The goal of this guide is to provide instructions on how to create and configure custom applications to be able to execute SAS compute sessions.
Microsoft Entra ID is used as the authentication provider in this guide, although other authentication providers could also be used as long as they are integrated with SAS Viya using OIDC.

The custom application will be mapped to an Entra ID service principal. In the example this is a Managed Identity assigned to an Azure VM.

The figure below illustrates the high-level steps that need to be performed in order to run a SAS compute session using a Managed Identity.

![Steps](../../../../sections/generic/implementation-guides/oauth/20260212/img/JobExecutionOAuth.png)
