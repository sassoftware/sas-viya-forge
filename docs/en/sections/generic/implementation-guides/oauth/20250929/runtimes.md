# SAS Runtime usage

The SAS Viya platforms offers three run-time servers:

1. SAS Programming Run-Time Server

The SAS Programming Runtime Engine is the compute server for the SAS Viya platform. The SAS Programming Runtime Engine can be thought of as equivalent to the SAS Workspace Server in SAS 9.4[^1]

2. SAS Cloud Analytic Server

SAS Cloud Analytics Services (CAS) is an in-memory engine that can spread the data across all threads on all CAS worker nodes. The processing is distributed and parallel. \
CAS is an alternative compute engine within the SAS Viya platform that is tailored to calculations involving very large data sets. Such calculations benefit from large-scale parallelization. CAS is used by SAS Visual Analytics, SAS Visual Data Mining and Machine Learning, and other SAS products.[^1]

3. SAS Micro Analytic Server

SAS Micro Analytic Service is a stateless, memory-resident, high-performance program execution service. Users of SAS Event Stream Processing or SAS Intelligent Decisioning can publish SAS analytics, such as predictive models that were created with a variety of SAS products and analytical procedures. They can also author custom programs using the SAS DS2 or Python programming languages or in the SAS Intelligent Decisioning web application.[^2]

4. SAS Event Stream Processing Server.

SAS Event Stream Processing enables you to quickly process and analyze streaming data. Real-time, high throughput, low latency data flows are called event streams. Event stream processing projects can perform real-time analytics on event streams.[^3]


Note that SAS also includes an Event Stream Processing server that can be seen as a run-time server. 


## Runtime APIs

The different run-time servers all offer API endpoints that can be used to communicate with them. In this document we will only discuss the SAS Programming Run-Time Server and the SAS Cloud Analytic Server. The reason is that these servers need to run as a user that is valid outside of the SAS platform as well in order to be able to interact with the filesystem for example. Therefore there are additional steps that need to be taken to enable an OAuth client to use these APIs.

