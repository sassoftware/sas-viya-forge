The Viya platform is an open platform that allows users to interact with it in the way they choose. Whether this is through the SAS Viya web interfaces, IDEs, Open Source libraries or APIs.
While a lot of documentation exists around the use of the SAS Viya APIs, it may be difficult to oversee the entire chain of events and related requirements that exist when working with these APIs.
This is especially true when using Custom Applications (previously called OAuth clients) to use these APIs.

This document tries to capture the different stages involved in using the Viya APIs specifically to run a compute session and provide the requirements that need to be fulfilled when using these specific parts of the API.
For detailed information on all the API endpoints that are available for SAS Viya, please visit [SAS Developers](https://developer.sas.com/)

This version of the document focuses on using functionality added in SAS Viya 2026.02 that allows custom applications to run SAS compute sessions.
The previous way of working, using dedicated user accounts functioning as service accounts, is still valid and can be found in the previous version of this guide.