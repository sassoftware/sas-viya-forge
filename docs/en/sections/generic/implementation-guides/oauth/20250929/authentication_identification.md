# 1. Identification and Authentication

The SAS Viya platform can be configured for many different authentication protocols. For the purpose of this document however, there is only one distinction that is relevant. Does your Viya environment authenticate to LDAP or is a third-party authentication provider used? In other words, is Viya able to authenticate users with a username and password combination or does it rely on a third-party to make the authentication decision on its behalf?
When third-party authentication providers, such as Azure EntraId or Okta, are used, authenticating to the Viya environment may not always be possible for non-interactive processes to successfully authenticate due to restrictions such as multi-factor authentication (MFA).
It is in these scenarios that OAuth clients, defined in the Viya environment itself, are used to allow external systems to interact with the Viya environment.

## Identification

Before we can interact with any Viya API, we need to have an identity that we can use for these interactions. As described above we will use OAuth clients for this. Creation of OAuth client is described in the [Register an OAuth Client ID](https://go.documentation.sas.com/doc/en/sasadmincdc/default/calauthmdl/n1iyx40th7exrqn1ej8t12gfhm88.htm#n0ce1kz53qzmukn165fzrqdsws3e) section of the SAS Viya Platform Administration guide.

The guide shows two different ways of registering an OAuth Client ID. This document assumed the SAS Viya Command-Line Interface is used. Note that the example uses the --grant-password option, which is not applicable for environments without an LDAP backend. There are several other options available. These are:

* --grant-authorization-code
* --grant-client-credentials
* --grant-implicit
* --grant-refresh-token

The authorization-code and refresh-token grant types do not allow for fully non-interactive interaction with the SAS Viya API as there is always a manual action required to obtain an authorization token. There are [security concerns](https://learn.microsoft.com/en-us/entra/identity-platform/v2-oauth2-implicit-grant-flow#security-concerns-with-implicit-grant-flow) with using the implicit grant type. This therefore leaves us with the client-credentials grant type as the only available option. We will see later on in this document that there is another option available when you register your client through the REST API instead of using the CLI. This option will be discussed in the Runtimes chapter.

Next to the required --id and --secret options, the --authorities option should be provided in most scenarios. Authorization of the OAuth client will be based on the groups that are specified for this option.

Note that the example again assumes password authentication is available and therefore utilizes the "auth login" command of the Viya CLI. Instead we will use the "auth loginCode" command, which will work regardless of your chosen authentication protocol.

To register the OAuth client we therefore need to run the following commands as a user that is a member of the SAS Administrators group:

```
sas-viya --profile <profile> auth loginCode

sas-viya --profile <profile> oauth register-client \
         --id <client-id> --secret <client-secret> \
         --grant-client-credentials \
         --authorities <group1,group2,..groupN>
```

For example:

```
sas-viya --profile development auth loginCode

sas-viya --profile development oauth register-client \
         --id 'finance-frontend' --secret 'verysecret' \
         --grant-client-credentials \
         --authorities 'api-users,finance-users'
```
should result in
```
Registering new client 'finance-frontend' with grant_type client_credentials...
finance-frontend has been registered as a client of the SAS environment at https://hostname.example.com.
Clients can use finance-frontend and verysecret to obtain access tokens.
OK
```

## Authentication

Now that an OAuth client has been created we can authenticate this user with the Viya environment to obtain an access token. Obtaining an access token is described in the [Obtain an Access Token](https://go.documentation.sas.com/doc/en/sasadmincdc/default/calauthmdl/n1iyx40th7exrqn1ej8t12gfhm88.htm#n1n9seeyh7rsg7n1iilbj8wxnyxo) section of the SAS Viya Platform Administration guide.

The following example authenticates the OAuth client and extracts the access token from the response obtained from the SAS Logon Manager:

```
INGRESS_URL='https://hostname.example.com'
CLIENT_ID='finance-frontend'
CLIENT_SECRET='verysecret'

OAUTH_TOKEN=$(curl -k "${INGRESS_URL}/SASLogon/oauth/token" \
          -H 'Content-Type: application/x-www-form-urlencoded' \
          -d 'grant_type=client_credentials' \
          -u "${CLIENT_ID}:${CLIENT_SECRET}" \
          2> /dev/null | jq -r .access_token)
```

Note that defining the CLIENT_ID and CLIENT_SECRET variables on the command-line is not recommended.
Instead these variables should be provided as environment variables to the process performing the API call. Alternatively you can use a netrc file that contains the credentials and is stored in a secure location.

The contents of the netrc file:
```
machine example.com login finance-frontend password verysecret
```

The accompanying shell commands:
```
INGRESS_URL='https://hostname.example.com'

OAUTH_TOKEN=$(curl -k "${INGRESS_URL}/SASLogon/oauth/token" \
          -H 'Content-Type: application/x-www-form-urlencoded' \
          -d 'grant_type=client_credentials' \
          --netrc-file /tmp/secure/example_com_credentials \
          2> /dev/null | jq -r .access_token)
```

## Next
Continue to the next section: [Authorization](./authorization_interaction.md)