The Micro Analytic Server and Event Stream Processing server do not have this requirement and can therefore be used like any other API within the Viya platform. The REST API documentation for the Micro Analytic Server can be found [here](https://developer.sas.com/rest-apis/microanalyticScore). Event stream processing usually happens through a publish/subscriber model that integrates with several [connectors and adapters](https://go.documentation.sas.com/doc/en/espcdc/default/espca/p1swscq8yglnunn1p44y46w2rjtx.htm) and direct API usage is therefore not required. Should you be interested in using it directly by using the API, details can be found [here](https://go.documentation.sas.com/doc/en/espcdc/default/esppsapi/titlepage.htm) and [here](https://go.documentation.sas.com/doc/en/espcdc/default/espws/titlepage.htm).

## SAS Programming Run-Time Server

The SAS Programming Run-Time Server executes SAS code. SAS code is executed in compute sessions. SAS code can be run on a compute session in a variety of ways. These include:
- Directly submitting code to a session
- Submitting a job that contains SAS code
- Submitting a job flow that contains one or more jobs

Independent of the way in which SAS code is provided to the SAS Programming Run-Time Server, we first need to make sure there is a valid user to run the compute session. There are two ways to enable an OAuth client to run a compute session as user:

1. **Using a compute context that runs under a shared account**  
This option creates a dedicated [Compute Context](https://go.documentation.sas.com/doc/en/sasadmincdc/default/calsrvpgm/p137sodav4z72nn1scp9ccanzpf7.htm#n1tjmnfsphx25qn1ll62hrwf2eq8) which executes all programs submitted to it under a shared account. \
The advantage of this approach is that any client who has access to this compute context, including OAuth clients, can execute SAS programs as this user. No further setup is required. It also allows you to configure [Reusable Compute Servers](https://go.documentation.sas.com/doc/en/sasadmincdc/default/calsrvpgm/p059rp0q82tvpzn1hk9x26486do5.htm#n18kjcb5hwt0wmn1xtm1ccf8httu) to reduce the amount of time it takes to start a new compute session.  
The disadvantage is that there is no way of controlling which user is executing a particular job as it is always the same. If you need distinct users for different jobs, you need to create a Compute Context for each of those. This does not scale well.

2. **Obtaining an access token for a shared account and using this when interacting with the API**  
This option does not require any modification to existing Compute Contexts or new Compute Contexts to be created. In stead, the access token allows the OAuth client to start compute sessions as the service account directly. The disadvantage is that the application that is using the OAuth client to interact with SAS Viya needs to be set-up to obtain an access token for the service account before it can call a SAS Viya API.

It might seem that there is a third option, namely using a [Group-Managed Service Account](https://go.documentation.sas.com/doc/en/sasadmincdc/default/caljobs/n1n032p2t4a65gn1unv4gazmlx7x.htm). A Group-Managed Service Account enables members of a scheduling group to execute or schedule a job or job flow under a service account. However, this feature is only available to actual users in the Viya environment and cannot be used by OAuth clients.

### Service Account
As described above, compute sessions running on a SAS Programming Run-Time server need to be run as an actual user. This means that this user account needs to be available in the identity provider that you configured for your SAS Viya environment. This can either be a [SCIM client](https://go.documentation.sas.com/doc/en/sasadmincdc/default/calids/n1rl3gjjjqmxmfn1hw9ebjjz5778.htm) or an [LDAP server](https://go.documentation.sas.com/doc/en/sasadmincdc/default/calids/n1aw4xnkvwcddnn1mv8lxr2e4tu7.htm). Next to this, this service account also needs to be able to authenticate to the environment using the authentication provider you set up. This is required to either:
* store its access token and refresh token for use by the compute context running under the service account
* allow an OAuth client to obtain an access token directly before interacting with the API

### Using a Compute Context using a Shared Account

The process of configuring a compute context to use a shared account is documented [here](https://go.documentation.sas.com/doc/en/sasadmincdc/default/calsrvpgm/p059rp0q82tvpzn1hk9x26486do5.htm#p1t5ysle4s46yln1nkt5mvqgcpka). However, to provide a more complete example we will combine this with the creation of a dedicated Compute Context as described [here](https://go.documentation.sas.com/doc/en/sasadmincdc/default/calsrvpgm/n1gak6r1ar6clfn11ap10j7s637d.htm).

We will utilize the Viya CLI as much as possible.

#### Prerequisites
We need to ensure we have two things in place:
1. A Service Account to run the compute sessions under in this Compute Context
2. A group which we can assign to users that grants permission to use the Compute Context

Asuming you are authenticated as an administrator using in the SAS Viya platform, let's verify these exist.
In our environment we have the following Service Account:

<details>
<summary>Viya CLI Command</summary>

```
sas-viya identities show-user --id sasshared@contoso.onmicrosoft.com
```

</details>

<details>
<summary>Viya CLI Response</summary>

```
Id                  sasshared@contoso.onmicrosoft.com
Name                SAS Shared
Title
EmailAddresses      [map[value:sasshared@contoso.onmicrosoft.com]]
PhoneNumbers        []
Addresses           []
State               active
ProviderId          scim
CreationTimeStamp   2025-01-28T12:52:57.432Z
ModifiedTimeStamp   2025-01-28T12:52:57.432Z
```

</details>  
We also have a group which we can assign to users and oauth clients:
  
<details>
<summary>Viya CLI Command</summary>

```
sas-viya --profile decboard identities show-group --id SharedContextUsers
```

</details>
<details>
<summary>Viya CLI Response</summary>

```
Id                  SharedContextUsers
Name                Shared Context Users
Description         Members of this group have access to the Shared Compute Context
State               active
ProviderId          local
CreationTimeStamp   2025-01-28T12:56:00.247Z
ModifiedTimeStamp   2025-01-28T12:56:00.247Z
```

</details>

#### Creating a new Compute Context

Asuming you are authenticated as an administrator using in the SAS Viya platform, first create a template file:
```
sas-viya compute contexts generate-template --file compute_context_template.json
```
The template will look like this:
<details>
<summary>Template</summary>

```
{
  "name": "MyApp",
  "version": 1,
  "description": "My Application Context",
  "attributes": {
      "sessionInactiveTimeout": 60 
   },
  "launchContext": {
      "contextName": "compsrv"
   },
   "launchType": "service",
   "authorizedUsers": [ 
      "myUser"
   ],
  "mediaTypeMap": {
      "csv": "application/vnd.ms-excel"
   }
}
```

</details>

For the purpose of this example, we modify the template to look like this:

<details>
<summary>Modified Template</summary>

```
{
  "name": "Shared Compute Context",
  "version": 1,
  "description": "A shared compute context",
  "attributes": {
      "sessionInactiveTimeout": 60,
      "runServerAs": "sasshared@contoso.onmicrosoft.com"
   },
  "launchContext": {
      "contextName": "SAS Job Execution launcher context"
   },
   "launchType": "service",
   "authorizedGroups": [ 
      "SharedContextUsers"
   ]
}
```

</details>

Note that for the [Launcher Context](https://go.documentation.sas.com/doc/en/sasadmincdc/default/calsrvpgm/n01004viyaprgmsrvs00000admin.htm) we chose the existing SAS Job Execution launcher context as we will be submitting jobs to this Compute Context. Creating a dedicated Launcher Context is also possible. This is documented [here](https://go.documentation.sas.com/doc/en/sasadmincdc/default/calsrvpgm/n1kpmvcirigs4gn1ro6om35ghimm.htm).  
To configure this context to run under a shared account, we added the runServerAs attribute. The value of this attribute should be set to the user ID of the user you want to configure. In our case this is sasshared@contoso.onmicrosoft.com as we saw in the Prerequisites section. Also take note of the SharedContextUsers group that we saw earlier which is added to the authorizedGroups list.

For all options that can be specified in this template, please refer to the documentation [here](https://developer.sas.com/rest-apis/compute/createContext).

We now create the new Compute Context using the following command:
```
sas-viya --output json compute contexts create --data @compute_context_template.json --raw
```
You should see something like the following:
```
{
    "description": "A shared compute context",
    "id": "1c3ece67-4476-4cd2-b1ed-d81152b8f59c",
    "launchType": "service",
    "name": "Shared Compute Context"
}
```

#### Store the credentials of the Shared Account

There are two ways of storing the credentials of the Shared Account. The first way is to have an administrator store the username and password of this account. This is only possible when your environment is configured to authenticate against LDAP. The second way can be used regardless of your authentication provider, which is why this is the way we will use in this example.

First, add the Shared Account to the ComputeServiceAccountUsers group. This is a predefined [custom group](https://go.documentation.sas.com/doc/en/sasadmincdc/default/calids/p0ata1oqy9v7nan188h1k254doxq.htm#p1cu94m9lbxjbpn16hlpd7hupm50) within the SAS Viya platform that grants members the permissions to create a shared credential.
```
sas-viya identities add-member --group-id ComputeServiceAccountUsers --user-member-id sasshared@contoso.onmicrosoft.com
```
```
sasshared@contoso.onmicrosoft.com has been added to group ComputeServiceAccountUsers
```
Next, log out of the sas-viya CLI as the administrator user you have been using so far and re-authenticate as the Shared Account.
```
sas-viya auth logout
sas-viya auth loginCode
```
```
Logout succeeded.
Login succeeded. Token saved.
```
Now that you are logged in as the Shared Account, register the access token and refresh token of this account:
```
sas-viya compute credentials create --domain-type oauth2.0
```
```
The shared service account credential for sasshared@contoso.onmicrosoft.com was created successfully.
```

### Executing a job on the Shared Compute Context

Now that we have everything in place to execute a job on the Shared Compute Context. We will use the SAS program we retrieved in the Authorization & API Interaction chapter as an example of a piece of SAS code we want to execute as a job.

There are three important definitions to bear in mind:
- Job definition. A job definition contains information about a job such as the code, the job type, and job parameters. A job definition is identified by its job-definition ID.
- Job request. A job request contains a job definition plus runtime information (such as values for prompts and the compute context). Job requests enable job definitions to be scheduled and executed.
- Job-request instance. Job requests can run multiple times. Each time a job request is scheduled or executed, a job-request instance is created. A job-request instance is identified by its job-request-instance ID.

In short, we need to create a job definition containing the SAS code we want to run. We can then create a job request, which is where we will add the Compute Context that we want this job to run in. Finally, we can then submit the job for execution.

1. Creating the job definition.

    To create the job definition, we use the jobDefinitions service' [definitions endpoint](https://developer.sas.com/rest-apis/jobDefinitions/createJobDefinition).

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
    --data '{
    "version": 2,
    "name": "Simple proc setinit",
    "description": "Show the current licensed SAS software",
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
    "code": "proc setinit; run;"
    }'
    ```

    </details>

    <details>
    <summary>API Response</summary>

    ```
    {
        "creationTimeStamp":"2025-01-28T14:24:52.146Z",
        "modifiedTimeStamp":"2025-01-28T14:24:52.146Z",
        "createdBy":"finance-frontend",
        "modifiedBy":"finance-frontend",
        "version":2,
        "id":"3bfab632-35d7-4d5f-93d6-82de3117d0be",
        "name":"Simple proc setinit",
        "description":"Show the current licensed SAS software",
        "type":"Compute",
        "parameters":[
            {
                "version":1,
                "name":"_contextName",
                "defaultValue":"SAS Job Execution compute context",
                "type":"CHARACTER","label":
                "Context Name",
                "required":false
            }
        ],
        "code":"proc setinit; run;",
        "links":[
            {
                "method":"GET",
                "rel":"self",
                "href":"/jobDefinitions/definitions/3bfab632-35d7-4d5f-93d6-82de3117d0be",
                "uri":"/jobDefinitions/definitions/3bfab632-35d7-4d5f-93d6-82de3117d0be",
                "type":"application/vnd.sas.job.definition"
            },
            {
                "method":"GET",
                "rel":"alternate",
                "href":"/jobDefinitions/definitions/3bfab632-35d7-4d5f-93d6-82de3117d0be",
                "uri":"/jobDefinitions/definitions/3bfab632-35d7-4d5f-93d6-82de3117d0be",
                "type":"application/vnd.sas.summary"
            },
            {
                "method":"PUT",
                "rel":"update",
                "href":"/jobDefinitions/definitions/3bfab632-35d7-4d5f-93d6-82de3117d0be",
                "uri":"/jobDefinitions/definitions/3bfab632-35d7-4d5f-93d6-82de3117d0be",
                "type":"application/vnd.sas.job.definition",
                "responseType":"application/vnd.sas.job.definition"
            },
            {
                "method":"DELETE",
                "rel":"delete",
                "href":"/jobDefinitions/definitions/3bfab632-35d7-4d5f-93d6-82de3117d0be",
                "uri":"/jobDefinitions/definitions/3bfab632-35d7-4d5f-93d6-82de3117d0be"
            }
        ]
    }
    ```
    </details>

    Note that the contextName that is provided in the job definition is just defining that you can definie a contextName when creating the job request. It sets the default value to the SAS Job Execution compute context. We will override this default in the job request.
    The id field in the response is used in the subsequent job request to reference this job definition.

2. Creating the job request.

    To create the job request, we use the jobExecution service' [jobRequests endpoint](https://developer.sas.com/rest-apis/jobExecution/createJobRequest).

    <details>
    <summary>API Call</summary>

    ```
    INGRESS_URL=https://hostname.example.com

    curl --request POST \
    --url "${INGRESS_URL}/jobExecution/jobRequests" \
    --header 'Accept: application/json, application/vnd.sas.job.execution.job.request+json, application/vnd.sas.error+json' \
    --header "Authorization: Bearer $OAUTH_TOKEN" \
    --header 'Content-Type: application/json' \
    --data '{
    "name": "Proc setinit shared",
    "description": "Execute proc setinit on a shared compute context",
    "jobDefinitionUri": "/jobDefinitions/definitions/3bfab632-35d7-4d5f-93d6-82de3117d0be",
    "arguments": {
        "_contextName": "Shared Compute Context"
    },
    "createdByApplication": "finance-frontend"
    }'
    ```
    </details>

    <details>
    <summary>API Response</summary>

    ```
    {
        "creationTimeStamp": "2025-02-13T09:42:35.937Z",
        "modifiedTimeStamp": "2025-02-13T09:42:35.937Z",
        "createdBy": "finance-frontend",
        "modifiedBy": "finance-frontend",
        "version": 3,
        "id": "b6f0cead-b7d7-40c5-9864-bbdb7c6f8962",
        "name": "Proc setiniit shared",
        "description": "Execute proc setinit on a shared compute context",
        "jobDefinitionUri": "/jobDefinitions/definitions/3bfab632-35d7-4d5f-93d6-82de3117d0be",
        "arguments": {
            "_contextName": "Shared Compute Context"
        },
        "properties": [],
        "createdByApplication": "finance-frontend",
        "links": [
            {
                "method": "GET",
                "rel": "self",
                "href": "/jobExecution/jobRequests/b6f0cead-b7d7-40c5-9864-bbdb7c6f8962",
                "uri": "/jobExecution/jobRequests/b6f0cead-b7d7-40c5-9864-bbdb7c6f8962",
                "type": "application/vnd.sas.job.execution.job.request"
            },
            {
                "method": "GET",
                "rel": "alternate",
                "href": "/jobExecution/jobRequests/b6f0cead-b7d7-40c5-9864-bbdb7c6f8962",
                "uri": "/jobExecution/jobRequests/b6f0cead-b7d7-40c5-9864-bbdb7c6f8962",
                "type": "application/vnd.sas.summary"
            },
            {
                "method": "GET",
                "rel": "export",
                "href": "/jobExecution/jobRequests/b6f0cead-b7d7-40c5-9864-bbdb7c6f8962",
                "uri": "/jobExecution/jobRequests/b6f0cead-b7d7-40c5-9864-bbdb7c6f8962",
                "type": "application/vnd.sas.transfer.object"
            },
            {
                "method": "DELETE",
                "rel": "delete",
                "href": "/jobExecution/jobRequests/b6f0cead-b7d7-40c5-9864-bbdb7c6f8962",
                "uri": "/jobExecution/jobRequests/b6f0cead-b7d7-40c5-9864-bbdb7c6f8962"
            },
            {
                "method": "PUT",
                "rel": "update",
                "href": "/jobExecution/jobRequests/b6f0cead-b7d7-40c5-9864-bbdb7c6f8962",
                "uri": "/jobExecution/jobRequests/b6f0cead-b7d7-40c5-9864-bbdb7c6f8962",
                "type": "application/vnd.sas.job.execution.job.request"
            },
            {
                "method": "PUT",
                "rel": "import",
                "href": "/jobExecution/jobRequests/b6f0cead-b7d7-40c5-9864-bbdb7c6f8962",
                "uri": "/jobExecution/jobRequests/b6f0cead-b7d7-40c5-9864-bbdb7c6f8962",
                "type": "application/vnd.sas.transfer.object",
                "responseType": "application/vnd.sas.summary"
            },
            {
                "method": "GET",
                "rel": "up",
                "href": "/jobExecution/jobRequests",
                "uri": "/jobExecution/jobRequests",
                "type": "application/vnd.sas.collection",
                "itemType": "application/vnd.sas.job.execution.job.request"
            },
            {
                "method": "GET",
                "rel": "jobs",
                "href": "/jobExecution/jobRequests/b6f0cead-b7d7-40c5-9864-bbdb7c6f8962/jobs",
                "uri": "/jobExecution/jobRequests/b6f0cead-b7d7-40c5-9864-bbdb7c6f8962/jobs",
                "type": "application/vnd.sas.collection",
                "itemType": "application/vnd.sas.job.execution.job"
            },
            {
                "method": "POST",
                "rel": "submitJob",
                "href": "/jobExecution/jobRequests/b6f0cead-b7d7-40c5-9864-bbdb7c6f8962/jobs",
                "uri": "/jobExecution/jobRequests/b6f0cead-b7d7-40c5-9864-bbdb7c6f8962/jobs",
                "responseType": "application/vnd.sas.job.execution.job"
            }
        ]
    }
    ```
    </details>

    We again need to take note of the id returned by API. This is the id we need to provide in our final API call to submit the job request for execution.

3. Submitting the job request.

    To submit the job request for execution, we use the jobExecution service' [jobRequestsJobs endpoint](https://developer.sas.com/rest-apis/jobExecution/createJobRequestJob).

    <details>
    <summary>API Call</summary>

    ```
    INGRESS_URL=https://hostname.example.com

    curl --request POST \
    --url "${INGRESS_URL}/jobExecution/jobRequests/b6f0cead-b7d7-40c5-9864-bbdb7c6f8962/jobs" \
    --header 'Accept: application/json, application/vnd.sas.job.execution.job+json, application/vnd.sas.error+json' \
    --header "Authorization: Bearer $OAUTH_TOKEN"
    ```
    </details>

    <details>
    <summary>API Response</summary>
    ```
    {
        "creationTimeStamp": "2025-02-13T09:43:25.030Z",
        "modifiedTimeStamp": "2025-02-13T09:43:25.078Z",
        "createdBy": "finance-frontend",
        "modifiedBy": "finance-frontend",
        "version": 4,
        "id": "cd2931a7-7c7d-4677-98e3-7a3e3d0628a1",
        "jobRequest": {
            "creationTimeStamp": "2025-02-13T09:42:35.937Z",
            "modifiedTimeStamp": "2025-02-13T09:42:35.937Z",
            "createdBy": "finance-frontend",
            "modifiedBy": "finance-frontend",
            "version": 3,
            "id": "b6f0cead-b7d7-40c5-9864-bbdb7c6f8962",
            "name": "Proc setiniit shared",
            "description": "Execute proc setinit on a shared compute context",
            "jobDefinitionUri": "/jobDefinitions/definitions/3bfab632-35d7-4d5f-93d6-82de3117d0be",
            "jobDefinition": {
                "creationTimeStamp": "2025-01-29T13:26:50.368Z",
                "modifiedTimeStamp": "2025-01-29T13:26:50.372Z",
                "createdBy": "finance-frontend",
                "modifiedBy": "finance-frontend",
                "version": 2,
                "id": "3bfab632-35d7-4d5f-93d6-82de3117d0be",
                "name": "Simple proc setinit",
                "description": "Show the current licensed SAS software",
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
                "code": "proc setinit; run;",
                "links": [
                    {
                        "method": "GET",
                        "rel": "self",
                        "href": "/jobDefinitions/definitions/3bfab632-35d7-4d5f-93d6-82de3117d0be",
                        "uri": "/jobDefinitions/definitions/3bfab632-35d7-4d5f-93d6-82de3117d0be",
                        "type": "application/vnd.sas.job.definition"
                    },
                    {
                        "method": "GET",
                        "rel": "alternate",
                        "href": "/jobDefinitions/definitions/3bfab632-35d7-4d5f-93d6-82de3117d0be",
                        "uri": "/jobDefinitions/definitions/3bfab632-35d7-4d5f-93d6-82de3117d0be",
                        "type": "application/vnd.sas.summary"
                    },
                    {
                        "method": "PUT",
                        "rel": "update",
                        "href": "/jobDefinitions/definitions/3bfab632-35d7-4d5f-93d6-82de3117d0be",
                        "uri": "/jobDefinitions/definitions/3bfab632-35d7-4d5f-93d6-82de3117d0be",
                        "type": "application/vnd.sas.job.definition",
                        "responseType": "application/vnd.sas.job.definition"
                    },
                    {
                        "method": "DELETE",
                        "rel": "delete",
                        "href": "/jobDefinitions/definitions/3bfab632-35d7-4d5f-93d6-82de3117d0be",
                        "uri": "/jobDefinitions/definitions/3bfab632-35d7-4d5f-93d6-82de3117d0be"
                    }
                ]
            },
            "arguments": {
                "_contextName": "Shared Compute Context"
            },
            "properties": [],
            "createdByApplication": "finance-frontend",
            "links": [
                {
                    "method": "GET",
                    "rel": "self",
                    "href": "/jobExecution/jobRequests/b6f0cead-b7d7-40c5-9864-bbdb7c6f8962",
                    "uri": "/jobExecution/jobRequests/b6f0cead-b7d7-40c5-9864-bbdb7c6f8962",
                    "type": "application/vnd.sas.job.execution.job.request"
                }
            ]
        },
        "state": "running",
        "heartbeatTimeStamp": "2025-02-13T09:43:25.074Z",
        "submittedByApplication": "finance-frontend",
        "heartbeatInterval": 600,
        "elapsedTime": 63,
        "results": {},
        "links": [
            {
                "method": "GET",
                "rel": "self",
                "href": "/jobExecution/jobs/cd2931a7-7c7d-4677-98e3-7a3e3d0628a1",
                "uri": "/jobExecution/jobs/cd2931a7-7c7d-4677-98e3-7a3e3d0628a1",
                "type": "application/vnd.sas.job.execution.job"
            },
            {
                "method": "GET",
                "rel": "state",
                "href": "/jobExecution/jobs/cd2931a7-7c7d-4677-98e3-7a3e3d0628a1/state",
                "uri": "/jobExecution/jobs/cd2931a7-7c7d-4677-98e3-7a3e3d0628a1/state",
                "type": "text/plain"
            },
            {
                "method": "PUT",
                "rel": "update",
                "href": "/jobExecution/jobs/cd2931a7-7c7d-4677-98e3-7a3e3d0628a1",
                "uri": "/jobExecution/jobs/cd2931a7-7c7d-4677-98e3-7a3e3d0628a1",
                "type": "application/vnd.sas.job.execution.job",
                "responseType": "application/vnd.sas.job.execution.job"
            },
            {
                "method": "DELETE",
                "rel": "delete",
                "href": "/jobExecution/jobs/cd2931a7-7c7d-4677-98e3-7a3e3d0628a1",
                "uri": "/jobExecution/jobs/cd2931a7-7c7d-4677-98e3-7a3e3d0628a1"
            },
            {
                "method": "PUT",
                "rel": "updateState",
                "href": "/jobExecution/jobs/cd2931a7-7c7d-4677-98e3-7a3e3d0628a1/state",
                "uri": "/jobExecution/jobs/cd2931a7-7c7d-4677-98e3-7a3e3d0628a1/state",
                "type": "text/plain"
            },
            {
                "method": "POST",
                "rel": "updateHeartbeatTimeStamp",
                "href": "/jobExecution/jobs/cd2931a7-7c7d-4677-98e3-7a3e3d0628a1/heartbeatTimeStamp",
                "uri": "/jobExecution/jobs/cd2931a7-7c7d-4677-98e3-7a3e3d0628a1/heartbeatTimeStamp",
                "type": "text/plain"
            },
            {
                "method": "GET",
                "rel": "jobRequest",
                "href": "/jobExecution/jobRequests/b6f0cead-b7d7-40c5-9864-bbdb7c6f8962",
                "uri": "/jobExecution/jobRequests/b6f0cead-b7d7-40c5-9864-bbdb7c6f8962",
                "type": "application/vnd.sas.job.execution.job.request"
            },
            {
                "method": "GET",
                "rel": "jobDefinition",
                "href": "/jobDefinitions/definitions/3bfab632-35d7-4d5f-93d6-82de3117d0be",
                "uri": "/jobDefinitions/definitions/3bfab632-35d7-4d5f-93d6-82de3117d0be",
                "type": "application/vnd.sas.job.definition"
            }
        ]
    }
    ```

4. Retrieving the job state

    Job request submissions are asynchronous. We can use the [state endpoint](https://developer.sas.com/rest-apis/jobExecution-v7/getJobState) of a job request instance to query its state:
    <details>
    <summary>API Call</summary>

    ```
    curl --request GET \
    --url "${INGRESS_URL}/jobExecution/jobs/cd2931a7-7c7d-4677-98e3-7a3e3d0628a1/state" \
    --header 'Accept: text/plain' \
    --header "Authorization: Bearer $OAUTH_TOKEN"
    ```

    </details>
    <details>
    <summary>API Response</summary>

    ```
    completed
    ```
    </details>

### Obtaining an access token for a service account

Obtaining an access token for service account can be done in two different ways. By manually authenticating once and using the obtained refresh token to obtain access tokens or by authenticating to your authentication provider and obtaining an access token prior to authenticating to SAS Viya. The second option is only available if you have a way to authenticate the service account non-interactively with your authentication provider. The first option is always available and although it requires a manual authentication step, this is only required once and can therefore be incorporated into the setup procedure of the environment.

#### Creating an OAuth client

In the initial section of this document, we created an OAuth client with the client-credentials grant type. This OAuth client cannot be used to obtain access tokens for a service account as this requires two different grant types:

* refresh token
* JWT bearer token

Therefore, we have to create our OAuth client slightly differently and given that the SAS Viya CLI does not support registering OAuth clients with the JWT bearer token grant type, we have to use the REST API for this.

1. Authenticate to the Viya environment as a user in the SAS Administrator group

    <details>
    <summary>API Call</summary>

    ```
    INGRESS_URL='https://hostname.example.com'
    SASBOOT_PASSWORD='s@sb00t'
    SASBOOT_PASSWORD_ENCODED=$(echo -n "${SASBOOT_PASSWORD}" | jq -sRr @uri)

    BEARER_TOKEN=$(curl -skX POST "${INGRESS_URL}/SASLogon/oauth/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "client_id=sas.cli&grant_type=password&username=sasboot&password=${SASBOOT_PASSWORD_ENCODED}" \
    | jq -r ."access_token")
    ```

    </details>

2. Register the OAuth client

    <details>
    <summary>API Call</summary>

    ```
    curl -sk -X POST "${INGRESS_URL}/SASLogon/oauth/clients" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $BEARER_TOKEN" \
    -d '{
        "client_id": "finance-frontend",
        "client_secret": "verysecret",
        "scope": ["openid","uaa.user"],
        "authorities": ["uaa.none"],
        "autoapprove": ["openid","uaa.user"],
        "authorized_grant_types": ["urn:ietf:params:oauth:grant-type:jwt-bearer","refresh_token"],
        "refresh_token_validity": 7776000
    }'
    ```

    </details>

    <details>
    <summary>API Response</summary>

    ```
    {
        "scope": [
            "openid",
            "uaa.user"
        ],
        "client_id": "finance-frontend",
        "resource_ids": [
            "none"
        ],
        "authorized_grant_types": [
            "refresh_token",
            "urn:ietf:params:oauth:grant-type:jwt-bearer"
        ],
        "autoapprove": [
            "openid",
            "uaa.user"
        ],
        "refresh_token_validity": 7776000,
        "authorities": [
            "uaa.none"
        ],
        "lastModified": 1743510032132,
        "required_user_groups": []
    }
    ```

    </details>

#### Obtaining an initial access token

Now that we have a properly configured OAuth client, we can use it to obtain access tokens for the service account.

1. Authenticate to the Viya environment as the service account using the CLI:

    ```
    sas-viya auth loginCode
    ```


    You will be asked to authenticate. Authenticate as the service account.
2. Obtain the refresh token

    ```
    INITIAL_REFRESH_TOKEN=$(cat ~/.sas/credentials.json |jq -r '."Default"."refresh-token"')
    ```

    Note that if you use a profile with the SAS Viya CLI, substitute "Default" with the name of your profile.

3. Obtain an access token

    <details>
    <summary>API Call</summary>

    ```
    INITIAL_ACCESS_TOKEN=$(curl -sk -X POST "${INGRESS_URL}/SASLogon/oauth/token" \
    -H 'Accept: application/json' \
    -H 'Content-Type: application/x-www-form-urlencoded' \
    --data-urlencode "client_id=sas.cli" \
    --data-urlencode "grant_type=refresh_token" \
    --data-urlencode "response_type=token" \
    --data-urlencode "scope=openid" \
    --data-urlencode "refresh_token=${INITIAL_REFRESH_TOKEN}" \
    |jq -r '."access_token"')
    ```

    </details>

#### Renewing the refresh token and obtaining access tokens

With the initial access token obtained with the prevous API call, we can now obtain refresh tokens in a way that is repeatable. The difference between the initial refresh token and the refresh token we will obtain next is that the first refresh token was bound to the default sas.cli OAuth client, whilst this new refresh token will be bound to our custom "finance-fronted" OAuth client.

1. Obtain a new refresh token

    <details>
    <summary>API Call</summary>

    ```
    ACCESS_TOKEN=$INITIAL_ACCESS_TOKEN # This line is only required the first time you execute this call

    REFRESH_TOKEN=$(curl -sk -X POST "${INGRESS_URL}/SASLogon/oauth/token" \
    -H 'Accept: application/json' \
    -H 'Content-Type: application/x-www-form-urlencoded' \
    --data-urlencode "client_id=finance-frontend" \
    --data-urlencode "client_secret=verysecret" \
    --data-urlencode "grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer" \
    --data-urlencode "response_type=token" \
    --data-urlencode "scope=openid" \
    --data-urlencode "assertion=${ACCESS_TOKEN}" \
    |jq -r '."refresh_token"')
    ```

    </details>

2. Obtain an access token with the refresh token

    <details>
    <summary>API Call</summary>

    ```
    ACCESS_TOKEN=$(curl -sk -X POST "${INGRESS_URL}/SASLogon/oauth/token" \
    -H 'Accept: application/json' \
    -H 'Content-Type: application/x-www-form-urlencoded' \
    --data-urlencode "client_id=finance-frontend" \
    --data-urlencode "client_secret=verysecret" \
    --data-urlencode "grant_type=refresh_token" \
    --data-urlencode "response_type=token" \
    --data-urlencode "scope=openid" \
    --data-urlencode "refresh_token=${REFRESH_TOKEN}" \
    |jq -r '."access_token"')
    ```

    </details>

As you can see, you can obtain new refresh tokens with the access tokens already in your posession. This means that as long as you renew the refresh token before it has expired (which would block you from generating the access token required to renew it) there is no further human intervention required.

### Executing a job using an access token for a service account

Now that we have an access token, we can use it to execute a job using the Viya APIs. This works in exactly the same way as executing a job on a shared compute context, but now we do not have to use a dedicated compute context for this. Note though, that although the API calls are the same, they are now all executed as the service account. That means that any permissions that are required to create jobs and job requests need to be assigned to the service account instead of to the OAuth client.


1. Creating the job definition.

    <details>
    <summary>API Call</summary>

    ```
    INGRESS_URL=https://hostname.example.com
    OAUTH_TOKEN=$ACCESS_TOKEN

    curl --request POST \
    --url "${INGRESS_URL}/jobDefinitions/definitions" \
    --header 'Accept: application/json, application/vnd.sas.job.definition+json' \
    --header "Authorization: Bearer $OAUTH_TOKEN" \
    --header 'Content-Type: application/json' \
    --header 'accept: ' \
    --data '{
    "version": 2,
    "name": "Simple proc setinit",
    "description": "Show the current licensed SAS software",
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
    "code": "proc setinit; run;"
    }'
    ```

    </details>

    <details>
    <summary>API Response</summary>

    ```
    {
        "creationTimeStamp": "2025-04-01T13:28:01.058Z",
        "modifiedTimeStamp": "2025-04-01T13:28:01.061Z",
        "createdBy": "sasshared@contoso.onmicrosoft.com",
        "modifiedBy": "sasshared@contoso.onmicrosoft.com",
        "version": 2,
        "id": "bbf8e264-f7c7-436a-a852-e07852704a07",
        "name": "Simple proc setinit",
        "description": "Show the current licensed SAS software",
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
        "code": "proc setinit; run;",
        "links": [
            {
                "method": "GET",
                "rel": "self",
                "href": "/jobDefinitions/definitions/bbf8e264-f7c7-436a-a852-e07852704a07",
                "uri": "/jobDefinitions/definitions/bbf8e264-f7c7-436a-a852-e07852704a07",
                "type": "application/vnd.sas.job.definition"
            },
            {
                "method": "GET",
                "rel": "alternate",
                "href": "/jobDefinitions/definitions/bbf8e264-f7c7-436a-a852-e07852704a07",
                "uri": "/jobDefinitions/definitions/bbf8e264-f7c7-436a-a852-e07852704a07",
                "type": "application/vnd.sas.summary"
            },
            {
                "method": "PUT",
                "rel": "update",
                "href": "/jobDefinitions/definitions/bbf8e264-f7c7-436a-a852-e07852704a07",
                "uri": "/jobDefinitions/definitions/bbf8e264-f7c7-436a-a852-e07852704a07",
                "type": "application/vnd.sas.job.definition",
                "responseType": "application/vnd.sas.job.definition"
            },
            {
                "method": "DELETE",
                "rel": "delete",
                "href": "/jobDefinitions/definitions/bbf8e264-f7c7-436a-a852-e07852704a07",
                "uri": "/jobDefinitions/definitions/bbf8e264-f7c7-436a-a852-e07852704a07"
            }
        ]
    }
    ```
    </details>

2. Creating the job request.

    <details>
    <summary>API Call</summary>

    ```
    INGRESS_URL=https://hostname.example.com

    curl --request POST \
    --url "${INGRESS_URL}/jobExecution/jobRequests" \
    --header 'Accept: application/json, application/vnd.sas.job.execution.job.request+json, application/vnd.sas.error+json' \
    --header "Authorization: Bearer $OAUTH_TOKEN" \
    --header 'Content-Type: application/json' \
    --data '{
    "name": "Proc setinit",
    "description": "Execute proc setinit",
    "jobDefinitionUri": "/jobDefinitions/definitions/bbf8e264-f7c7-436a-a852-e07852704a07",
    "createdByApplication": "finance-frontend"
    }'
    ```
    </details>

    <details>
    <summary>API Response</summary>

    ```
    {
        "creationTimeStamp": "2025-04-01T13:31:49.896Z",
        "modifiedTimeStamp": "2025-04-01T13:31:49.896Z",
        "createdBy": "sasshared@contoso.onmicrosoft.com",
        "modifiedBy": "sasshared@contoso.onmicrosoft.com",
        "version": 3,
        "id": "67a69b9a-117d-48bd-8097-9d7514d22812",
        "name": "Proc setinit",
        "description": "Execute proc setinit",
        "jobDefinitionUri": "/jobDefinitions/definitions/bbf8e264-f7c7-436a-a852-e07852704a07",
        "arguments": {},
        "properties": [],
        "createdByApplication": "finance-frontend",
        "links": [
            {
                "method": "GET",
                "rel": "self",
                "href": "/jobExecution/jobRequests/67a69b9a-117d-48bd-8097-9d7514d22812",
                "uri": "/jobExecution/jobRequests/67a69b9a-117d-48bd-8097-9d7514d22812",
                "type": "application/vnd.sas.job.execution.job.request"
            },
            {
                "method": "GET",
                "rel": "alternate",
                "href": "/jobExecution/jobRequests/67a69b9a-117d-48bd-8097-9d7514d22812",
                "uri": "/jobExecution/jobRequests/67a69b9a-117d-48bd-8097-9d7514d22812",
                "type": "application/vnd.sas.summary"
            },
            {
                "method": "GET",
                "rel": "export",
                "href": "/jobExecution/jobRequests/67a69b9a-117d-48bd-8097-9d7514d22812",
                "uri": "/jobExecution/jobRequests/67a69b9a-117d-48bd-8097-9d7514d22812",
                "type": "application/vnd.sas.transfer.object"
            },
            {
                "method": "DELETE",
                "rel": "delete",
                "href": "/jobExecution/jobRequests/67a69b9a-117d-48bd-8097-9d7514d22812",
                "uri": "/jobExecution/jobRequests/67a69b9a-117d-48bd-8097-9d7514d22812"
            },
            {
                "method": "PUT",
                "rel": "update",
                "href": "/jobExecution/jobRequests/67a69b9a-117d-48bd-8097-9d7514d22812",
                "uri": "/jobExecution/jobRequests/67a69b9a-117d-48bd-8097-9d7514d22812",
                "type": "application/vnd.sas.job.execution.job.request"
            },
            {
                "method": "PUT",
                "rel": "import",
                "href": "/jobExecution/jobRequests/67a69b9a-117d-48bd-8097-9d7514d22812",
                "uri": "/jobExecution/jobRequests/67a69b9a-117d-48bd-8097-9d7514d22812",
                "type": "application/vnd.sas.transfer.object",
                "responseType": "application/vnd.sas.summary"
            },
            {
                "method": "GET",
                "rel": "up",
                "href": "/jobExecution/jobRequests",
                "uri": "/jobExecution/jobRequests",
                "type": "application/vnd.sas.collection",
                "itemType": "application/vnd.sas.job.execution.job.request"
            },
            {
                "method": "GET",
                "rel": "jobs",
                "href": "/jobExecution/jobRequests/67a69b9a-117d-48bd-8097-9d7514d22812/jobs",
                "uri": "/jobExecution/jobRequests/67a69b9a-117d-48bd-8097-9d7514d22812/jobs",
                "type": "application/vnd.sas.collection",
                "itemType": "application/vnd.sas.job.execution.job"
            },
            {
                "method": "POST",
                "rel": "submitJob",
                "href": "/jobExecution/jobRequests/67a69b9a-117d-48bd-8097-9d7514d22812/jobs",
                "uri": "/jobExecution/jobRequests/67a69b9a-117d-48bd-8097-9d7514d22812/jobs",
                "responseType": "application/vnd.sas.job.execution.job"
            }
        ]
    }
    ```
    </details>

3. Submitting the job request.

    <details>
    <summary>API Call</summary>

    ```
    INGRESS_URL=https://hostname.example.com

    curl --request POST \
    --url "${INGRESS_URL}/jobExecution/jobRequests/67a69b9a-117d-48bd-8097-9d7514d22812/jobs" \
    --header 'Accept: application/json, application/vnd.sas.job.execution.job+json, application/vnd.sas.error+json' \
    --header "Authorization: Bearer $OAUTH_TOKEN"
    ```
    </details>

    <details>
    <summary>API Response</summary>
    ```
    {
        "creationTimeStamp": "2025-04-01T13:33:15.839Z",
        "modifiedTimeStamp": "2025-04-01T13:33:16.421Z",
        "createdBy": "sasshared@contoso.onmicrosoft.com",
        "modifiedBy": "sasshared@contoso.onmicrosoft.com",
        "version": 4,
        "id": "6545dfd8-e35e-49bf-83e0-6adba1051c3c",
        "jobRequest": {
            "creationTimeStamp": "2025-04-01T13:31:49.896Z",
            "modifiedTimeStamp": "2025-04-01T13:31:49.896Z",
            "createdBy": "sasshared@contoso.onmicrosoft.com",
            "modifiedBy": "sasshared@contoso.onmicrosoft.com",
            "version": 3,
            "id": "67a69b9a-117d-48bd-8097-9d7514d22812",
            "name": "Proc setinit",
            "description": "Execute proc setinit",
            "jobDefinitionUri": "/jobDefinitions/definitions/bbf8e264-f7c7-436a-a852-e07852704a07",
            "jobDefinition": {
                "creationTimeStamp": "2025-04-01T13:28:01.058Z",
                "modifiedTimeStamp": "2025-04-01T13:28:01.061Z",
                "createdBy": "sasshared@contoso.onmicrosoft.com",
                "modifiedBy": "sasshared@contoso.onmicrosoft.com",
                "version": 2,
                "id": "bbf8e264-f7c7-436a-a852-e07852704a07",
                "name": "Simple proc setinit",
                "description": "Show the current licensed SAS software",
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
                "code": "proc setinit; run;",
                "links": [
                    {
                        "method": "GET",
                        "rel": "self",
                        "href": "/jobDefinitions/definitions/bbf8e264-f7c7-436a-a852-e07852704a07",
                        "uri": "/jobDefinitions/definitions/bbf8e264-f7c7-436a-a852-e07852704a07",
                        "type": "application/vnd.sas.job.definition"
                    },
                    {
                        "method": "GET",
                        "rel": "alternate",
                        "href": "/jobDefinitions/definitions/bbf8e264-f7c7-436a-a852-e07852704a07",
                        "uri": "/jobDefinitions/definitions/bbf8e264-f7c7-436a-a852-e07852704a07",
                        "type": "application/vnd.sas.summary"
                    },
                    {
                        "method": "PUT",
                        "rel": "update",
                        "href": "/jobDefinitions/definitions/bbf8e264-f7c7-436a-a852-e07852704a07",
                        "uri": "/jobDefinitions/definitions/bbf8e264-f7c7-436a-a852-e07852704a07",
                        "type": "application/vnd.sas.job.definition",
                        "responseType": "application/vnd.sas.job.definition"
                    },
                    {
                        "method": "DELETE",
                        "rel": "delete",
                        "href": "/jobDefinitions/definitions/bbf8e264-f7c7-436a-a852-e07852704a07",
                        "uri": "/jobDefinitions/definitions/bbf8e264-f7c7-436a-a852-e07852704a07"
                    }
                ]
            },
            "arguments": {
                "_contextName": "SAS Job Execution compute context"
            },
            "properties": [],
            "createdByApplication": "finance-frontend",
            "links": [
                {
                    "method": "GET",
                    "rel": "self",
                    "href": "/jobExecution/jobRequests/67a69b9a-117d-48bd-8097-9d7514d22812",
                    "uri": "/jobExecution/jobRequests/67a69b9a-117d-48bd-8097-9d7514d22812",
                    "type": "application/vnd.sas.job.execution.job.request"
                }
            ]
        },
        "state": "running",
        "heartbeatTimeStamp": "2025-04-01T13:33:16.418Z",
        "submittedByApplication": "finance-frontend",
        "heartbeatInterval": 600,
        "elapsedTime": 586,
        "results": {},
        "links": [
            {
                "method": "GET",
                "rel": "self",
                "href": "/jobExecution/jobs/6545dfd8-e35e-49bf-83e0-6adba1051c3c",
                "uri": "/jobExecution/jobs/6545dfd8-e35e-49bf-83e0-6adba1051c3c",
                "type": "application/vnd.sas.job.execution.job"
            },
            {
                "method": "GET",
                "rel": "state",
                "href": "/jobExecution/jobs/6545dfd8-e35e-49bf-83e0-6adba1051c3c/state",
                "uri": "/jobExecution/jobs/6545dfd8-e35e-49bf-83e0-6adba1051c3c/state",
                "type": "text/plain"
            },
            {
                "method": "PUT",
                "rel": "update",
                "href": "/jobExecution/jobs/6545dfd8-e35e-49bf-83e0-6adba1051c3c",
                "uri": "/jobExecution/jobs/6545dfd8-e35e-49bf-83e0-6adba1051c3c",
                "type": "application/vnd.sas.job.execution.job",
                "responseType": "application/vnd.sas.job.execution.job"
            },
            {
                "method": "DELETE",
                "rel": "delete",
                "href": "/jobExecution/jobs/6545dfd8-e35e-49bf-83e0-6adba1051c3c",
                "uri": "/jobExecution/jobs/6545dfd8-e35e-49bf-83e0-6adba1051c3c"
            },
            {
                "method": "PUT",
                "rel": "updateState",
                "href": "/jobExecution/jobs/6545dfd8-e35e-49bf-83e0-6adba1051c3c/state",
                "uri": "/jobExecution/jobs/6545dfd8-e35e-49bf-83e0-6adba1051c3c/state",
                "type": "text/plain"
            },
            {
                "method": "POST",
                "rel": "updateHeartbeatTimeStamp",
                "href": "/jobExecution/jobs/6545dfd8-e35e-49bf-83e0-6adba1051c3c/heartbeatTimeStamp",
                "uri": "/jobExecution/jobs/6545dfd8-e35e-49bf-83e0-6adba1051c3c/heartbeatTimeStamp",
                "type": "text/plain"
            },
            {
                "method": "GET",
                "rel": "jobRequest",
                "href": "/jobExecution/jobRequests/67a69b9a-117d-48bd-8097-9d7514d22812",
                "uri": "/jobExecution/jobRequests/67a69b9a-117d-48bd-8097-9d7514d22812",
                "type": "application/vnd.sas.job.execution.job.request"
            },
            {
                "method": "GET",
                "rel": "jobDefinition",
                "href": "/jobDefinitions/definitions/bbf8e264-f7c7-436a-a852-e07852704a07",
                "uri": "/jobDefinitions/definitions/bbf8e264-f7c7-436a-a852-e07852704a07",
                "type": "application/vnd.sas.job.definition"
            }
        ]
    }
    ```

4. Retrieving the job state

    <details>
    <summary>API Call</summary>

    ```
    curl --request GET \
    --url "${INGRESS_URL}/jobExecution/jobs/6545dfd8-e35e-49bf-83e0-6adba1051c3c/state" \
    --header 'Accept: text/plain' \
    --header "Authorization: Bearer $OAUTH_TOKEN"
    ```

    </details>
    <details>
    <summary>API Response</summary>

    ```
    completed
    ```
    </details>


## SAS Cloud Analytic Server

The SAS Cloud Analytic Server can run in two different modes. By default, a CAS session runs under a default pre-defined "cas" identity. Alternatively, you can configure CAS to run under the end-user's identity. This is done by placing users for which this behavior is desired in the pre-defined [CASHostAccountRequired](https://go.documentation.sas.com/doc/en/sasadmincdc/default/calids/p0ata1oqy9v7nan188h1k254doxq.htm#p1b0uixk221q3jn19ztuitir62gm) custom group or by setting the [CASALLHOSTACCOUNTS](https://go.documentation.sas.com/doc/en/sasadmincdc/default/calauthmdl/p0pya5yqzs30psn1kqpt1x2wirph.htm) environment variable to 1. This may be required if you need to access file system resources that are secured using POSIX permissions. 

Although you can interact with the CAS server via the [CAS Management API](https://developer.sas.com/rest-apis/casManagement) directly for high-level operations such as requesting the number of available nodes and creating CASLibs, most interactions with CAS will happen via an established compute session.

Here, our two different scenario's detailed above for running compute sessions using a service account will work differently when interacting with CAS. Compute sessions that are started under a shared account are still considered to run on behalve of a specific end-user (or OAuth client in our case). Hence, CAS sessions started by these compute sessions will still be started as that specific end-user.

This is easily demonstrated by starting a CAS session from a compute session running on a compute context configured to run under a shared account:

1. Creating the job definition.

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
    --data '{
    "version": 2,
    "name": "RunCAS",
    "description": "Create and terminate a CAS session",
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
    "code": "cas sharedsession; cas sharedsession terminate;"
    }'
    ```

    </details>

    <details>
    <summary>API Response</summary>

    ```
    {
        "creationTimeStamp": "2025-02-03T13:29:17.150Z",
        "modifiedTimeStamp": "2025-02-03T13:29:17.153Z",
        "createdBy": "finance-frontend",
        "modifiedBy": "finance-frontend",
        "version": 2,
        "id": "071c2c2c-3a9c-49a0-96c0-87e5e82a6567",
        "name": "RunCASOAuth",
        "description": "Start and Terminate a CAS session",
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
        "code": "%put &sysuserid; cas sharedsession; cas sharedsession terminate;",
        "links": [
            {
                "method": "GET",
                "rel": "self",
                "href": "/jobDefinitions/definitions/071c2c2c-3a9c-49a0-96c0-87e5e82a6567",
                "uri": "/jobDefinitions/definitions/071c2c2c-3a9c-49a0-96c0-87e5e82a6567",
                "type": "application/vnd.sas.job.definition"
            },
            {
                "method": "GET",
                "rel": "alternate",
                "href": "/jobDefinitions/definitions/071c2c2c-3a9c-49a0-96c0-87e5e82a6567",
                "uri": "/jobDefinitions/definitions/071c2c2c-3a9c-49a0-96c0-87e5e82a6567",
                "type": "application/vnd.sas.summary"
            },
            {
                "method": "PUT",
                "rel": "update",
                "href": "/jobDefinitions/definitions/071c2c2c-3a9c-49a0-96c0-87e5e82a6567",
                "uri": "/jobDefinitions/definitions/071c2c2c-3a9c-49a0-96c0-87e5e82a6567",
                "type": "application/vnd.sas.job.definition",
                "responseType": "application/vnd.sas.job.definition"
            },
            {
                "method": "DELETE",
                "rel": "delete",
                "href": "/jobDefinitions/definitions/071c2c2c-3a9c-49a0-96c0-87e5e82a6567",
                "uri": "/jobDefinitions/definitions/071c2c2c-3a9c-49a0-96c0-87e5e82a6567"
            }
        ]
    }
    ```
    </details>

2. Create the job request.

    <details>
    <summary>API Call</summary>

    ```
    INGRESS_URL=https://hostname.example.com

    curl --request POST \
    --url "${INGRESS_URL}/jobExecution/jobRequests" \
    --header 'Accept: application/json, application/vnd.sas.job.execution.job.request+json, application/vnd.sas.error+json' \
    --header "Authorization: Bearer $OAUTH_TOKEN" \
    --header 'Content-Type: application/json' \
    --data '{
    "name": "RunCAS shared",
    "description": "Start and Stop a CAS session using a shared compute context",
    "jobDefinitionUri": "/jobDefinitions/definitions/071c2c2c-3a9c-49a0-96c0-87e5e82a6567",
    "arguments": {
        "_contextName": "Shared Compute Context"
    },
    "createdByApplication": "finance-frontend"
    }'
    ```
    </details>

    <details>
    <summary>API Response</summary>

    ```
    {
        "creationTimeStamp": "2025-02-13T09:51:26.085Z",
        "modifiedTimeStamp": "2025-02-13T09:51:26.085Z",
        "createdBy": "finance-frontend",
        "modifiedBy": "finance-frontend",
        "version": 3,
        "id": "a2c2e1da-36e6-42db-a1e0-3e1a35bbe38b",
        "name": "RunCAS shared",
        "description": "Start and Stop a CAS session using a shared compute context",
        "jobDefinitionUri": "/jobDefinitions/definitions/071c2c2c-3a9c-49a0-96c0-87e5e82a6567",
        "arguments": {
            "_contextName": "Shared Compute Context"
        },
        "properties": [],
        "createdByApplication": "finance-frontend",
        "links": [
            {
                "method": "GET",
                "rel": "self",
                "href": "/jobExecution/jobRequests/a2c2e1da-36e6-42db-a1e0-3e1a35bbe38b",
                "uri": "/jobExecution/jobRequests/a2c2e1da-36e6-42db-a1e0-3e1a35bbe38b",
                "type": "application/vnd.sas.job.execution.job.request"
            },
            {
                "method": "GET",
                "rel": "alternate",
                "href": "/jobExecution/jobRequests/a2c2e1da-36e6-42db-a1e0-3e1a35bbe38b",
                "uri": "/jobExecution/jobRequests/a2c2e1da-36e6-42db-a1e0-3e1a35bbe38b",
                "type": "application/vnd.sas.summary"
            },
            {
                "method": "GET",
                "rel": "export",
                "href": "/jobExecution/jobRequests/a2c2e1da-36e6-42db-a1e0-3e1a35bbe38b",
                "uri": "/jobExecution/jobRequests/a2c2e1da-36e6-42db-a1e0-3e1a35bbe38b",
                "type": "application/vnd.sas.transfer.object"
            },
            {
                "method": "DELETE",
                "rel": "delete",
                "href": "/jobExecution/jobRequests/a2c2e1da-36e6-42db-a1e0-3e1a35bbe38b",
                "uri": "/jobExecution/jobRequests/a2c2e1da-36e6-42db-a1e0-3e1a35bbe38b"
            },
            {
                "method": "PUT",
                "rel": "update",
                "href": "/jobExecution/jobRequests/a2c2e1da-36e6-42db-a1e0-3e1a35bbe38b",
                "uri": "/jobExecution/jobRequests/a2c2e1da-36e6-42db-a1e0-3e1a35bbe38b",
                "type": "application/vnd.sas.job.execution.job.request"
            },
            {
                "method": "PUT",
                "rel": "import",
                "href": "/jobExecution/jobRequests/a2c2e1da-36e6-42db-a1e0-3e1a35bbe38b",
                "uri": "/jobExecution/jobRequests/a2c2e1da-36e6-42db-a1e0-3e1a35bbe38b",
                "type": "application/vnd.sas.transfer.object",
                "responseType": "application/vnd.sas.summary"
            },
            {
                "method": "GET",
                "rel": "up",
                "href": "/jobExecution/jobRequests",
                "uri": "/jobExecution/jobRequests",
                "type": "application/vnd.sas.collection",
                "itemType": "application/vnd.sas.job.execution.job.request"
            },
            {
                "method": "GET",
                "rel": "jobs",
                "href": "/jobExecution/jobRequests/a2c2e1da-36e6-42db-a1e0-3e1a35bbe38b/jobs",
                "uri": "/jobExecution/jobRequests/a2c2e1da-36e6-42db-a1e0-3e1a35bbe38b/jobs",
                "type": "application/vnd.sas.collection",
                "itemType": "application/vnd.sas.job.execution.job"
            },
            {
                "method": "POST",
                "rel": "submitJob",
                "href": "/jobExecution/jobRequests/a2c2e1da-36e6-42db-a1e0-3e1a35bbe38b/jobs",
                "uri": "/jobExecution/jobRequests/a2c2e1da-36e6-42db-a1e0-3e1a35bbe38b/jobs",
                "responseType": "application/vnd.sas.job.execution.job"
            }
        ]
    }
    ```
    </details>

3. Execute the job

    <details>
    <summary>API Call</summary>

    ```
    curl --request POST \
    --url "${INGRESS_URL}/jobExecution/jobRequests/a2c2e1da-36e6-42db-a1e0-3e1a35bbe38b/jobs" \
    --header 'Accept: application/json, application/vnd.sas.job.execution.job+json, application/vnd.sas.error+json' \
    --header "Authorization: Bearer $OAUTH_TOKEN"
    ```

    </details>
    <details>
    <summary>API Response</summary>

    ```
    {
        "creationTimeStamp": "2025-02-13T09:52:42.434Z",
        "modifiedTimeStamp": "2025-02-13T09:52:42.481Z",
        "createdBy": "finance-frontend",
        "modifiedBy": "finance-frontend",
        "version": 4,
        "id": "39462910-34a6-41cc-b15e-defcde3d8699",
        "jobRequest": {
            "creationTimeStamp": "2025-02-13T09:51:26.085Z",
            "modifiedTimeStamp": "2025-02-13T09:51:26.085Z",
            "createdBy": "finance-frontend",
            "modifiedBy": "finance-frontend",
            "version": 3,
            "id": "a2c2e1da-36e6-42db-a1e0-3e1a35bbe38b",
            "name": "RunCAS shared",
            "description": "Start and Stop a CAS session using a shared compute context",
            "jobDefinitionUri": "/jobDefinitions/definitions/071c2c2c-3a9c-49a0-96c0-87e5e82a6567",
            "jobDefinition": {
                "creationTimeStamp": "2025-02-03T13:29:17.150Z",
                "modifiedTimeStamp": "2025-02-03T13:29:17.153Z",
                "createdBy": "finance-frontend",
                "modifiedBy": "finance-frontend",
                "version": 2,
                "id": "071c2c2c-3a9c-49a0-96c0-87e5e82a6567",
                "name": "RunCASOAuth",
                "description": "Start and Terminate a CAS session",
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
                "code": "%put &sysuserid; cas sharedsession; cas sharedsession terminate;",
                "links": [
                    {
                        "method": "GET",
                        "rel": "self",
                        "href": "/jobDefinitions/definitions/071c2c2c-3a9c-49a0-96c0-87e5e82a6567",
                        "uri": "/jobDefinitions/definitions/071c2c2c-3a9c-49a0-96c0-87e5e82a6567",
                        "type": "application/vnd.sas.job.definition"
                    },
                    {
                        "method": "GET",
                        "rel": "alternate",
                        "href": "/jobDefinitions/definitions/071c2c2c-3a9c-49a0-96c0-87e5e82a6567",
                        "uri": "/jobDefinitions/definitions/071c2c2c-3a9c-49a0-96c0-87e5e82a6567",
                        "type": "application/vnd.sas.summary"
                    },
                    {
                        "method": "PUT",
                        "rel": "update",
                        "href": "/jobDefinitions/definitions/071c2c2c-3a9c-49a0-96c0-87e5e82a6567",
                        "uri": "/jobDefinitions/definitions/071c2c2c-3a9c-49a0-96c0-87e5e82a6567",
                        "type": "application/vnd.sas.job.definition",
                        "responseType": "application/vnd.sas.job.definition"
                    },
                    {
                        "method": "DELETE",
                        "rel": "delete",
                        "href": "/jobDefinitions/definitions/071c2c2c-3a9c-49a0-96c0-87e5e82a6567",
                        "uri": "/jobDefinitions/definitions/071c2c2c-3a9c-49a0-96c0-87e5e82a6567"
                    }
                ]
            },
            "arguments": {
                "_contextName": "Shared Compute Context"
            },
            "properties": [],
            "createdByApplication": "finance-frontend",
            "links": [
                {
                    "method": "GET",
                    "rel": "self",
                    "href": "/jobExecution/jobRequests/a2c2e1da-36e6-42db-a1e0-3e1a35bbe38b",
                    "uri": "/jobExecution/jobRequests/a2c2e1da-36e6-42db-a1e0-3e1a35bbe38b",
                    "type": "application/vnd.sas.job.execution.job.request"
                }
            ]
        },
        "state": "running",
        "heartbeatTimeStamp": "2025-02-13T09:52:42.476Z",
        "submittedByApplication": "finance-frontend",
        "heartbeatInterval": 600,
        "elapsedTime": 57,
        "results": {},
        "links": [
            {
                "method": "GET",
                "rel": "self",
                "href": "/jobExecution/jobs/39462910-34a6-41cc-b15e-defcde3d8699",
                "uri": "/jobExecution/jobs/39462910-34a6-41cc-b15e-defcde3d8699",
                "type": "application/vnd.sas.job.execution.job"
            },
            {
                "method": "GET",
                "rel": "state",
                "href": "/jobExecution/jobs/39462910-34a6-41cc-b15e-defcde3d8699/state",
                "uri": "/jobExecution/jobs/39462910-34a6-41cc-b15e-defcde3d8699/state",
                "type": "text/plain"
            },
            {
                "method": "PUT",
                "rel": "update",
                "href": "/jobExecution/jobs/39462910-34a6-41cc-b15e-defcde3d8699",
                "uri": "/jobExecution/jobs/39462910-34a6-41cc-b15e-defcde3d8699",
                "type": "application/vnd.sas.job.execution.job",
                "responseType": "application/vnd.sas.job.execution.job"
            },
            {
                "method": "DELETE",
                "rel": "delete",
                "href": "/jobExecution/jobs/39462910-34a6-41cc-b15e-defcde3d8699",
                "uri": "/jobExecution/jobs/39462910-34a6-41cc-b15e-defcde3d8699"
            },
            {
                "method": "PUT",
                "rel": "updateState",
                "href": "/jobExecution/jobs/39462910-34a6-41cc-b15e-defcde3d8699/state",
                "uri": "/jobExecution/jobs/39462910-34a6-41cc-b15e-defcde3d8699/state",
                "type": "text/plain"
            },
            {
                "method": "POST",
                "rel": "updateHeartbeatTimeStamp",
                "href": "/jobExecution/jobs/39462910-34a6-41cc-b15e-defcde3d8699/heartbeatTimeStamp",
                "uri": "/jobExecution/jobs/39462910-34a6-41cc-b15e-defcde3d8699/heartbeatTimeStamp",
                "type": "text/plain"
            },
            {
                "method": "GET",
                "rel": "jobRequest",
                "href": "/jobExecution/jobRequests/a2c2e1da-36e6-42db-a1e0-3e1a35bbe38b",
                "uri": "/jobExecution/jobRequests/a2c2e1da-36e6-42db-a1e0-3e1a35bbe38b",
                "type": "application/vnd.sas.job.execution.job.request"
            },
            {
                "method": "GET",
                "rel": "jobDefinition",
                "href": "/jobDefinitions/definitions/071c2c2c-3a9c-49a0-96c0-87e5e82a6567",
                "uri": "/jobDefinitions/definitions/071c2c2c-3a9c-49a0-96c0-87e5e82a6567",
                "type": "application/vnd.sas.job.definition"
            }
        ]
    }
    ```
    </details>

4. Get the job information, including the location of the log file

    <details>
    <summary>API Call</summary>

    ```
    curl --request GET \
      --url "${INGRESS_URL}/jobExecution/jobs/39462910-34a6-41cc-b15e-defcde3d8699" \
      --header 'Accept: application/json, application/vnd.sas.job.execution.job+json, application/vnd.sas.error+json' \
      --header "Authorization: Bearer $OAUTH_TOKEN"
    ```

    </details>
    <details>
    <summary>API Response</summary>

    ```
    {
        "creationTimeStamp": "2025-02-13T09:52:42.434Z",
        "modifiedTimeStamp": "2025-02-13T09:52:48.592Z",
        "createdBy": "finance-frontend",
        "modifiedBy": "finance-frontend",
        "version": 4,
        "id": "39462910-34a6-41cc-b15e-defcde3d8699",
        "jobRequest": {
            "creationTimeStamp": "2025-02-13T09:51:26.085Z",
            "modifiedTimeStamp": "2025-02-13T09:51:26.085Z",
            "createdBy": "finance-frontend",
            "modifiedBy": "finance-frontend",
            "version": 3,
            "id": "a2c2e1da-36e6-42db-a1e0-3e1a35bbe38b",
            "name": "RunCAS shared",
            "description": "Start and Stop a CAS session using a shared compute context",
            "jobDefinitionUri": "/jobDefinitions/definitions/071c2c2c-3a9c-49a0-96c0-87e5e82a6567",
            "jobDefinition": {
                "creationTimeStamp": "2025-02-03T13:29:17.150Z",
                "modifiedTimeStamp": "2025-02-03T13:29:17.153Z",
                "createdBy": "finance-frontend",
                "modifiedBy": "finance-frontend",
                "version": 2,
                "id": "071c2c2c-3a9c-49a0-96c0-87e5e82a6567",
                "name": "RunCASOAuth",
                "description": "Start and Terminate a CAS session",
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
                "code": "%put &sysuserid; cas sharedsession; cas sharedsession terminate;",
                "links": [
                    {
                        "method": "GET",
                        "rel": "self",
                        "href": "/jobDefinitions/definitions/071c2c2c-3a9c-49a0-96c0-87e5e82a6567",
                        "uri": "/jobDefinitions/definitions/071c2c2c-3a9c-49a0-96c0-87e5e82a6567",
                        "type": "application/vnd.sas.job.definition"
                    },
                    {
                        "method": "GET",
                        "rel": "alternate",
                        "href": "/jobDefinitions/definitions/071c2c2c-3a9c-49a0-96c0-87e5e82a6567",
                        "uri": "/jobDefinitions/definitions/071c2c2c-3a9c-49a0-96c0-87e5e82a6567",
                        "type": "application/vnd.sas.summary"
                    },
                    {
                        "method": "PUT",
                        "rel": "update",
                        "href": "/jobDefinitions/definitions/071c2c2c-3a9c-49a0-96c0-87e5e82a6567",
                        "uri": "/jobDefinitions/definitions/071c2c2c-3a9c-49a0-96c0-87e5e82a6567",
                        "type": "application/vnd.sas.job.definition",
                        "responseType": "application/vnd.sas.job.definition"
                    },
                    {
                        "method": "DELETE",
                        "rel": "delete",
                        "href": "/jobDefinitions/definitions/071c2c2c-3a9c-49a0-96c0-87e5e82a6567",
                        "uri": "/jobDefinitions/definitions/071c2c2c-3a9c-49a0-96c0-87e5e82a6567"
                    }
                ]
            },
            "arguments": {
                "_contextName": "Shared Compute Context"
            },
            "properties": [],
            "createdByApplication": "finance-frontend",
            "links": [
                {
                    "method": "GET",
                    "rel": "self",
                    "href": "/jobExecution/jobRequests/a2c2e1da-36e6-42db-a1e0-3e1a35bbe38b",
                    "uri": "/jobExecution/jobRequests/a2c2e1da-36e6-42db-a1e0-3e1a35bbe38b",
                    "type": "application/vnd.sas.job.execution.job.request"
                }
            ]
        },
        "state": "completed",
        "endTimeStamp": "2025-02-13T09:52:48.592Z",
        "heartbeatTimeStamp": "2025-02-13T09:52:42.481Z",
        "submittedByApplication": "finance-frontend",
        "heartbeatInterval": 600,
        "elapsedTime": 6158,
        "results": {
            "COMPUTE_CONTEXT": "Shared Compute Context",
            "COMPUTE_JOB": "A5199BE2-B0F0-834C-9460-C56106442B73",
            "A5199BE2-B0F0-834C-9460-C56106442B73.log.txt": "/files/files/b4ff52d1-e72a-4a51-a65b-67bdd8dd12b8",
            "COMPUTE_SESSION": "0c0007d6-585d-4c9c-b0b7-a98ac3f392d2-ses0000 ended."
        },
        "logLocation": "/files/files/814f031e-01c7-4eaf-88de-05920c2a18e7",
        "links": [
            {
                "method": "GET",
                "rel": "self",
                "href": "/jobExecution/jobs/39462910-34a6-41cc-b15e-defcde3d8699",
                "uri": "/jobExecution/jobs/39462910-34a6-41cc-b15e-defcde3d8699",
                "type": "application/vnd.sas.job.execution.job"
            },
            {
                "method": "GET",
                "rel": "state",
                "href": "/jobExecution/jobs/39462910-34a6-41cc-b15e-defcde3d8699/state",
                "uri": "/jobExecution/jobs/39462910-34a6-41cc-b15e-defcde3d8699/state",
                "type": "text/plain"
            },
            {
                "method": "PUT",
                "rel": "update",
                "href": "/jobExecution/jobs/39462910-34a6-41cc-b15e-defcde3d8699",
                "uri": "/jobExecution/jobs/39462910-34a6-41cc-b15e-defcde3d8699",
                "type": "application/vnd.sas.job.execution.job",
                "responseType": "application/vnd.sas.job.execution.job"
            },
            {
                "method": "DELETE",
                "rel": "delete",
                "href": "/jobExecution/jobs/39462910-34a6-41cc-b15e-defcde3d8699",
                "uri": "/jobExecution/jobs/39462910-34a6-41cc-b15e-defcde3d8699"
            },
            {
                "method": "PUT",
                "rel": "updateState",
                "href": "/jobExecution/jobs/39462910-34a6-41cc-b15e-defcde3d8699/state",
                "uri": "/jobExecution/jobs/39462910-34a6-41cc-b15e-defcde3d8699/state",
                "type": "text/plain"
            },
            {
                "method": "POST",
                "rel": "updateHeartbeatTimeStamp",
                "href": "/jobExecution/jobs/39462910-34a6-41cc-b15e-defcde3d8699/heartbeatTimeStamp",
                "uri": "/jobExecution/jobs/39462910-34a6-41cc-b15e-defcde3d8699/heartbeatTimeStamp",
                "type": "text/plain"
            },
            {
                "method": "GET",
                "rel": "jobRequest",
                "href": "/jobExecution/jobRequests/a2c2e1da-36e6-42db-a1e0-3e1a35bbe38b",
                "uri": "/jobExecution/jobRequests/a2c2e1da-36e6-42db-a1e0-3e1a35bbe38b",
                "type": "application/vnd.sas.job.execution.job.request"
            },
            {
                "method": "GET",
                "rel": "jobDefinition",
                "href": "/jobDefinitions/definitions/071c2c2c-3a9c-49a0-96c0-87e5e82a6567",
                "uri": "/jobDefinitions/definitions/071c2c2c-3a9c-49a0-96c0-87e5e82a6567",
                "type": "application/vnd.sas.job.definition"
            },
            {
                "method": "GET",
                "rel": "log",
                "href": "/files/files/814f031e-01c7-4eaf-88de-05920c2a18e7",
                "uri": "/files/files/814f031e-01c7-4eaf-88de-05920c2a18e7"
            }
        ]
    }
    ```
    </details>
    
5. Get the log file for this job

    <details>
    <summary>API Call</summary>

    ```
    curl --request GET \
      --url "${INGRESS_URL}/files/files/814f031e-01c7-4eaf-88de-05920c2a18e7/content" \
      --header 'Accept: application/vnd.sas.error+json' \
      --header "Authorization: Bearer $OAUTH_TOKEN"
    ```

    </details>
    <details>
    <summary>API Response</summary>

    ```
    {
        "version": 2,
        "name": "items",
        "accept": "application/vnd.sas.compute.log.line",
        "start": 0,
        "items": [
            {
                "version": 1,
                "type": "source",
                "line": "1    %put &sysuserid; cas mysession; cas mysession terminate;"
            },
            {
                "version": 1,
                "type": "normal",
                "line": "sasshared@contoso"
            },
            {
                "version": 1,
                "type": "note",
                "line": "NOTE: The session MYSESSION connected successfully to Cloud Analytic Services sas-cas-server-default-client using port 5570. The "
            },
            {
                "version": 1,
                "type": "note",
                "line": "      UUID is 873f19e1-0106-e743-96f4-c221a0733a28. The user is finance-frontend and the active caslib is CASUSER(finance-frontend)."
            },
            {
                "version": 1,
                "type": "note",
                "line": "NOTE: The SAS option SESSREF was updated with the value MYSESSION."
            },
            {
                "version": 1,
                "type": "note",
                "line": "NOTE: The SAS macro _SESSREF_ was updated with the value MYSESSION."
            },
            {
                "version": 1,
                "type": "note",
                "line": "NOTE: The session is using 0 workers."
            },
            {
                "version": 1,
                "type": "note",
                "line": "NOTE: Deletion of the session MYSESSION was successful."
            },
            {
                "version": 1,
                "type": "note",
                "line": "NOTE: The default CAS session MYSESSION identified by SAS option SESSREF= was terminated. Use the OPTIONS statement to set the "
            },
            {
                "version": 1,
                "type": "note",
                "line": "      SESSREF= option to an active session."
            },
            {
                "version": 1,
                "type": "note",
                "line": "NOTE: Request to TERMINATE completed for session MYSESSION."
            }
        ],
        "count": 11,
        "limit": 11,
        "links": []
    }
    ```
    </details>

As you can see, the user running the compute session is sasshared@contoso. However, the CAS session that is started in this compute session is started as finance-frontend, our OAuth client.

Compare this, if we run the same program, but now by using an access token for a service account.

1. Creating the job definition.

    <details>
    <summary>API Call</summary>

    ```
    INGRESS_URL=https://hostname.example.com
    OAUTH_TOKEN=$ACCESS_TOKEN

    curl --request POST \
    --url "${INGRESS_URL}/jobDefinitions/definitions" \
    --header 'Accept: application/json, application/vnd.sas.job.definition+json' \
    --header "Authorization: Bearer $OAUTH_TOKEN" \
    --header 'Content-Type: application/json' \
    --header 'accept: ' \
    --data '{
    "version": 2,
    "name": "RunCAS",
    "description": "Create and terminate a CAS session",
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
    "code": "cas mysession; cas mysession terminate;"
    }'
    ```

    </details>

    <details>
    <summary>API Response</summary>

    ```
    {
        "creationTimeStamp": "2025-04-01T13:38:09.205Z",
        "modifiedTimeStamp": "2025-04-01T13:38:09.206Z",
        "createdBy": "sasshared@contoso.onmicrosoft.com",
        "modifiedBy": "sasshared@contoso.onmicrosoft.com",
        "version": 2,
        "id": "18efdb16-dc76-4f11-b7c8-1bb17dc0d2ce",
        "name": "RunCAS",
        "description": "Create and terminate a CAS session",
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
        "code": "cas mysession; cas mysession terminate;",
        "links": [
            {
                "method": "GET",
                "rel": "self",
                "href": "/jobDefinitions/definitions/18efdb16-dc76-4f11-b7c8-1bb17dc0d2ce",
                "uri": "/jobDefinitions/definitions/18efdb16-dc76-4f11-b7c8-1bb17dc0d2ce",
                "type": "application/vnd.sas.job.definition"
            },
            {
                "method": "GET",
                "rel": "alternate",
                "href": "/jobDefinitions/definitions/18efdb16-dc76-4f11-b7c8-1bb17dc0d2ce",
                "uri": "/jobDefinitions/definitions/18efdb16-dc76-4f11-b7c8-1bb17dc0d2ce",
                "type": "application/vnd.sas.summary"
            },
            {
                "method": "PUT",
                "rel": "update",
                "href": "/jobDefinitions/definitions/18efdb16-dc76-4f11-b7c8-1bb17dc0d2ce",
                "uri": "/jobDefinitions/definitions/18efdb16-dc76-4f11-b7c8-1bb17dc0d2ce",
                "type": "application/vnd.sas.job.definition",
                "responseType": "application/vnd.sas.job.definition"
            },
            {
                "method": "DELETE",
                "rel": "delete",
                "href": "/jobDefinitions/definitions/18efdb16-dc76-4f11-b7c8-1bb17dc0d2ce",
                "uri": "/jobDefinitions/definitions/18efdb16-dc76-4f11-b7c8-1bb17dc0d2ce"
            }
        ]
    }
    ```
    </details>

2. Create the job request.

    <details>
    <summary>API Call</summary>

    ```
    INGRESS_URL=https://hostname.example.com

    curl --request POST \
    --url "${INGRESS_URL}/jobExecution/jobRequests" \
    --header 'Accept: application/json, application/vnd.sas.job.execution.job.request+json, application/vnd.sas.error+json' \
    --header "Authorization: Bearer $OAUTH_TOKEN" \
    --header 'Content-Type: application/json' \
    --data '{
    "name": "RunCAS",
    "description": "Start and Stop a CAS session",
    "jobDefinitionUri": "/jobDefinitions/definitions/18efdb16-dc76-4f11-b7c8-1bb17dc0d2ce",
    "createdByApplication": "finance-frontend"
    }'
    ```
    </details>

    <details>
    <summary>API Response</summary>

    ```
    {
        "creationTimeStamp": "2025-04-01T13:41:52.277Z",
        "modifiedTimeStamp": "2025-04-01T13:41:52.277Z",
        "createdBy": "sasshared@contoso.onmicrosoft.com",
        "modifiedBy": "sasshared@contoso.onmicrosoft.com",
        "version": 3,
        "id": "44ca6f4f-8e1e-4ff6-a338-f6977885ca31",
        "name": "RunCAS",
        "description": "Start and Stop a CAS session",
        "jobDefinitionUri": "/jobDefinitions/definitions/18efdb16-dc76-4f11-b7c8-1bb17dc0d2ce",
        "arguments": {},
        "properties": [],
        "createdByApplication": "finance-frontend",
        "links": [
            {
                "method": "GET",
                "rel": "self",
                "href": "/jobExecution/jobRequests/44ca6f4f-8e1e-4ff6-a338-f6977885ca31",
                "uri": "/jobExecution/jobRequests/44ca6f4f-8e1e-4ff6-a338-f6977885ca31",
                "type": "application/vnd.sas.job.execution.job.request"
            },
            {
                "method": "GET",
                "rel": "alternate",
                "href": "/jobExecution/jobRequests/44ca6f4f-8e1e-4ff6-a338-f6977885ca31",
                "uri": "/jobExecution/jobRequests/44ca6f4f-8e1e-4ff6-a338-f6977885ca31",
                "type": "application/vnd.sas.summary"
            },
            {
                "method": "GET",
                "rel": "export",
                "href": "/jobExecution/jobRequests/44ca6f4f-8e1e-4ff6-a338-f6977885ca31",
                "uri": "/jobExecution/jobRequests/44ca6f4f-8e1e-4ff6-a338-f6977885ca31",
                "type": "application/vnd.sas.transfer.object"
            },
            {
                "method": "DELETE",
                "rel": "delete",
                "href": "/jobExecution/jobRequests/44ca6f4f-8e1e-4ff6-a338-f6977885ca31",
                "uri": "/jobExecution/jobRequests/44ca6f4f-8e1e-4ff6-a338-f6977885ca31"
            },
            {
                "method": "PUT",
                "rel": "update",
                "href": "/jobExecution/jobRequests/44ca6f4f-8e1e-4ff6-a338-f6977885ca31",
                "uri": "/jobExecution/jobRequests/44ca6f4f-8e1e-4ff6-a338-f6977885ca31",
                "type": "application/vnd.sas.job.execution.job.request"
            },
            {
                "method": "PUT",
                "rel": "import",
                "href": "/jobExecution/jobRequests/44ca6f4f-8e1e-4ff6-a338-f6977885ca31",
                "uri": "/jobExecution/jobRequests/44ca6f4f-8e1e-4ff6-a338-f6977885ca31",
                "type": "application/vnd.sas.transfer.object",
                "responseType": "application/vnd.sas.summary"
            },
            {
                "method": "GET",
                "rel": "up",
                "href": "/jobExecution/jobRequests",
                "uri": "/jobExecution/jobRequests",
                "type": "application/vnd.sas.collection",
                "itemType": "application/vnd.sas.job.execution.job.request"
            },
            {
                "method": "GET",
                "rel": "jobs",
                "href": "/jobExecution/jobRequests/44ca6f4f-8e1e-4ff6-a338-f6977885ca31/jobs",
                "uri": "/jobExecution/jobRequests/44ca6f4f-8e1e-4ff6-a338-f6977885ca31/jobs",
                "type": "application/vnd.sas.collection",
                "itemType": "application/vnd.sas.job.execution.job"
            },
            {
                "method": "POST",
                "rel": "submitJob",
                "href": "/jobExecution/jobRequests/44ca6f4f-8e1e-4ff6-a338-f6977885ca31/jobs",
                "uri": "/jobExecution/jobRequests/44ca6f4f-8e1e-4ff6-a338-f6977885ca31/jobs",
                "responseType": "application/vnd.sas.job.execution.job"
            }
        ]
    }
    ```
    </details>

3. Execute the job

    <details>
    <summary>API Call</summary>

    ```
    curl --request POST \
    --url "${INGRESS_URL}/jobExecution/jobRequests/44ca6f4f-8e1e-4ff6-a338-f6977885ca31/jobs" \
    --header 'Accept: application/json, application/vnd.sas.job.execution.job+json, application/vnd.sas.error+json' \
    --header "Authorization: Bearer $OAUTH_TOKEN"
    ```

    </details>
    <details>
    <summary>API Response</summary>

    ```
    {
        "creationTimeStamp": "2025-04-01T13:42:43.122Z",
        "modifiedTimeStamp": "2025-04-01T13:42:43.333Z",
        "createdBy": "sasshared@contoso.onmicrosoft.com",
        "modifiedBy": "sasshared@contoso.onmicrosoft.com",
        "version": 4,
        "id": "00f595b2-d575-4781-a75b-829578b5a9a9",
        "jobRequest": {
            "creationTimeStamp": "2025-04-01T13:41:52.277Z",
            "modifiedTimeStamp": "2025-04-01T13:41:52.277Z",
            "createdBy": "sasshared@contoso.onmicrosoft.com",
            "modifiedBy": "sasshared@contoso.onmicrosoft.com",
            "version": 3,
            "id": "44ca6f4f-8e1e-4ff6-a338-f6977885ca31",
            "name": "RunCAS",
            "description": "Start and Stop a CAS session",
            "jobDefinitionUri": "/jobDefinitions/definitions/18efdb16-dc76-4f11-b7c8-1bb17dc0d2ce",
            "jobDefinition": {
                "creationTimeStamp": "2025-04-01T13:38:09.205Z",
                "modifiedTimeStamp": "2025-04-01T13:38:09.206Z",
                "createdBy": "sasshared@contoso.onmicrosoft.com",
                "modifiedBy": "sasshared@contoso.onmicrosoft.com",
                "version": 2,
                "id": "18efdb16-dc76-4f11-b7c8-1bb17dc0d2ce",
                "name": "RunCAS",
                "description": "Create and terminate a CAS session",
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
                "code": "cas mysession; cas mysession terminate;",
                "links": [
                    {
                        "method": "GET",
                        "rel": "self",
                        "href": "/jobDefinitions/definitions/18efdb16-dc76-4f11-b7c8-1bb17dc0d2ce",
                        "uri": "/jobDefinitions/definitions/18efdb16-dc76-4f11-b7c8-1bb17dc0d2ce",
                        "type": "application/vnd.sas.job.definition"
                    },
                    {
                        "method": "GET",
                        "rel": "alternate",
                        "href": "/jobDefinitions/definitions/18efdb16-dc76-4f11-b7c8-1bb17dc0d2ce",
                        "uri": "/jobDefinitions/definitions/18efdb16-dc76-4f11-b7c8-1bb17dc0d2ce",
                        "type": "application/vnd.sas.summary"
                    },
                    {
                        "method": "PUT",
                        "rel": "update",
                        "href": "/jobDefinitions/definitions/18efdb16-dc76-4f11-b7c8-1bb17dc0d2ce",
                        "uri": "/jobDefinitions/definitions/18efdb16-dc76-4f11-b7c8-1bb17dc0d2ce",
                        "type": "application/vnd.sas.job.definition",
                        "responseType": "application/vnd.sas.job.definition"
                    },
                    {
                        "method": "DELETE",
                        "rel": "delete",
                        "href": "/jobDefinitions/definitions/18efdb16-dc76-4f11-b7c8-1bb17dc0d2ce",
                        "uri": "/jobDefinitions/definitions/18efdb16-dc76-4f11-b7c8-1bb17dc0d2ce"
                    }
                ]
            },
            "arguments": {
                "_contextName": "SAS Job Execution compute context"
            },
            "properties": [],
            "createdByApplication": "finance-frontend",
            "links": [
                {
                    "method": "GET",
                    "rel": "self",
                    "href": "/jobExecution/jobRequests/44ca6f4f-8e1e-4ff6-a338-f6977885ca31",
                    "uri": "/jobExecution/jobRequests/44ca6f4f-8e1e-4ff6-a338-f6977885ca31",
                    "type": "application/vnd.sas.job.execution.job.request"
                }
            ]
        },
        "state": "running",
        "heartbeatTimeStamp": "2025-04-01T13:42:43.331Z",
        "submittedByApplication": "finance-frontend",
        "heartbeatInterval": 600,
        "elapsedTime": 214,
        "results": {},
        "links": [
            {
                "method": "GET",
                "rel": "self",
                "href": "/jobExecution/jobs/00f595b2-d575-4781-a75b-829578b5a9a9",
                "uri": "/jobExecution/jobs/00f595b2-d575-4781-a75b-829578b5a9a9",
                "type": "application/vnd.sas.job.execution.job"
            },
            {
                "method": "GET",
                "rel": "state",
                "href": "/jobExecution/jobs/00f595b2-d575-4781-a75b-829578b5a9a9/state",
                "uri": "/jobExecution/jobs/00f595b2-d575-4781-a75b-829578b5a9a9/state",
                "type": "text/plain"
            },
            {
                "method": "PUT",
                "rel": "update",
                "href": "/jobExecution/jobs/00f595b2-d575-4781-a75b-829578b5a9a9",
                "uri": "/jobExecution/jobs/00f595b2-d575-4781-a75b-829578b5a9a9",
                "type": "application/vnd.sas.job.execution.job",
                "responseType": "application/vnd.sas.job.execution.job"
            },
            {
                "method": "DELETE",
                "rel": "delete",
                "href": "/jobExecution/jobs/00f595b2-d575-4781-a75b-829578b5a9a9",
                "uri": "/jobExecution/jobs/00f595b2-d575-4781-a75b-829578b5a9a9"
            },
            {
                "method": "PUT",
                "rel": "updateState",
                "href": "/jobExecution/jobs/00f595b2-d575-4781-a75b-829578b5a9a9/state",
                "uri": "/jobExecution/jobs/00f595b2-d575-4781-a75b-829578b5a9a9/state",
                "type": "text/plain"
            },
            {
                "method": "POST",
                "rel": "updateHeartbeatTimeStamp",
                "href": "/jobExecution/jobs/00f595b2-d575-4781-a75b-829578b5a9a9/heartbeatTimeStamp",
                "uri": "/jobExecution/jobs/00f595b2-d575-4781-a75b-829578b5a9a9/heartbeatTimeStamp",
                "type": "text/plain"
            },
            {
                "method": "GET",
                "rel": "jobRequest",
                "href": "/jobExecution/jobRequests/44ca6f4f-8e1e-4ff6-a338-f6977885ca31",
                "uri": "/jobExecution/jobRequests/44ca6f4f-8e1e-4ff6-a338-f6977885ca31",
                "type": "application/vnd.sas.job.execution.job.request"
            },
            {
                "method": "GET",
                "rel": "jobDefinition",
                "href": "/jobDefinitions/definitions/18efdb16-dc76-4f11-b7c8-1bb17dc0d2ce",
                "uri": "/jobDefinitions/definitions/18efdb16-dc76-4f11-b7c8-1bb17dc0d2ce",
                "type": "application/vnd.sas.job.definition"
            }
        ]
    }
    ```
    </details>

4. Get the job information, including the location of the log file

    <details>
    <summary>API Call</summary>

    ```
    curl --request GET \
      --url "${INGRESS_URL}/jobExecution/jobs/00f595b2-d575-4781-a75b-829578b5a9a9" \
      --header 'Accept: application/json, application/vnd.sas.job.execution.job+json, application/vnd.sas.error+json' \
      --header "Authorization: Bearer $OAUTH_TOKEN"
    ```

    </details>
    <details>
    <summary>API Response</summary>

    ```
    {
        "creationTimeStamp": "2025-04-01T13:42:43.122Z",
        "modifiedTimeStamp": "2025-04-01T13:42:50.041Z",
        "createdBy": "sasshared@contoso.onmicrosoft.com",
        "modifiedBy": "sasshared@contoso.onmicrosoft.com",
        "version": 4,
        "id": "00f595b2-d575-4781-a75b-829578b5a9a9",
        "jobRequest": {
            "creationTimeStamp": "2025-04-01T13:41:52.277Z",
            "modifiedTimeStamp": "2025-04-01T13:41:52.277Z",
            "createdBy": "sasshared@contoso.onmicrosoft.com",
            "modifiedBy": "sasshared@contoso.onmicrosoft.com",
            "version": 3,
            "id": "44ca6f4f-8e1e-4ff6-a338-f6977885ca31",
            "name": "RunCAS",
            "description": "Start and Stop a CAS session",
            "jobDefinitionUri": "/jobDefinitions/definitions/18efdb16-dc76-4f11-b7c8-1bb17dc0d2ce",
            "jobDefinition": {
                "creationTimeStamp": "2025-04-01T13:38:09.205Z",
                "modifiedTimeStamp": "2025-04-01T13:38:09.206Z",
                "createdBy": "sasshared@contoso.onmicrosoft.com",
                "modifiedBy": "sasshared@contoso.onmicrosoft.com",
                "version": 2,
                "id": "18efdb16-dc76-4f11-b7c8-1bb17dc0d2ce",
                "name": "RunCAS",
                "description": "Create and terminate a CAS session",
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
                "code": "cas mysession; cas mysession terminate;",
                "links": [
                    {
                        "method": "GET",
                        "rel": "self",
                        "href": "/jobDefinitions/definitions/18efdb16-dc76-4f11-b7c8-1bb17dc0d2ce",
                        "uri": "/jobDefinitions/definitions/18efdb16-dc76-4f11-b7c8-1bb17dc0d2ce",
                        "type": "application/vnd.sas.job.definition"
                    },
                    {
                        "method": "GET",
                        "rel": "alternate",
                        "href": "/jobDefinitions/definitions/18efdb16-dc76-4f11-b7c8-1bb17dc0d2ce",
                        "uri": "/jobDefinitions/definitions/18efdb16-dc76-4f11-b7c8-1bb17dc0d2ce",
                        "type": "application/vnd.sas.summary"
                    },
                    {
                        "method": "PUT",
                        "rel": "update",
                        "href": "/jobDefinitions/definitions/18efdb16-dc76-4f11-b7c8-1bb17dc0d2ce",
                        "uri": "/jobDefinitions/definitions/18efdb16-dc76-4f11-b7c8-1bb17dc0d2ce",
                        "type": "application/vnd.sas.job.definition",
                        "responseType": "application/vnd.sas.job.definition"
                    },
                    {
                        "method": "DELETE",
                        "rel": "delete",
                        "href": "/jobDefinitions/definitions/18efdb16-dc76-4f11-b7c8-1bb17dc0d2ce",
                        "uri": "/jobDefinitions/definitions/18efdb16-dc76-4f11-b7c8-1bb17dc0d2ce"
                    }
                ]
            },
            "arguments": {
                "_contextName": "SAS Job Execution compute context"
            },
            "properties": [],
            "createdByApplication": "finance-frontend",
            "links": [
                {
                    "method": "GET",
                    "rel": "self",
                    "href": "/jobExecution/jobRequests/44ca6f4f-8e1e-4ff6-a338-f6977885ca31",
                    "uri": "/jobExecution/jobRequests/44ca6f4f-8e1e-4ff6-a338-f6977885ca31",
                    "type": "application/vnd.sas.job.execution.job.request"
                }
            ]
        },
        "state": "completed",
        "endTimeStamp": "2025-04-01T13:42:50.040Z",
        "heartbeatTimeStamp": "2025-04-01T13:42:43.343Z",
        "submittedByApplication": "finance-frontend",
        "heartbeatInterval": 600,
        "elapsedTime": 6918,
        "results": {
            "COMPUTE_CONTEXT": "SAS Job Execution compute context",
            "ECF786F4-42F4-A146-8EBC-7127B0AB51F9.log.txt": "/files/files/f566581f-437b-47b1-8a56-892a91aefda2",
            "COMPUTE_JOB": "ECF786F4-42F4-A146-8EBC-7127B0AB51F9",
            "COMPUTE_SESSION": "086cb298-92ea-4180-91f7-e45de837a9e7-ses0000 ended."
        },
        "logLocation": "/files/files/5b0e1276-8d38-46c6-a5e1-09824122cb2f",
        "links": [
            {
                "method": "GET",
                "rel": "self",
                "href": "/jobExecution/jobs/00f595b2-d575-4781-a75b-829578b5a9a9",
                "uri": "/jobExecution/jobs/00f595b2-d575-4781-a75b-829578b5a9a9",
                "type": "application/vnd.sas.job.execution.job"
            },
            {
                "method": "GET",
                "rel": "state",
                "href": "/jobExecution/jobs/00f595b2-d575-4781-a75b-829578b5a9a9/state",
                "uri": "/jobExecution/jobs/00f595b2-d575-4781-a75b-829578b5a9a9/state",
                "type": "text/plain"
            },
            {
                "method": "PUT",
                "rel": "update",
                "href": "/jobExecution/jobs/00f595b2-d575-4781-a75b-829578b5a9a9",
                "uri": "/jobExecution/jobs/00f595b2-d575-4781-a75b-829578b5a9a9",
                "type": "application/vnd.sas.job.execution.job",
                "responseType": "application/vnd.sas.job.execution.job"
            },
            {
                "method": "DELETE",
                "rel": "delete",
                "href": "/jobExecution/jobs/00f595b2-d575-4781-a75b-829578b5a9a9",
                "uri": "/jobExecution/jobs/00f595b2-d575-4781-a75b-829578b5a9a9"
            },
            {
                "method": "PUT",
                "rel": "updateState",
                "href": "/jobExecution/jobs/00f595b2-d575-4781-a75b-829578b5a9a9/state",
                "uri": "/jobExecution/jobs/00f595b2-d575-4781-a75b-829578b5a9a9/state",
                "type": "text/plain"
            },
            {
                "method": "POST",
                "rel": "updateHeartbeatTimeStamp",
                "href": "/jobExecution/jobs/00f595b2-d575-4781-a75b-829578b5a9a9/heartbeatTimeStamp",
                "uri": "/jobExecution/jobs/00f595b2-d575-4781-a75b-829578b5a9a9/heartbeatTimeStamp",
                "type": "text/plain"
            },
            {
                "method": "GET",
                "rel": "jobRequest",
                "href": "/jobExecution/jobRequests/44ca6f4f-8e1e-4ff6-a338-f6977885ca31",
                "uri": "/jobExecution/jobRequests/44ca6f4f-8e1e-4ff6-a338-f6977885ca31",
                "type": "application/vnd.sas.job.execution.job.request"
            },
            {
                "method": "GET",
                "rel": "jobDefinition",
                "href": "/jobDefinitions/definitions/18efdb16-dc76-4f11-b7c8-1bb17dc0d2ce",
                "uri": "/jobDefinitions/definitions/18efdb16-dc76-4f11-b7c8-1bb17dc0d2ce",
                "type": "application/vnd.sas.job.definition"
            },
            {
                "method": "GET",
                "rel": "log",
                "href": "/files/files/5b0e1276-8d38-46c6-a5e1-09824122cb2f",
                "uri": "/files/files/5b0e1276-8d38-46c6-a5e1-09824122cb2f"
            }
        ]
    }
    ```
    </details>
    
4. Get the log file for this job

    <details>
    <summary>API Call</summary>

    ```
    curl --request GET \
      --url "${INGRESS_URL}/files/files/5b0e1276-8d38-46c6-a5e1-09824122cb2f/content" \
      --header 'Accept: application/vnd.sas.error+json' \
      --header "Authorization: Bearer $OAUTH_TOKEN"
    ```

    </details>
    <details>
    <summary>API Response</summary>

    ```
    {
        "version": 2,
        "name": "items",
        "accept": "application/vnd.sas.compute.log.line",
        "start": 0,
        "items": [
            {
                "version": 1,
                "type": "source",
                "line": "1    cas mysession;"
            },
            {
                "version": 1,
                "type": "note",
                "line": "NOTE: The session MYSESSION connected successfully to Cloud Analytic Services sas-cas-server-default-client using port 5570. "
            },
            {
                "version": 1,
                "type": "note",
                "line": "      The UUID is bf971bdd-2d08-c042-b6f2-4be1511bd9b3. The user is sasshared@contoso.onmicrosoft.com and the active caslib is "
            },
            {
                "version": 1,
                "type": "note",
                "line": "      CASUSER(sasshared@contoso.onmicrosoft.com)."
            },
            {
                "version": 1,
                "type": "note",
                "line": "NOTE: The SAS option SESSREF was updated with the value MYSESSION."
            },
            {
                "version": 1,
                "type": "note",
                "line": "NOTE: The SAS macro _SESSREF_ was updated with the value MYSESSION."
            },
            {
                "version": 1,
                "type": "note",
                "line": "NOTE: The session is using 0 workers."
            },
            {
                "version": 1,
                "type": "source",
                "line": "1  !                    cas mysession terminate;"
            },
            {
                "version": 1,
                "type": "note",
                "line": "NOTE: Deletion of the session MYSESSION was successful."
            },
            {
                "version": 1,
                "type": "note",
                "line": "NOTE: The default CAS session MYSESSION identified by SAS option SESSREF= was terminated. Use the OPTIONS statement to set the "
            },
            {
                "version": 1,
                "type": "note",
                "line": "      SESSREF= option to an active session."
            },
            {
                "version": 1,
                "type": "note",
                "line": "NOTE: Request to TERMINATE completed for session MYSESSION."
            }
        ],
        "count": 12,
        "limit": 12,
        "links": []
    }
    ```
    </details>

As you can see, the user running the compute and CAS sessions is now sasshared@contoso in both cases. This difference also has its consequences when connecting to external services as we will see in the [next](./external-services.md) section.

[^1]: https://go.documentation.sas.com/doc/en/calintro/latest/p1mf381di3nmsan1dmpq25b7w7ic.htm#p1ko0541331zn7n1at3arrz1amut/

[^2]: https://go.documentation.sas.com/doc/en/mascdc/default/masag/p0gehkxmerovitn1w5nv6yvgpws5.htm

[^3]: https://go.documentation.sas.com/doc/en/espcdc/default/espov/home.htm