# Using External Services

In the previous chapter we discussed how to use the SAS run-time servers with an OAuth client. In this chapter we will discuss how we can interact with different external services from those run-time servers. We will discuss two different types of external services: those that are integrated with the authentication provider that Viya uses and therefore can be used without further authentication (Single Sign-On) and those that are using a different authentication provider from SAS.

## Services using External credentials

If you do not want to use integrated authentication or the service you connect to does not offer it, using [external credentials](https://go.documentation.sas.com/doc/en/sasadmincdc/default/calcredentials/p1wvrzz9l2o7lnn1kx9vjezfkuzk.htm) will be required.

How you use external credentials differs based on the run-time server that you use. For the SAS programming run-time and the SAS Cloud Analytic Server, storing the credentials in a credential domain is recommended. For the Micro Analytic Server, external credentials have to be supplied in the database [connection string](https://go.documentation.sas.com/doc/en/mascdc/default/masag/n0rdoki6q46irhn125qqgjvkrbzg.htm#p0lj51q6p3omprn1t0hgtprbz76r). For ESP projects requiring access to a database during processing of an event, the external credentials need to be supplied in the [connectstring](https://go.documentation.sas.com/doc/en/espcdc/default/espca/p0kqcqs0y2r24yn1c94ick5yudkh.htm).

In the rest of this chapter, we will focus on using external credentials in the SAS programming run-time and the CAS server.

### Access to credentials
The first thing to determine is who to grant access to the credentials. This will depend on how your programming run-time session has been started.  
As discussed in the previous chapter, if you are using a shared credential for starting jobs on a specific compute context, the OAuth client's identity will still be used for subsequent authentication and authorizations. This also includes access to credentials stored in credential domains.  
When using an access token of a service account to execute a job, it will be the service account that requires access to the credentials. It does not matter whether the connection to an external service is made directly from the compute session or from the connected CAS session in this case as the CAS session will have been started with whatever credentials are used for subsequent authentication.

For our example we will use an Azure SQL database configured for sql authentication.

### Creating a user in Azure SQL database
We use Microsoft SQL Management Studio to add a new login and user to our database[^1]

Connected to the master database:
```
CREATE LOGIN finance WITH password='verysecret';
```
Connected to the application database:
```
CREATE USER finance FROM LOGIN finance;

EXEC sp_addrolemember 'db_datawriter', 'finance';
```

### Storing the credentials in a credentials domain

We will first register credentials in a credential domain and grant the Finance User group, of which our OAuth client is a member rights to access this credential. Again, we will use the Viya CLI to accomplish this:

```
sas-viya credentials domains create --domain-id finance-sql --description "Credential domain containing credentials for the finance Azure SQL database" --type password

sas-viya credentials groups create --domain-id finance-sql --identity-id finance-users --user finance --password "verysecret"
```
```
The domain "finance-sql" was created.
The credential "finance-users" was created.
```

### Executing a job interacting with an external service

Now that we have credentials stored in a credential domain, we can use these credentials in a job executed by our OAuth client.
Remember, as we have granted access to these credentials to the group of which the OAuth client is a member, we need to run the job on the compute context running under the shared credentials. The service account itself currently has no access to these credentials and therefore cannot use them.

When using more complicated programs that include multiple lines of code, it is often easier to first write the code, save it in a code file and then reference that code file from your job. We will do this in our next example.

1. Creating the code file

    Using SASStudio, the following SAS code was written to a file called ProcContentsFinanceSQL.sas and written to the Public folder in Viya.
    ```
    libname sqlauth sqlsvr authdomain='finance-sql' noprompt="DRIVER={SAS ACCESS to MS SQL Server};SSLLibName=/usr/lib64/libssl.so.1.1;CryptoLibName=/usr/lib64/libcrypto.so.1.1;TrustStore=/opt/sas/viya/home/SASSecurityCertificateFramework/tls/certs/ca-bundle.pem;Database=demo-sql-auth;HostName=demo-sql-auth.database.windows.net;PortNumber=1433";

    proc contents data=sqlauth.credit;
    run;

    libname sqlauth clear;
    ```

2. Creating the job definition.

    Referencing this file we can then create the job by using the following code. Note that we use a here document to avoid issues with escaping quotes.

    <details>
    <summary>API Call</summary>

    ```
    INGRESS_URL=https://hostname.example.com

    curl --request POST \
    --url "${INGRESS_URL}/jobDefinitions/definitions" \
    --header 'Accept: application/json, application/vnd.sas.job.definition+json' \
    --header "Authorization: Bearer $OAUTH_TOKEN" \
    --header 'Content-Type: application/json' \
    --header 'accept: ' \
    --data @- << 'EOF'
    {
        "version": 2,
        "name": "ContentsSQLTable",
        "description": "Get the contents of the credit table in Azure SQL Database.",
        "type": "Compute",
        "parameters": [
            {
                "version": 1,
                "name": "_contextName",
                "defaultValue": "SAS Job Execution compute context",
                "type": "CHARACTER",
                "label": "Context Name",
                "required": false
            }
        ],
        "code": "filename jobfldr filesrvc folderPath = '/Public'; %include jobfldr ('ProcContentsFinanceSQL.sas');"
    }
    EOF
    ```

    </details>

    <details>
    <summary>API Response</summary>

    ```
    {
        "creationTimeStamp": "2025-02-05T15:22:11.312Z",
        "modifiedTimeStamp": "2025-02-05T15:22:11.313Z",
        "createdBy": "finance-frontend",
        "modifiedBy": "finance-frontend",
        "version": 2,
        "id": "bec95a86-0815-4c1a-b661-fecf465591fa",
        "name": "ContentsSQLTable",
        "description": "Get the contents of the credit table in Azure SQL Database.",
        "type": "Compute",
        "parameters": [
            {
                "version": 1,
                "name": "_contextName",
                "defaultValue": "SAS Job Execution compute context",
                "type": "CHARACTER",
                "label": "Context Name",
                "required": false
            }
        ],
        "code": "filename jobfldr filesrvc folderPath = '/Public'; %include jobfldr ('ProcContentsFinanceSQL.sas');",
        "links": [
            {
                "method": "GET",
                "rel": "self",
                "href": "/jobDefinitions/definitions/bec95a86-0815-4c1a-b661-fecf465591fa",
                "uri": "/jobDefinitions/definitions/bec95a86-0815-4c1a-b661-fecf465591fa",
                "type": "application/vnd.sas.job.definition"
            },
            {
                "method": "GET",
                "rel": "alternate",
                "href": "/jobDefinitions/definitions/bec95a86-0815-4c1a-b661-fecf465591fa",
                "uri": "/jobDefinitions/definitions/bec95a86-0815-4c1a-b661-fecf465591fa",
                "type": "application/vnd.sas.summary"
            },
            {
                "method": "PUT",
                "rel": "update",
                "href": "/jobDefinitions/definitions/bec95a86-0815-4c1a-b661-fecf465591fa",
                "uri": "/jobDefinitions/definitions/bec95a86-0815-4c1a-b661-fecf465591fa",
                "type": "application/vnd.sas.job.definition",
                "responseType": "application/vnd.sas.job.definition"
            },
            {
                "method": "DELETE",
                "rel": "delete",
                "href": "/jobDefinitions/definitions/bec95a86-0815-4c1a-b661-fecf465591fa",
                "uri": "/jobDefinitions/definitions/bec95a86-0815-4c1a-b661-fecf465591fa"
            }
        ]
    }
    ```
    </details>     

2. Submitting the job for execution.

    <details>
    <summary>API Call</summary>

    ```
    curl --request POST \
    --url "${INGRESS_URL}/jobExecution/jobs" \
    --header 'Accept: application/json, application/vnd.sas.job.execution.job+json, application/vnd.sas.error+json' \
    --header "Authorization: Bearer $OAUTH_TOKEN" \
    --header 'Content-Type: application/json' \
    --data '{
        "name": "ContentsSQLTable",
        "description": "Get the contents of the credit table in Azure SQL Database.",
        "jobDefinitionUri": "/jobDefinitions/definitions/bec95a86-0815-4c1a-b661-fecf465591fa",
        "arguments": {
        "_contextName":"Shared Compute Context"
        }
    }'
    ```

    </details>
    <details>
    <summary>API Response</summary>

    ```
    {
        "creationTimeStamp": "2025-02-05T15:23:44.304Z",
        "modifiedTimeStamp": "2025-02-05T15:23:44.352Z",
        "createdBy": "finance-frontend",
        "modifiedBy": "finance-frontend",
        "version": 4,
        "id": "b2ed45ac-ee29-47db-bafd-27f7d823c2e5",
        "jobRequest": {
            "version": 3,
            "name": "ContentsSQLTable",
            "description": "Get the contents of the credit table in Azure SQL Database.",
            "jobDefinitionUri": "/jobDefinitions/definitions/bec95a86-0815-4c1a-b661-fecf465591fa",
            "jobDefinition": {
                "creationTimeStamp": "2025-02-05T15:22:11.312Z",
                "modifiedTimeStamp": "2025-02-05T15:22:11.313Z",
                "createdBy": "finance-frontend",
                "modifiedBy": "finance-frontend",
                "version": 2,
                "id": "bec95a86-0815-4c1a-b661-fecf465591fa",
                "name": "ContentsSQLTable",
                "description": "Get the contents of the credit table in Azure SQL Database.",
                "type": "Compute",
                "parameters": [
                    {
                        "version": 1,
                        "name": "_contextName",
                        "defaultValue": "SAS Job Execution compute context",
                        "type": "CHARACTER",
                        "label": "Context Name",
                        "required": false
                    }
                ],
                "code": "filename jobfldr filesrvc folderPath = '/Public'; %include jobfldr ('ProcContentsFinanceSQL.sas');",
                "links": [
                    {
                        "method": "GET",
                        "rel": "self",
                        "href": "/jobDefinitions/definitions/bec95a86-0815-4c1a-b661-fecf465591fa",
                        "uri": "/jobDefinitions/definitions/bec95a86-0815-4c1a-b661-fecf465591fa",
                        "type": "application/vnd.sas.job.definition"
                    },
                    {
                        "method": "GET",
                        "rel": "alternate",
                        "href": "/jobDefinitions/definitions/bec95a86-0815-4c1a-b661-fecf465591fa",
                        "uri": "/jobDefinitions/definitions/bec95a86-0815-4c1a-b661-fecf465591fa",
                        "type": "application/vnd.sas.summary"
                    },
                    {
                        "method": "PUT",
                        "rel": "update",
                        "href": "/jobDefinitions/definitions/bec95a86-0815-4c1a-b661-fecf465591fa",
                        "uri": "/jobDefinitions/definitions/bec95a86-0815-4c1a-b661-fecf465591fa",
                        "type": "application/vnd.sas.job.definition",
                        "responseType": "application/vnd.sas.job.definition"
                    },
                    {
                        "method": "DELETE",
                        "rel": "delete",
                        "href": "/jobDefinitions/definitions/bec95a86-0815-4c1a-b661-fecf465591fa",
                        "uri": "/jobDefinitions/definitions/bec95a86-0815-4c1a-b661-fecf465591fa"
                    }
                ]
            },
            "arguments": {
                "_contextName": "Shared Compute Context"
            },
            "properties": [],
            "createdByApplication": "jobExecution"
        },
        "state": "running",
        "heartbeatTimeStamp": "2025-02-05T15:23:44.349Z",
        "submittedByApplication": "jobExecution",
        "heartbeatInterval": 600,
        "elapsedTime": 61,
        "results": {},
        "links": [
            {
                "method": "GET",
                "rel": "self",
                "href": "/jobExecution/jobs/b2ed45ac-ee29-47db-bafd-27f7d823c2e5",
                "uri": "/jobExecution/jobs/b2ed45ac-ee29-47db-bafd-27f7d823c2e5",
                "type": "application/vnd.sas.job.execution.job"
            },
            {
                "method": "GET",
                "rel": "state",
                "href": "/jobExecution/jobs/b2ed45ac-ee29-47db-bafd-27f7d823c2e5/state",
                "uri": "/jobExecution/jobs/b2ed45ac-ee29-47db-bafd-27f7d823c2e5/state",
                "type": "text/plain"
            },
            {
                "method": "PUT",
                "rel": "update",
                "href": "/jobExecution/jobs/b2ed45ac-ee29-47db-bafd-27f7d823c2e5",
                "uri": "/jobExecution/jobs/b2ed45ac-ee29-47db-bafd-27f7d823c2e5",
                "type": "application/vnd.sas.job.execution.job",
                "responseType": "application/vnd.sas.job.execution.job"
            },
            {
                "method": "DELETE",
                "rel": "delete",
                "href": "/jobExecution/jobs/b2ed45ac-ee29-47db-bafd-27f7d823c2e5",
                "uri": "/jobExecution/jobs/b2ed45ac-ee29-47db-bafd-27f7d823c2e5"
            },
            {
                "method": "PUT",
                "rel": "updateState",
                "href": "/jobExecution/jobs/b2ed45ac-ee29-47db-bafd-27f7d823c2e5/state",
                "uri": "/jobExecution/jobs/b2ed45ac-ee29-47db-bafd-27f7d823c2e5/state",
                "type": "text/plain"
            },
            {
                "method": "POST",
                "rel": "updateHeartbeatTimeStamp",
                "href": "/jobExecution/jobs/b2ed45ac-ee29-47db-bafd-27f7d823c2e5/heartbeatTimeStamp",
                "uri": "/jobExecution/jobs/b2ed45ac-ee29-47db-bafd-27f7d823c2e5/heartbeatTimeStamp",
                "type": "text/plain"
            },
            {
                "method": "GET",
                "rel": "jobDefinition",
                "href": "/jobDefinitions/definitions/bec95a86-0815-4c1a-b661-fecf465591fa",
                "uri": "/jobDefinitions/definitions/bec95a86-0815-4c1a-b661-fecf465591fa",
                "type": "application/vnd.sas.job.definition"
            }
        ]
    }
    ```
    </details>

In the previous section, we have already seen how to retrieve the log file for a job.
For brevity sake, the log file is shown without retrieving it programatically here:

<details>
<summary>Log</summary>

```
source: 1    filename jobfldr filesrvc folderPath = '/Public'; %include jobfldr ('ProcContentsFinanceSQL.sas');
note: NOTE: The quoted string currently being processed has become more than 262 bytes long.  You might have unbalanced quotation marks.
note: NOTE:  Credential obtained from Viya credentials service.
note: NOTE: Libref SQLAUTH was successfully assigned as follows: 
note:       Engine:        SQLSVR 
note:       Physical Name: 
note: 
note: NOTE: PROCEDURE CONTENTS used (Total process time):
note:       real time           0.25 seconds
note:       cpu time            0.09 seconds
note:       
note: NOTE: The PROCEDURE CONTENTS printed page 1.
note: 
note: NOTE: Libref SQLAUTH has been deassigned.
note: 
```

</details>

As you can see, the log line "Credential obtained from Viya credentials service." indicates that the credential to access the SQL Server database was retrieved from the SAS Credential service.


## Services using Single Sign-On

Services that utilize the same authentication provider as the Viya platform allow users to use the credentials that they use to access the Viya environment to access external services as well. Most of these services are located in [Microsoft Azure](https://go.documentation.sas.com/doc/en/sasadmincdc/default/calauthmdl/n1iyx40th7exrqn1ej8t12gfhm88.htm#n1btw367gbj4t7n1is4wg18q5mdk):
- Azure Databricks
- Azure Data Lake
- Azure Key Vault
- Azure PostgreSQL and Azure MySQL
- Azure Service Management
- Azure SQL Database
- Azure Storage

It is also possible to setup [Federated Authentication between Azure Entra ID and Amazon S3](https://go.documentation.sas.com/doc/en/sasadmincdc/default/calauthmdl/p0wwse5qh9uom4n14xoy0721ypkd.htm) to enable access to Amazon S3 without additional authentication.

For our example we will use an Azure SQL database.

### Requirements

To be able to use a single sign-on to connect to an Azure SQL Database, we need to configure our SQL Database to [use Entra ID Authentication](https://learn.microsoft.com/en-us/azure/azure-sql/database/authentication-aad-configure?view=azuresql&tabs=azure-portal).

The SAS Viya environment you are working with needs to be set-up for OIDC authentication. In addition, the App Registration that is used to provide the OIDC authentication needs to be set-up with additional API permissions as documented in the [SAS Viya Platform Administration](https://go.documentation.sas.com/doc/en/sasadmincdc/default/calauthmdl/n1iyx40th7exrqn1ej8t12gfhm88.htm#n1hp4d6pixslt8n1cm03kw8le8wm) guide.
For Azure SQL Database, the API permissions that need to be added are:
* Azure SQL Database (user_impersonation)
* Azure Storage (user_impersonation)
* Microsoft Graph (profile)

You may need to ask an administrator to approve these additional API permissions for all users in your domain if users do not have the rights to approve these themselves.

### Executing a job interacting with an OIDC enabled service

Because we need access to the authentication token of the service account, the only way to submit jobs that need to interact with external services that integrate with the same authentication provider as SAS Viya, is to obtain an access token for the service account before interacting with the API. Jobs submitted to a shared compute context, will continue to use the authorization context of the OAuth client that submitted the job. As the OAuth client does not have any presence in the authentication provider, it cannot be used to access these kind of services.

1. Creating the code file

    Using SASStudio, the following SAS code was written to a file called WriteFishSQLOIDC.sas and written to the Public folder in Viya.
    ```
    libname sqllib sqlsvr AUTHSCOPE="https://database.windows.net/user_impersonation" noprompt="DRIVER={SAS ACCESS to MS SQL Server};SSLLibName=/usr/lib64/libssl.so.1.1;CryptoLibName=/usr/lib64/libcrypto.so.1.1;TrustStore=/opt/sas/viya/home/SASSecurityCertificateFramework/tls/certs/ca-bundle.pem;AuthenticationMethod=13;Database=demo-sql-auth;HostName=demo-sql-auth.database.windows.net;PortNumber=1433";

    proc sql;
        DROP TABLE sqllib.fish;
    run;


    data sqllib.fish replace;
        set sashelp.fish;
    run;

    libname sqllib clear;
    ```

2. Creating the job definition.

    <details>
    <summary>API Call</summary>

    ```
    INGRESS_URL=https://hostname.example.com

    curl --request POST \
    --url "${INGRESS_URL}/jobDefinitions/definitions" \
    --header 'Accept: application/json, application/vnd.sas.job.definition+json' \
    --header "Authorization: Bearer $OAUTH_TOKEN" \
    --header 'Content-Type: application/json' \
    --header 'accept: ' \
    --data @- << 'EOF'
    {
        "version": 2,
        "name": "WriteFishSQLOIDC",
        "description": "Write the table Fish to SQL Server.",
        "type": "Compute",
        "parameters": [
            {
                "version": 1,
                "name": "_contextName",
                "defaultValue": "SAS Job Execution compute context",
                "type": "CHARACTER",
                "label": "Context Name",
                "required": false
            }
        ],
        "code": "filename jobfldr filesrvc folderPath = '/Public'; %include jobfldr ('WriteFishSQLOIDC.sas');"
    }
    EOF

    ```

    </details>

    <details>
    <summary>API Response</summary>

    ```
    {
        "creationTimeStamp": "2025-04-02T08:47:29.778Z",
        "modifiedTimeStamp": "2025-04-02T08:47:29.779Z",
        "createdBy": "Jan.Stienstra@sas.com",
        "modifiedBy": "Jan.Stienstra@sas.com",
        "version": 2,
        "id": "3ea0e5c9-2641-488e-b4bf-9e181e6a682a",
        "name": "WriteFishSQLOIDC",
        "description": "Write the table Fish to SQL Server.",
        "type": "Compute",
        "parameters": [
            {
                "version": 1,
                "name": "_contextName",
                "defaultValue": "SAS Job Execution compute context",
                "type": "CHARACTER",
                "label": "Context Name",
                "required": false
            }
        ],
        "code": "filename jobfldr filesrvc folderPath = '/Public'; %include jobfldr ('WriteFishSQLOIDC.sas');",
        "links": [
            {
                "method": "GET",
                "rel": "self",
                "href": "/jobDefinitions/definitions/3ea0e5c9-2641-488e-b4bf-9e181e6a682a",
                "uri": "/jobDefinitions/definitions/3ea0e5c9-2641-488e-b4bf-9e181e6a682a",
                "type": "application/vnd.sas.job.definition"
            },
            {
                "method": "GET",
                "rel": "alternate",
                "href": "/jobDefinitions/definitions/3ea0e5c9-2641-488e-b4bf-9e181e6a682a",
                "uri": "/jobDefinitions/definitions/3ea0e5c9-2641-488e-b4bf-9e181e6a682a",
                "type": "application/vnd.sas.summary"
            },
            {
                "method": "PUT",
                "rel": "update",
                "href": "/jobDefinitions/definitions/3ea0e5c9-2641-488e-b4bf-9e181e6a682a",
                "uri": "/jobDefinitions/definitions/3ea0e5c9-2641-488e-b4bf-9e181e6a682a",
                "type": "application/vnd.sas.job.definition",
                "responseType": "application/vnd.sas.job.definition"
            },
            {
                "method": "DELETE",
                "rel": "delete",
                "href": "/jobDefinitions/definitions/3ea0e5c9-2641-488e-b4bf-9e181e6a682a",
                "uri": "/jobDefinitions/definitions/3ea0e5c9-2641-488e-b4bf-9e181e6a682a"
            }
        ]
    }
    ```
    </details>     

2. Submitting the job for execution.

    <details>
    <summary>API Call</summary>

    ```
    curl --request POST \
    --url "${INGRESS_URL}/jobExecution/jobs" \
    --header 'Accept: application/json, application/vnd.sas.job.execution.job+json, application/vnd.sas.error+json' \
    --header "Authorization: Bearer $OAUTH_TOKEN" \
    --header 'Content-Type: application/json' \
    --data '{
        "name": "WriteFishSQLOIDC",
        "description": "Write the table Fish to SQL Server.",
        "jobDefinitionUri": "/jobDefinitions/definitions/3ea0e5c9-2641-488e-b4bf-9e181e6a682a"
    }'
    ```

    </details>
    <details>
    <summary>API Response</summary>

    ```
    {
        "creationTimeStamp": "2025-04-02T08:50:32.605Z",
        "modifiedTimeStamp": "2025-04-02T08:50:32.955Z",
        "createdBy": "Jan.Stienstra@sas.com",
        "modifiedBy": "Jan.Stienstra@sas.com",
        "version": 4,
        "id": "8de1791f-6fb1-4a71-b674-adfc642c84b7",
        "jobRequest": {
            "version": 3,
            "name": "WriteFishSQLOIDC",
            "description": "Write the table Fish to SQL Server.",
            "jobDefinitionUri": "/jobDefinitions/definitions/3ea0e5c9-2641-488e-b4bf-9e181e6a682a",
            "jobDefinition": {
                "creationTimeStamp": "2025-04-02T08:47:29.778Z",
                "modifiedTimeStamp": "2025-04-02T08:47:29.779Z",
                "createdBy": "Jan.Stienstra@sas.com",
                "modifiedBy": "Jan.Stienstra@sas.com",
                "version": 2,
                "id": "3ea0e5c9-2641-488e-b4bf-9e181e6a682a",
                "name": "WriteFishSQLOIDC",
                "description": "Write the table Fish to SQL Server.",
                "type": "Compute",
                "parameters": [
                    {
                        "version": 1,
                        "name": "_contextName",
                        "defaultValue": "SAS Job Execution compute context",
                        "type": "CHARACTER",
                        "label": "Context Name",
                        "required": false
                    }
                ],
                "code": "filename jobfldr filesrvc folderPath = '/Public'; %include jobfldr ('WriteFishSQLOIDC.sas');",
                "links": [
                    {
                        "method": "GET",
                        "rel": "self",
                        "href": "/jobDefinitions/definitions/3ea0e5c9-2641-488e-b4bf-9e181e6a682a",
                        "uri": "/jobDefinitions/definitions/3ea0e5c9-2641-488e-b4bf-9e181e6a682a",
                        "type": "application/vnd.sas.job.definition"
                    },
                    {
                        "method": "GET",
                        "rel": "alternate",
                        "href": "/jobDefinitions/definitions/3ea0e5c9-2641-488e-b4bf-9e181e6a682a",
                        "uri": "/jobDefinitions/definitions/3ea0e5c9-2641-488e-b4bf-9e181e6a682a",
                        "type": "application/vnd.sas.summary"
                    },
                    {
                        "method": "PUT",
                        "rel": "update",
                        "href": "/jobDefinitions/definitions/3ea0e5c9-2641-488e-b4bf-9e181e6a682a",
                        "uri": "/jobDefinitions/definitions/3ea0e5c9-2641-488e-b4bf-9e181e6a682a",
                        "type": "application/vnd.sas.job.definition",
                        "responseType": "application/vnd.sas.job.definition"
                    },
                    {
                        "method": "DELETE",
                        "rel": "delete",
                        "href": "/jobDefinitions/definitions/3ea0e5c9-2641-488e-b4bf-9e181e6a682a",
                        "uri": "/jobDefinitions/definitions/3ea0e5c9-2641-488e-b4bf-9e181e6a682a"
                    }
                ]
            },
            "arguments": {
                "_contextName": "SAS Job Execution compute context"
            },
            "properties": [],
            "createdByApplication": "jobExecution"
        },
        "state": "running",
        "heartbeatTimeStamp": "2025-04-02T08:50:32.942Z",
        "submittedByApplication": "jobExecution",
        "heartbeatInterval": 600,
        "elapsedTime": 355,
        "results": {},
        "links": [
            {
                "method": "GET",
                "rel": "self",
                "href": "/jobExecution/jobs/8de1791f-6fb1-4a71-b674-adfc642c84b7",
                "uri": "/jobExecution/jobs/8de1791f-6fb1-4a71-b674-adfc642c84b7",
                "type": "application/vnd.sas.job.execution.job"
            },
            {
                "method": "GET",
                "rel": "state",
                "href": "/jobExecution/jobs/8de1791f-6fb1-4a71-b674-adfc642c84b7/state",
                "uri": "/jobExecution/jobs/8de1791f-6fb1-4a71-b674-adfc642c84b7/state",
                "type": "text/plain"
            },
            {
                "method": "PUT",
                "rel": "update",
                "href": "/jobExecution/jobs/8de1791f-6fb1-4a71-b674-adfc642c84b7",
                "uri": "/jobExecution/jobs/8de1791f-6fb1-4a71-b674-adfc642c84b7",
                "type": "application/vnd.sas.job.execution.job",
                "responseType": "application/vnd.sas.job.execution.job"
            },
            {
                "method": "DELETE",
                "rel": "delete",
                "href": "/jobExecution/jobs/8de1791f-6fb1-4a71-b674-adfc642c84b7",
                "uri": "/jobExecution/jobs/8de1791f-6fb1-4a71-b674-adfc642c84b7"
            },
            {
                "method": "PUT",
                "rel": "updateState",
                "href": "/jobExecution/jobs/8de1791f-6fb1-4a71-b674-adfc642c84b7/state",
                "uri": "/jobExecution/jobs/8de1791f-6fb1-4a71-b674-adfc642c84b7/state",
                "type": "text/plain"
            },
            {
                "method": "POST",
                "rel": "updateHeartbeatTimeStamp",
                "href": "/jobExecution/jobs/8de1791f-6fb1-4a71-b674-adfc642c84b7/heartbeatTimeStamp",
                "uri": "/jobExecution/jobs/8de1791f-6fb1-4a71-b674-adfc642c84b7/heartbeatTimeStamp",
                "type": "text/plain"
            },
            {
                "method": "GET",
                "rel": "jobDefinition",
                "href": "/jobDefinitions/definitions/3ea0e5c9-2641-488e-b4bf-9e181e6a682a",
                "uri": "/jobDefinitions/definitions/3ea0e5c9-2641-488e-b4bf-9e181e6a682a",
                "type": "application/vnd.sas.job.definition"
            }
        ]
    }
    ```
    </details>

    <details>
    <summary>Log</summary>

    ```
    source: 1    filename jobfldr filesrvc folderPath = '/Public'; %include jobfldr ('WriteFishSQLOIDC.sas');
    note: NOTE: The quoted string currently being processed has become more than 262 bytes long.  You might have unbalanced quotation marks.
    note: NOTE: Libref SQLLIB was successfully assigned as follows: 
    note:       Engine:        SQLSVR 
    note:       Physical Name: 
    note: NOTE: Table SQLLIB.fish has been dropped.
    note: NOTE: PROC SQL statements are executed immediately; The RUN statement has no effect.
    note: NOTE: PROCEDURE SQL used (Total process time):
    note:       real time           0.32 seconds
    note:       cpu time            0.06 seconds
    note:       
    note: 
    note: 
    note: NOTE: There were 159 observations read from the data set SASHELP.FISH.
    note: NOTE: The data set SQLLIB.fish has 159 observations and 7 variables.
    note: NOTE: The data set WORK.REPLACE has 159 observations and 7 variables.
    note: NOTE: DATA statement used (Total process time):
    note:       real time           0.36 seconds
    note:       cpu time            0.06 seconds
    note:       
    note: 
    note: NOTE: Libref SQLLIB has been deassigned.
    note: 
    ```

</details>

As you can see in the log, the connection was made without accessing the SAS Viya Credentials service. It uses the authentication context already available in the compute session.

The [final section](./closing.md) will have some closing remarks.

[^1]: Creating logins or executing any other query on the master database is currently not supported in the Azure portal.