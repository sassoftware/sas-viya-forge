# Closing Remarks

As we have seen throughout this document, the way to interact with the SAS Viya API with an OAuth client differs based on your use case. To summarize the recommended approach, see the outline below:

1. For any API call that does not require starting a compute session, use client credentials for authentication.
2. For any API call that starts a compute session, but does not require any subsequent single sign-on authentication (such as CAS or a third-party database), configure a compute context to run under a shared account and use client credentials for authentication.
3. For any API call that starts a compute session and needs to authenticate using single sign-on to downstream services, first acquire an access token for a registered service account and then interact with the API.

## References

* [SAS Viya Platform Administration - Authentication](https://go.documentation.sas.com/doc/en/sasadmincdc/default/calauthmdl/n1iyx40th7exrqn1ej8t12gfhm88.htm)
* [SAS Developers Documentation - REST APIs](https://developer.sas.com/rest-apis)