---
title: Scenarios and Resources
---

# Scenarios and Resources

## Scenarios 

Each scenario represents a specific use case and includes everything needed to configure and validate your SAS Viya environment. Ensure that your Viya environment is properly set up with all required content before executing any scenario.

If the required setup is incomplete, the tests may fail.
For example, running a Visual Analytics test case without the associated reports, data sources, formats, or dependent objects will result in errors during execution.

Refer to the following [list of available scenarios](https://github.com/sassoftware/sas-validation-scenarios/blob/main/documentation/SCENARIOS-GUIDE.md) for more details. 


details. 


## Resources

The scenarios expect content such as data, SAS Studio flows, VA reports, SAS programs and other items in order to run successfully. 
These resources are all available in the sas-validation-scenarios/validation-scenarios/resources folder.
They need to be uploaded to the viya system before the tests can be run successfully. 

Currently, SAS Content needs to be loaded manually by a user into their Viya environment.
This step is expected to be automated soon. 

<!-- vale off -->
| Content Type       | Details                              | Location  |  
|------------------|---------------------------------------------|----------|
| data | datasets that needs to be loaded to cas  |  CAS Public Library | 
| dataflows |SAS Studio Flows (Use SAS Studio to upload)  | SAS Content --> Public |  
| sas_program | SAS programs (Use SAS Studio to upload)  | SAS Content--> Public  |
<!-- vale on -->