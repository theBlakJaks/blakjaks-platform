\# Introduction

Welcome to the Teller API Reference

The Teller API is organized around REST. Resources have predictable, self-describing URLs and contain links to related resources. Our API accepts form-encoded requests and returns JSON encoded responses. It uses standard HTTP status codes, authentication, and methods in their usual ways.

You can use the Teller API in sandbox mode, which is free, does not call out to any real banks, and does not affect your live data. The access token you use determines whether your request is handled in the live or sandbox environments.

Access tokens for the live environment are obtained using Teller Connect when a user successfully connects a bank account to your Teller application.

\> \*\*Note\*\*  
\>  
\> Learn how to integrate Teller Connect into your application with the \[Teller Connect integration guide\](/docs/guides/connect)

\#\# Rate Limits

Teller enforces rate limits to maintain system stability and protect the integrity of connections with financial institutions. These limits help ensure that excessive traffic does not trigger hostile or defensive measures from banks, which could impact connectivity for all customers.

Free-tier accounts are subject to rate limits. The exact thresholds are not publicly documented and cannot be adjusted. If you’re on the free plan, design your integration to be efficient and resilient under these constraints.

Production plans benefit from significantly higher rate limits. In practice, it’s rare for production applications to hit these ceilings under normal usage. The limits are designed to balance performance with reliability—preventing overload scenarios that could degrade service quality for other customers.

Rate limiting is not just about controlling traffic. It is part of being a responsible participant in the broader financial ecosystem. By moderating the volume of requests sent to institutions, we help maintain long-term access, reduce the risk of disruption, and demonstrate respect for the operational boundaries of the banks we connect to. It reflects our commitment to being a good steward of shared infrastructure—for your users, for other developers, and for the institutions themselves.

If your application triggers rate limits, Teller will respond with an HTTP 429 status code. Your system should back off and retry after an appropriate delay.

\#\# API Entrypoint

\`\`\`bash  
https://api.teller.io/  
\`\`\`

\#\# Versioning

Teller uses dated versions with the latest one being 2020-10-12. By default all API requests will use the version specified in the \[Teller Dashboard\](https://teller.io/settings/application).

In order to test a new version, you can request it using the Teller-Version HTTP header. Once you are ready to upgrade to a new version permanently, you can do so from the dashboard. You will have 72 hours to rollback to the version you were previously using.

\`\`\`bash  
curl https://api.teller.io/accounts \-H "Teller-Version: 2019-07-01"  
\`\`\`  
\# Authentication

Nearly all of the Teller API endpoints require authentication. In this guide we'll look at mTLS and HTTP Basic Auth, which are the different types of authentication used in the Teller API and when and why they are used.

\#\# mTLS

In a normal TLS handshake the client uses the server's TLS certificate to authenticate its identity. Because the server is in possession of a certificate signed by a trusted certificate authority, the client is able to verify all of the handshake messages were sent by the server and there was no third-party eavesdropping on or worse, tampering with the channel. Sadly this allows the server to verify neither the identity of the client nor that an attacker isn't snooping or tampering with the channel. Unfortunately it's not uncommon to misconfigure TLS certificate validation, thereby invalidating all of the aforementioned guarantees. Given that the Teller API facilitates access to some of the most sensitive and private information possible, a scenario where Teller is not able to verify the integrity and confidentiality of the API is not something we can allow to happen.

\*\*The Teller API uses mTLS to authenticate the API caller\*\*. Teller issues client certificates that you use to connect to the Teller API. This allows both parties to mutually authenticate each other, and most importantly enables Teller to authenticate API clients even when API clients are not performing TLS verification correctly.

mTLS is \*\*required\*\* for all API requests that involve end-user data, i.e. all requests in \`development\` and \`production\`.

In the interests of getting up and running as quickly as possible client authentication is not required in the \`sandbox\` environment, because it does not involve real end-user data. If used, client certificates are validated in the \`sandbox\` environment. We recommend using client certificates as soon as possible in order to become familiarized with them.

\`\`\`bash  
curl \--cert /path/to/cert.pem \--key /path/to/key.pem https://api.teller.io  
\`\`\`

Always keep your private key safe and secret. You must never share or distribute your private key, e.g. embedding it in a mobile app. If you suspect your private key has been compromised, you must revoke the certificate in the Teller Dashboard and issue a new one.

\#\# Access Token

Access tokens are created when an end-user successfully completes an enrollment using Teller Connect. An access token represents your authorization to access accounts at a given financial institution that the end-user has expressly given consent for. Access tokens are useless without a Teller client certificate, in fact they are useless without a client certificate belonging to the application the user consented giving access to. The Teller API will not even acknowledge an access token is correct without the correct certificate.

Access tokens are encoded using the HTTP Basic Auth scheme.

\`\`\`bash  
curl \-u ACCESS\_TOKEN: https://api.teller.io/accounts  
\`\`\`  
\# Errors

Learn how error conditions are expressed in the Teller API

Teller uses standard HTTP response status codes to indicate the success or failure of a request. Status codes in the 2xx range denote a successful request. Status codes in the 4xx range denote a client error, e.g. not using a client certificate to make the request, a problem with the user access token, etc. Status codes in the 5xx range denote a problem on our end, e.g. a bank is unavailable and it's not possible or otherwise doesn't make sense to gracefully handle the exception.

\> \*\*Note\*\*  
\>  
\> Failed requests do not generate billing events

\#\# Status Codes

Here is a list of status codes currently in use by the Teller API

\-   \`200 OK\` \_()\_ \- A successful request.

\-   \`400 Bad Request\` \_()\_ \- The request was unacceptable. Used when a request that requires a client certificate is made without one.

\-   \`401 Unauthorized\` \_()\_ \- A request was made without an access token where one was required.

\-   \`403 Forbidden\` \_()\_ \- A request was made with an invalid or revoked access token.

\-   \`404 Not Found\` \_()\_ \- The requested resource was not found.

\-   \`410 Gone\` \_()\_ \- Indicates that the resource requested is no longer available and that condition is permanent, e.g. because a financial account was closed.

\-   \`422 Unprocessable Entity\` \_()\_ \- A request was made with an invalid request body.

\-   \`429 Too Many Requests\` \_()\_ \- Indicates that the application has exceeded its rate limit by sending too many requests in a given time period and that this request was denied.

\-   \`502 Bad Gateway\` \_()\_ \- The financial institution is unavailable, or a 500 level response was received when making a request to the financial institution, and a graceful fallback is not possible, e.g. a payment instruction.

\#\# The Error Object

Detailed information about the error condition is returned in the response body as a JSON object.

\`\`\`json  
{  
  "error": {  
      "code": "bad\_request",  
      "message": "Missing certificate: Retry request using your Teller client certificate."  
  }  
}  
\`\`\`

\-   \`error\` \_(object)\_ \- An object describing the error condition.  
    \-   \`code\` \_(string)\_ \- The error condition.  
    \-   \`message\` \_(string)\_ \- A human readable string describing the error and how to resolve it.

\#\# Enrollment Errors

From time to time enrollments can enter an unhealthy state, meaning Teller is unable to use it until the end-user takes the required action. When your application makes a request involving a disconnected enrollment Teller returns a 404 status code with an error code beginning with \`enrollment.disconnected\`.

\> \*\*Note\*\*  
\>  
\> To restore an unhealthy enrollment initialize Teller Connect in update mode and direct the user to reconnect.

When an enrollment enters a disconnected state, Teller can send a \[webhook event\](/docs/api/webhooks) of type \`enrollment.disconnected\`.

\`\`\`json  
{  
  "error": {  
    "code": "enrollment.disconnected.user\_action.mfa\_required",  
    "message": "User MFA is required."  
  }  
}  
\`\`\`

\#\# Enrollment Error Codes

\-   \`enrollment.disconnected\` \_()\_ \- A generic error used for when no more information is available.

\-   \`enrollment.disconnected.account\_locked\` \_()\_ \- Access to the account has been restricted by the financial institution.

\-   \`enrollment.disconnected.credentials\_invalid\` \_()\_ \- The end-user changed their authentication credentials to access the financial institution.

\-   \`enrollment.disconnected.enrollment\_inactive\` \_()\_ \- The enrollment has become disconnected due to inactivity.

\-   \`enrollment.disconnected.user\_action.captcha\_required\` \_()\_ \- The end-user is required to solve a CAPTCHA.

\-   \`enrollment.disconnected.user\_action.contact\_information\_required\` \_()\_ \- The end-user is required to update their contact information.

\-   \`enrollment.disconnected.user\_action.insufficient\_permissions\` \_()\_ \- The end-user does not have the required permissions to perform the requested operation.

\-   \`enrollment.disconnected.user\_action.mfa\_required\` \_()\_ \- The end-user is required to complete a MFA challenge.

\-   \`enrollment.disconnected.user\_action.web\_login\_required\` \_()\_ \- The end-user is required to login to the financial institution's web online-banking, e.g. to accept FI terms and conditions.  
\# Webhooks

Learn how to register your application to receive and verify webhook notifications from Teller and be notified of events not represented in the Teller API itself

\#\# When Webhooks Are Triggered

Teller sends webhook events when specific conditions or changes are detected in user enrollments or their financial data. Webhooks are triggered in response to these events, which represent meaningful state changes within the Teller system.

For example, the \`transactions.processed\` webhook is sent when Teller finds new transactions after polling a user’s connected financial institution. Teller performs these checks multiple times per day on a non-predictable schedule, but guarantees at least one polling attempt every 24 hours.

Another example is the \`enrollment.disconnected\` webhook, which is triggered when Teller determines that an enrollment’s connection to the institution is irrecoverably broken and cannot be automatically restored.

These events can interact. For instance, if Teller temporarily loses connectivity to an enrollment but hasn’t yet classified it as disconnected, it may not be able to access up-to-date account data. As a result, no \`transactions.processed\` events will be sent during that time. Webhooks resume once connectivity is restored or the enrollment is marked as disconnected.

\#\# Registering Webhooks

To register a new webhook, you need to have a URL in your app that Teller can call. You can configure a new webhook from the Teller Dashboard under \[Application Settings\](https://teller.io/settings/application).

Now, whenever something of interest happens in your app, a webhook is fired off by Teller. In the next section, we'll look at how to consume webhooks.

\#\# Consuming Webhooks

When your app receives a webhook request from Teller, check the \`type\` attribute to see what event caused it. The first part of the event type categorizes the payload type, e.g., \`enrollment\`, \`transaction\`, etc.

\`\`\`json  
{  
  "id": "wh\_oiffb5cocakqmksbkg000",  
  "payload": {  
    "enrollment\_id": "enr\_oiffb5cocakqmksbkg001",  
    "reason": "disconnected.account\_locked"  
  },  
  "timestamp": "2023-07-10T03:49:29Z",  
  "type": "enrollment.disconnected"  
}  
\`\`\`

In the example above, an enrollment has entered a disconnected state because the financial institution has completely locked the account. This may happen for legal reasons, because an account has been involved in fraud, or an attacker has repeatedly tried to login by guessing the end user's credentials.

\#\# The Webhook Object

The webhook object has the following shape:

\-   \`id\` \_(string)\_ \- The id of the webhook event

\-   \`payload\` \_(object)\_ \- Event specific data or an empty object if \`"type": "webhook.test"\`

\-   \`timestamp\` \_(string)\_ \- The ISO 8601 timestamp of the event.

\-   \`type\` \_(string)\_ \- The type of the event, either:  
    \-   \`enrollment.disconnected\` — Sent when the enrollment disconnected  
    \-   \`transactions.processed\` — Sent when transactions are categorized by Teller's transaction enrichment  
    \-   \`account.number\_verification.processed\` \- Sent when account details verification via microdeposit has either suceeded or expired (see \['Verify Account Details via Microdeposit'\](/docs/api/account/details\#account-details-verification-via-microdeposit))  
    \-   \`webhook.test\` — A test event triggered from the \[Application Settings\](https://teller.io/settings/application) page. Use this to test your webhook implementation.

The shape of the \`payload\` depends on the event's \`type\`

\#\# Payload shape

\-   \`enrollment\_id\` \_(string)\_ \- The id of the affected enrollment

\-   \`reason\` \_(string)\_ \-

    \> Available when \`"type": "enrollment.disconnected"\` only

    The reason the enrollment was disconnected. Possible values:

    \-   \`disconnected\`  
    \-   \`disconnected.account\_locked\`  
    \-   \`disconnected.credentials\_invalid\`  
    \-   \`disconnected.enrollment\_inactive\`  
    \-   \`disconnected.user\_action.captcha\_required\`  
    \-   \`disconnected.user\_action.contact\_information\_required\`  
    \-   \`disconnected.user\_action.insufficient\_permissions\`  
    \-   \`disconnected.user\_action.mfa\_required\`  
    \-   \`disconnected.user\_action.web\_login\_required\`

\-   \`transactions\` \_(array)\_ \-

    \> Available when \`"type": "transactions.processed"\` only

    An array of categorized transactions. The shape of the transaction objects is described in the \[Transactions\](/docs/api/account/transactions) page

\-   \`account\_id\` \_(string)\_ \-

    \> Available when \`"type": "account.number\_verification.processed"\` only

    The id of the account the details of which needed to be verified

\-   \`status\` \_(string)\_ \-

    \> Available when \`"type": "account.number\_verification.processed"\` only

    The status of the verification. Possible values:

    \-   \`completed\`  
    \-   \`expired\`

\#\# Verifying Messages

Teller signs every webhook event with all non-expired signing secrets, that only you and Teller know. You can get your signing secrets from the \[Application Settings\](https://teller.io/settings/application) page.

Teller sends a signature in the Teller-Signature HTTP header:

\`\`\`  
Teller-Signature: t=signature\_timestamp,v1=signature\_1,v1=signature\_2,v1=...  
\`\`\`

Most of the time there will be only one non-expired signing secret, so the signature header will look like this:

\`\`\`  
Teller-Signature: t=signature\_timestamp,v1=signature  
\`\`\`

To verify that the payload was created by Teller, you have to calculate the signature and it must be equal to the signature extracted from the signature header.

To calculate the signature:

\-   Create \`signed\_message\` by joining \`signature\_timestamp\` and the request's JSON body with a . character  
\-   Compute HMAC with SHA-256 using the non-expired signing secret as the key and \`signed\_message\` as the message

To prevent replay attacks you should reject webhook events with a \`signature\_timestamp\` (Unix time) older than 3 minutes.

\#\# Expiring Secrets

When you have a policy to periodically roll secrets, Teller allows you to do it without a gap in signature verification.

To expire the current signing secret, go to the \[Application Settings\](https://teller.io/settings/application) page and select when the secret should expire, e.g. in 2 hours. When you press Save, Teller will create a new non-expired secret, and from that moment, Teller will sign all webhook events with both secrets until the old secret expires:

\`\`\`  
Teller-Signature: t=signature\_timestamp,v1=signature\_with\_new\_secret,v1=signature\_with\_old\_secret  
\`\`\`

This gives you time to update your application with the new secret.  
\# Identity

Identity provides you with all of the accounts the end-user granted your application access authorization along with beneficial owner identity information for each of them. Beneficial owner information is attached to each account as it's possible the end-user is not the beneficial owner, e.g. a corporate account, or there is more than one beneficial owner, e.g. a joint account the end-user shares with their partner.

\#\# Properties

\-   \`type\` \_(string)\_ \- \`person\`, \`organization\` or \`unknown\`.

\-   \`names\` \_(array)\_ \- An array of \`name\` objects with the following shape: (can be an empty list)  
    \-   \`type\` \_(string)\_ \- \`name\` or \`alias\`.  
    \-   \`data\` \_(string)\_ \- Name of the person or organization.

\-   \`addresses\` \_(array)\_ \- An array of \`address\` objects. Can be an empty list.  
    \-   \`primary\` \_(boolean)\_ \- Indicates if this is the owner's primary address (in case multiple addresses are provided).  
    \-   \`data\` \_(object)\_ \-  
        \-   \`street\` \_(string)\_ \- The street address.  
        \-   \`city\` \_(string)\_ \- The name of the town or city.  
        \-   \`region\` \_(string)\_ \- The state or region. For US addresses it's a 2-letter uppercase state code, e.g. "AL".  
        \-   \`postal\_code\` \_(string)\_ \- The zip or postal code. For US addresses it can be a 5-digit ZIP code or a ZIP+4 code: 5 and 4 digits separated with a hyphen.  
        \-   \`country\` \_(string)\_ \- The ISO 3166-1 alpha-2 2-letter country codes, e.g. "US".

\-   \`phone\_numbers\` \_(array)\_ \- An array of \`phone\_number\` objects with the following shape: (can be an empty list)  
    \-   \`type\` \_(string)\_ \- \`mobile\`, \`home\`, \`work\` or \`unknown\`.  
    \-   \`data\` \_(string)\_ \- The phone number digits only or prefixed with a "+" if in an international (E.164) format.

\-   \`emails\` \_(array)\_ \- An array of \`email\` objects with the following shape: (can be an empty list)  
    \-   \`data\` \_(string)\_ \- An email address.

\*\*\*

\#\# Get Identity

Returns an array of accounts with beneficial owner identity information attached. Each item in the list is an object of the following type:

\#\#\# Properties

\-   \`account\` \_(object)\_ \- An \`account\` object. See the \[documentation\](/docs/api/accounts) for type information.

\-   \`owners\` \_(array)\_ \- An array of identity objects of the type defined \[above\](\#properties).

\`\`\`bash  
curl https://api.teller.io/identity \\  
  \-u test\_token\_ky6igyqi3qxa4:  
\`\`\`

\`\`\`json  
\[  
  {  
      "account" : {  
        "name" : "Essential Savings",  
        "last\_four" : "3528",  
        "type" : "depository",  
        "enrollment\_id" : "enr\_oiin624rqaojse22oe000",  
        "id" : "acc\_oiin624jqjrg2mp2ea000",  
        "status" : "open",  
        "links" : {  
            "self" : "https://api.teller.io/accounts/acc\_oiin624jqjrg2mp2ea000",  
            "transactions" : "https://api.teller.io/accounts/acc\_oiin624jqjrg2mp2ea000/transactions",  
            "balances" : "https://api.teller.io/accounts/acc\_oiin624jqjrg2mp2ea000/balances",  
            "details" : "https://api.teller.io/accounts/acc\_oiin624jqjrg2mp2ea000/details"  
        },  
        "institution" : {  
            "id" : "security\_cu",  
            "name" : "Security Credit Union"  
        },  
        "subtype" : "savings",  
        "currency" : "USD"  
      },  
      "owners" : \[  
        {  
            "addresses" : \[  
              {  
                  "primary" : true,  
                  "data" : {  
                    "postal\_code" : "55305",  
                    "street" : "4849 SYCAMORE FORK ROAD",  
                    "region" : "MINNESOTA",  
                    "country" : "US",  
                    "city" : "HOPKINS"  
                  }  
              }  
            \],  
            "type" : "organization",  
            "names" : \[  
              {  
                  "data" : "URBAN GROCERIES INC",  
                  "type" : "name"  
              }  
            \],  
            "phone\_numbers" : \[  
              {  
                  "data" : "6667778888",  
                  "type" : "mobile"  
              }  
            \],  
            "emails" : \[  
              {  
                  "data" : "urban\_groceries\_inc@example.com"  
              }  
            \]  
        }  
      \]  
  },  
...  
\]  
\`\`\`  
\# Accounts

An Account represents an end-user's individual financial account at a given financial institution.

\#\# Properties

\-   \`currency\` \_(string)\_ \- The ISO 4217 currency code of the account.

\-   \`enrollment\_id\` \_(string)\_ \- The id of the enrollment that the account belongs to.

\-   \`id\` \_(object)\_ \- The id of the account itself.

\-   \`institution\` \_(object)\_ \- An object containing information about the financial institution that holds the account.  
    \-   \`id\` \_(string)\_ \- The internal Teller id assigned to the financial institution.  
    \-   \`name\` \_(string)\_ \- The name of the financial institution that holds the account.

\-   \`last\_four\` \_(string)\_ \- The last four digits of the account number.

\-   \`links\` \_(object)\_ \- An object containing links to related resources. A link indicates the enrollment supports that type of resource. Not every institution implements all of the capabilities that Teller supports. Your application should reflect on the contents of this object to determine what is supported by the financial institution.  
    \-   \`self\` \_(string)\_ \- A self link to the account.  
    \-   \`details\` \_(string)\_ \- A link to the account's details, such as account number and routing numbers.  
    \-   \`balances\` \_(string)\_ \- A link to the account's live balances.  
    \-   \`transactions\` \_(string)\_ \- A link to the account's transactions.

\-   \`name\` \_(string)\_ \- The account's name.

\-   \`type\` \_(string)\_ \- The type of account. Either \`depository\` or \`credit\`.

\-   \`subtype\` \_(string)\_ \- The account's subtype.

    depository:  
    checking, savings, money\_market, certificate\_of\_deposit, treasury, sweep  
    credit:  
    credit\_card

\-   \`status\` \_(string)\_ \- The account's status: \`open\` or \`closed\`. When \\\`closed it means that it's closed from Teller's perspective, i.e. Teller can still access live enrollment data from the institution, but the account itself is closed, Teller can no longer see that account, or the account transitioned to an insufficient-access state.

    When you try to request an account or any of its sub-resources, and that account is \`closed\`, Teller returns a 410 response with \`account.closed\` error. You should parse the error as a dot-separated string where the first token is account.closed and the subsequent tokens, if present, include the reason for closing.

\*\*\*

\#\# List Accounts

Returns a list of all accounts the end-user granted access to during enrollment in Teller Connect.

\`\`\`bash  
curl https://api.teller.io/accounts \\  
  \-u test\_token\_ky6igyqi3qxa4:  
\`\`\`

\`\`\`json  
\[  
  {  
      "enrollment\_id" : "enr\_oiin624rqaojse22oe000",  
      "links" : {  
        "balances" : "https://api.teller.io/accounts/acc\_oiin624kqjrg2mp2ea000/balances",  
        "self" : "https://api.teller.io/accounts/acc\_oiin624kqjrg2mp2ea000",  
        "transactions" : "https://api.teller.io/accounts/acc\_oiin624kqjrg2mp2ea000/transactions"  
      },  
      "institution" : {  
        "name" : "Security Credit Union",  
        "id" : "security\_cu"  
      },  
      "type" : "credit",  
      "name" : "Platinum Card",  
      "subtype" : "credit\_card",  
      "currency" : "USD",  
      "id" : "acc\_oiin624kqjrg2mp2ea000",  
      "last\_four" : "7857",  
      "status" : "open"  
  },  
  ...  
\]  
\`\`\`

\*\*\*

\#\# Get Account

Retrieve a specific account by it's id.

\`\`\`bash  
curl https://api.teller.io/accounts/acc\_oiin624kqjrg2mp2ea000 \\  
  \-u test\_token\_ky6igyqi3qxa4:  
\`\`\`

\`\`\`json  
{  
    "enrollment\_id" : "enr\_oiin624rqaojse22oe000",  
    "links" : {  
      "balances" : "https://api.teller.io/accounts/acc\_oiin624kqjrg2mp2ea000/balances",  
      "self" : "https://api.teller.io/accounts/acc\_oiin624kqjrg2mp2ea000",  
      "transactions" : "https://api.teller.io/accounts/acc\_oiin624kqjrg2mp2ea000/transactions"  
    },  
    "institution" : {  
      "name" : "Security Credit Union",  
      "id" : "security\_cu"  
    },  
    "type" : "credit",  
    "name" : "Platinum Card",  
    "subtype" : "credit\_card",  
    "currency" : "USD",  
    "id" : "acc\_oiin624kqjrg2mp2ea000",  
    "last\_four" : "7857",  
    "status" : "open"  
}  
\`\`\`

\*\*\*

\#\# Delete Account

This deletes your application's authorization to access the given account as addressed by its id. This does not delete the account itself.

Removing access will cancel billing for subscription billed products associated with the account, e.g. transactions.

\`\`\`bash  
curl \-X DELETE https://api.teller.io/accounts/acc\_oiin624kqjrg2mp2ea000 \\  
  \-u test\_token\_ky6igyqi3qxa4:  
\`\`\`

\`\`\`json  
// No response body, e.g. 204 No Content  
\`\`\`

\*\*\*

\#\# Delete Accounts

This deletes your application's authorization to access any account in the  
enrollment, i.e. effectively deletes the enrollment. This does not delete  
the accounts themselves.

Removing access will cancel billing for subscription billed products  
associated with the enrollment, e.g. transactions.

\`\`\`bash  
curl \-X DELETE https://api.teller.io/accounts \\  
  \-u test\_token\_ky6igyqi3qxa4:  
\`\`\`

\`\`\`json  
// No response body, e.g. 204 No Content  
\`\`\`  
\# Account Details

The account details object contains the financial account's account number and routing information.

\#\# Properties

\-   \`account\_id\` \_(string)\_ \- The id of the account the account details belong to.

\-   \`account\_number\` \_(string)\_ \- The account number.

\-   \`links\` \_(object)\_ \- An object containing links to related resources. A link indicates the enrollment supports that type of resource. Not every institution implements all of the capabilities that Teller supports. Your application should reflect on the contents of this object to determine what is supported by the financial institution.  
    \-   \`self\` \_(string)\_ \- A self link to the account details.  
    \-   \`account\` \_(string)\_ \- A link to the account that owns the details.

\-   \`routing\_numbers\` \_(object)\_ \- An object containing the account details routing numbers.  
    \-   \`ach\` \_(string (nullable))\_ \- The account's routing number for ACH transactions.  
    \-   \`wire\` \_(string (nullable))\_ \- The account's wire routing number.  
    \-   \`bacs\` \_(string (nullable))\_ \- The account's BACS sort code.

\*\*\*

\#\# Get Account Details

Returns the account's details.

\`\`\`bash  
curl https://api.teller.io/accounts/acc\_oiin624iajrg2mp2ea000/details \\  
  \-u test\_token\_ky6igyqi3qxa4:  
\`\`\`

\`\`\`json  
{  
  "links" : {  
      "account" : "https://api.teller.io/accounts/acc\_oiin624iajrg2mp2ea000",  
      "self" : "https://api.teller.io/accounts/acc\_oiin624iajrg2mp2ea000/details"  
  },  
  "routing\_numbers" : {  
      "ach" : "066474405"  
  },  
  "account\_id" : "acc\_oiin624iajrg2mp2ea000",  
  "account\_number" : "142999287346"  
}  
\`\`\`

\*\*\*

\#\# Account Details verification via Microdeposit

Account details are available instantly after an enrollment for the majority of  
institutions supported by Teller. These institutions have the \`verify.instant\`  
product in the response from the \[Institutions API  
endpoint\](/docs/api/institutions). However, this is not possible for a number of  
institutions (those that have \`verify.microdeposit\` products in the API response  
from the \[Institutions API endpoint\](/docs/api/institutions)). To access  
account details from these institutions, you can implement the 'Verify Account  
Details via Microdeposit\\\` flow. Your customers will enter account and routing  
numbers for the accounts that they would like to enroll in Teller Connect, and  
Teller will send a microdeposit to the accounts to verify that they are  
correct.

\#\#\# Enabling / disabling the flow

To enable the flow, \[initialize Teller  
Connect\](/docs/guides/connect\#configuration-options) with \`verify\` specified among  
the products using the \`products\` property. To disable the flow and only  
enable institutions that provide account details instantly, specify  
the \`verify.instant\` product instead.

If you don't need account details but would like to enroll users with the  
institutions that require this flow to use other Teller products, don't  
specify \`verify\` product when initializing Teller Connect. Your users won't be  
prompted to enter account numbers when they enroll.

\#\#\# Accessing Account Details

When using this flow, account details become available after a successful  
verification: once we've confirmed that the microdeposit sent by us is present  
among the account's transactions, we'll make the account details available via  
the API. This usually happens within 3 business days. You can also subscribe to  
an \`account.number\_verification.processed\` \[webhook\](/docs/api/webhooks) to be  
notified about completed verifications.

While the verification is pending, the \`/accounts/:account\_id/details\` API  
endpoint will return a \`404 Not Found\` error with the following body:

\`\`\`json  
{  
  "error": {  
    "code": "account\_number\_verification\_pending",  
    "message": "Account details are not yet available because the verification via microdeposit is pending"  
  }  
}  
\`\`\`

If we are not able to verify the details entered by the user within 7 calendar  
days, the verification expires, and the \`/accounts/:account\_id/details\` API  
endpoint will start returning a \`404 Not Found\` error with the following body:

\`\`\`json  
{  
  "error": {  
    "code": "account\_number\_verification\_expired",  
    "message": "Account details are not available because the verification via microdeposit has expired"  
  }  
}  
\`\`\`

We'll also send a \`account.number\_verification.processed\` webhook when the  
verification expires.

\#\#\# Testing the flow in Sandbox

To test this flow in \[Sandbox\](/docs/guides/sandbox), \[initialize Teller  
Connect\](/docs/guides/connect\#configuration-options) with \`verify\` product and use  
\`verify.microdeposit\` as the username in Teller Connect. You'll get access to  
two accounts called \`Success\` and \`Failure\`, and you'll be asked to enter the  
account number and routing number for both. Enter any number that ends with the  
account number suffix shown in Teller Connect and any valid routing number  
(e.g. \`110000000\`).

After enrolling you can fetch account details to see what the response  
looks like when the verification is pending. Verification is triggered by  
fetching transactions: if you make an API call to fetch transactions for the  
account called \`Success\`, a microdeposit transaction will be present in the  
response and the account details verification will succeeed. You'll then be  
able to fetch account details from the API.

If you make an API call to fetch transactions for the account called \`Failure\`,  
there won't be a microdeposit transaciton present and the verification will  
expire. If you make an API call to fetch account details, you'll get an error  
saying that the verification has expired.

\#\#\# Considerations

Consider using \[\`selectAccount\` configuration  
parameter\](/docs/guides/connect\#configuration-options) in Teller Connect to limit the  
number of accounts your users enroll or let the user select which accounts they  
want to enroll to avoid making users enter details for the accounts that you  
don't need access to.

When a verification expires, the enrollment remains healthy and you might be  
billed for it, so consider \[disconnecting such  
enrollments\](/docs/api/accounts\#delete-accounts) if you don't need access to the  
enrollment.  
\# Account Balances

The account balances API provides your application with live, real-time account  
balances. At least one balance (ledger or available) is always provided.

\#\# Properties

\-   \`account\_id\` \_(string)\_ \- The id of the account the account balances belong to.

\-   \`ledger\` \_(string (nullable))\_ \- The account's ledger balance. The ledger balance is the total amount of funds in the account.

\-   \`available\` \_(string (nullable))\_ \- The account's available balance. The available balance is the ledger balance net any pending inflows or outflows.

\-   \`links\` \_(object)\_ \- An object containing links to related resources. A link indicates the enrollment supports that type of resource. Not every institution implements all of the capabilities that Teller supports. Your application should reflect on the contents of this object to determine what is supported by the financial institution.  
    \-   \`self\` \_(string)\_ \- A self link to the account balances.  
    \-   \`account\` \_(string)\_ \- A link to the account that owns the balances.

\*\*\*

\#\# Get Account Balances

Returns the account's balances.

\`\`\`bash  
curl https://api.teller.io/accounts/acc\_oiin624iajrg2mp2ea000/balances \\  
  \-u test\_token\_ky6igyqi3qxa4:  
\`\`\`

\`\`\`json  
{  
  "ledger" : "28575.02",  
  "links" : {  
      "account" : "https://api.teller.io/accounts/acc\_oiin624iajrg2mp2ea000",  
      "self" : "https://api.teller.io/accounts/acc\_oiin624iajrg2mp2ea000/balances"  
  },  
  "account\_id" : "acc\_oiin624iajrg2mp2ea000",  
  "available" : "28575.02"  
}  
\`\`\`  
\# Transactions

The transactions API exposes the ledger transactions of a financial account.

\> \*\*Note\*\*  
\>  
\> The initial call to the transactions API can sometimes time out with accounts that have an abnormally large number of transactions. Should this happen wait a few seconds and try again.

\#\# Properties

\-   \`account\_id\` \_(string)\_ \- The id of the account that the transaction belongs to.

\-   \`amount\` \_(string)\_ \- The signed amount of the transaction as a string.

\-   \`date\` \_(string)\_ \- The ISO 8601 date of the transaction.

\-   \`description\` \_(string)\_ \- The unprocessed transaction description as it appears on the bank statement.

\-   \`details\` \_(object)\_ \- An object containing additional information regarding the transaction added by Teller's transaction enrichment.  
    \-   \`processing\_status\` \_(string)\_ \- Indicates the transaction enrichment processing status. Either \`pending\` or \`complete\`.  
    \-   \`category\` \_(string (nullable))\_ \- The category that the transaction belongs to. Teller uses the following values for categorization: \`accommodation\`, \`advertising\`, \`bar\`, \`charity\`, \`clothing\`, \`dining\`, \`education\`, \`electronics\`, \`entertainment\`, \`fuel\`, \`general\`, \`groceries\`, \`health\`, \`home\`, \`income\`, \`insurance\`, \`investment\`, \`loan\`, \`office\`, \`phone\`, \`service\`, \`shopping\`, \`software\`, \`sport\`, \`tax\`, \`transport\`, \`transportation\`, and \`utilities\`.  
    \-   \`counterparty\` \_(object)\_ \- An object containing information regarding the transaction's recipient  
        \-   \`name\` \_(string (nullable))\_ \- The processed counterparty name.  
        \-   \`type\` \_(string (nullable))\_ \- The counterparty type: \`organization\` or \`person\`.

\-   \`status\` \_(string)\_ \- The transaction's status: \`posted\` or \`pending\`.

\-   \`id\` \_(string)\_ \- The id of the transaction itself.

\-   \`links\` \_(object)\_ \- An object containing links to related resources. A link indicates the enrollment supports that type of resource. Not every institution implements all of the capabilities that Teller supports. Your application should reflect on the contents of this object to determine what is supported by the financial institution.  
    \-   \`self\` \_(string)\_ \- A self link to the transaction.  
    \-   \`account\` \_(string)\_ \- A link to the account that the transaction belongs to.

\-   \`running\_balance\` \_(string (nullable))\_ \- The running balance of the account that the transaction belongs to. Running balance is only present on transactions with a \`posted\` status.

\-   \`type\` \_(string)\_ \- The type code transaction, e.g. \`card\_payment\`.

\*\*\*

\#\# List Transactions

Returns a list of all transactions belonging to the account.

\#\#\# Pagination

The Transactions endpoint returns all transactions for the given account. Usually this does not represent a large amount of data transfer, but if your application has specific requirements of minimizing the amount of data going over the wire the transactions list endpoint supports pagination controls.

Pagination controls are given as query params on the request URL.

\-   \`count\` \_(integer)\_ \- The maximum number of transactions to return in the API response.

\-   \`from\_id\` \_(string)\_ \- Paginate backward from this transaction. Returns transactions older than the one with this ID. For recent activity, use date ranges or webhooks.

\-   \`start\_date\` \_(string)\_ \- Filter transactions to include only those on or after this date (inclusive). Must be in ISO 8601 format, for example 2025-01-01.

\-   \`end\_date\` \_(string)\_ \- Filter transactions to include only those on or before this date (inclusive). Must be in ISO 8601 format, for example 2025-01-31.

\`\`\`bash  
curl https://api.teller.io/accounts/acc\_oiin624kqjrg2mp2ea000/transactions \\  
  \-u test\_token\_ky6igyqi3qxa4:  
\`\`\`

\`\`\`json  
\[  
  {  
    "details" : {  
      "processing\_status" : "complete",  
      "category" : "general",  
      "counterparty" : {  
          "name" : "YOURSELF",  
          "type" : "person"  
      }  
    },  
    "running\_balance" : null,  
    "description" : "Transfer to Checking",  
    "id" : "txn\_oiluj93igokseo0i3a000",  
    "date" : "2023-07-15",  
    "account\_id" : "acc\_oiin624kqjrg2mp2ea000",  
    "links" : {  
      "account" : "https://api.teller.io/accounts/acc\_oiin624kqjrg2mp2ea000",  
      "self" : "https://api.teller.io/accounts/acc\_oiin624kqjrg2mp2ea000/transactions/txn\_oiluj93igokseo0i3a000"  
    },  
    "amount" : "86.46",  
    "type" : "transfer",  
    "status" : "pending"  
  },  
  ...  
\]  
\`\`\`

\*\*\*

\#\# Get Transaction

Returns an individual transaction.

\`\`\`bash  
curl https://api.teller.io/accounts/acc\_oiin624kqjrg2mp2ea000/transactions/txn\_oiluj93igokseo0i3a005 \\  
  \-u test\_token\_ky6igyqi3qxa4:  
\`\`\`

\`\`\`json  
{  
  "running\_balance" : null,  
  "details" : {  
     "category" : "service",  
     "counterparty" : {  
        "type" : "organization",  
        "name" : "CARDTRONICS"  
     },  
     "processing\_status" : "complete"  
  },  
  "description" : "ATM Withdrawal",  
  "account\_id" : "acc\_oiin624kqjrg2mp2ea000",  
  "date" : "2023-07-13",  
  "id" : "txn\_oiluj93igokseo0i3a005",  
  "links" : {  
     "account" : "https://api.teller.io/accounts/acc\_oiin624kqjrg2mp2ea000",  
     "self" : "https://api.teller.io/accounts/acc\_oiin624kqjrg2mp2ea000/transactions/txn\_oiluj93igokseo0i3a005"  
  },  
  "amount" : "42.47",  
  "type" : "atm",  
  "status" : "posted"  
},  
\`\`\`

\*\*\*

\#\# Syncing Transactions

Use these patterns to fetch only new transactions without re-downloading your full history.

\#\#\# Using date ranges

Use \`start\_date\` and \`end\_date\` to bound your sync window; both dates are inclusive. Expand the window 7-10 days beyond your last sync to capture transactions that shift dates when moving from \`pending\` to \`posted\`.

When a pending transaction posts, its date often changes to the posting date. If you only query from your last sync date forward, you may miss these transactions.

\`\`\`bash  
curl \-G "https://api.teller.io/accounts/acc\_oiin624kqjrg2mp2ea000/transactions" \\  
  \-d "start\_date=2025-01-01" \\  
  \-d "end\_date=2025-01-31" \\  
  \-u test\_token\_ky6igyqi3qxa4:  
\`\`\`

Your expanded window will return transactions you've already stored. Reconcile by matching on transaction ID: insert new records and update existing ones. If the date range returns more than \`count\` transactions, use \`from\_id\` to paginate through the rest of the window.

\> \*\*Note\*\*  
\>  
\> Teller maintains stable transaction IDs. Occasionally, when a pending transaction changes significantly upon posting and cannot be matched to the original, it's created as a new record with a new ID. Account for this in your reconciliation.

\#\#\# Using webhooks

Subscribe to \[\`transactions.processed\`\](/docs/api/webhooks) to receive notifications when new transactions are available. Teller refreshes your enrollments at least once per day. When new transactions are found, this webhook fires, and you call the transactions API to retrieve them.  
\# Payments

\> \*\*Note\*\*  
\>  
\> This is a beta API and as such the interface is subject to change

The payments resource allows you to send payments to yourself or a 3rd party on behalf of the end-user from their account. Currently the only supported payment scheme is Zelle, but others will be added in the future.

\#\# Zelle

Zelle payments can be initiated from checking accounts. The funds are debited immediately from the payer account and are usually received by the beneficiary instantly. In cases where the receiving financial institution is not a member of the Zelle network, the funds will settle via ACH with the beneficiary receiving the funds around 3 days after.

\*\*\*

\#\# Create a Payee

Creates a beneficiary for sending payments from the given account.

The financial institution may require the account owner to perform MFA when creating a payee. If MFA is required the response body from Teller will contain the property \`connect\_token\`. The token is then used to initialize Teller Connect (see \`connectToken\` in the \[Teller Connect Guide\](/docs/guides/connect)), which will prompt the user with the steps required to save the payee. Your implementation must handle this case.

\#\#\# Request Properties

\-   \`scheme\` \_(string)\_ \- \`zelle\` for Zelle payments.

\-   \`address\` \_(string)\_ \- The email address or cellphone number of the payment beneficiary.

\-   \`name\` \_(string)\_ \- The payment beneficiary's name.

\-   \`type\` \_(string)\_ \- Whether the payment beneficiary is a \`person\` or \`business\`.

\`\`\`bash  
curl \-X POST https://api.teller.io/accounts/acc\_oiin624kqjrg2mp2ea000/payees \\  
  \-u test\_token\_ky6igyqi3qxa4: \\  
  \-H 'Content-Type: application/json' \\  
  \-d '{  
    "scheme": "zelle",  
    "address": "jackson.lewis@teller.io",  
    "name": "Jackson Lewis",  
    "type": "person"  
  }'  
\`\`\`

\`\`\`json  
// The financial institution requires the end-user  
// to perform MFA to complete the payment  
{  
  "connect\_token": "xxxxxxxxxxxxxx"  
}  
\`\`\`

\`\`\`json  
{  
  "scheme": "zelle",  
  "address": "jackson.lewis@teller.io",  
  "name": "Jackson Lewis",  
  "type": "person",  
  "account\_id": "acc\_oiin624kqjrg2mp2ea000",  
  "links": {  
    "account": "https://api.teller.io/accounts/acc\_oiin624kqjrg2mp2ea000"  
  }  
}  
\`\`\`

\*\*\*

\#\# Discover Supported Payment Schemes

First, check the links collection in the \[account entity\](/docs/api/account/details\#get-account-details). If the \`payments\` element is not present, the account does not support payment origination. If the \`payments\` element is present, send an \`OPTIONS\` request to the payments resource to see which payment schemes are supported.

Currently, only Zelle is supported. Additional payment schemes will be added in the future.

\`\`\`bash  
curl \-X OPTIONS https://api.teller.io/accounts/acc\_oiin624kqjrg2mp2ea000/payments  
  \-u test\_token\_ky6igyqi3qxa4:  
\`\`\`

\`\`\`json  
{  
  "schemes": \[  
    {  
      "name": "zelle",  
    }  
  \]  
}  
\`\`\`

\*\*\*

\#\# Initiate a Payment

Initiates a payment to the beneficiary from the given account.

The financial institution may require the account owner to perform MFA before executing the payment request. If MFA is required the response body from Teller will contain the property \`connect\_token\`. The token is then used to initialize Teller Connect (see \`connectToken\` in the \[Teller Connect Guide\](/docs/guides/connect)), which will prompt the user with the steps required to execute the payment. Your implementation must handle this case.

This endpoint supports idempotent requests. Use the \`Idempotency-Key\` request header with a unique value per payment request. We store the key and keep the behavior associated to it for 72 hours.

\#\#\# Request Properties

\-   \`amount\` \_(string)\_ \- The payment amount in dollars and cents (optional) as a string, e.g. "13.37", "10.00", "5".

\-   \`memo\` \_(string)\_ \- A short description of the nature of the payment.

\-   \`payee\` \_(object)\_ \- An object with the attributes of the payee. To make a payment to an existing payee, it's sufficient to specify the payee's \`scheme\` and \`address\` only. To make a payment to a new payee, specify all payee's attributes.

\`\`\`bash  
curl \-X POST https://api.teller.io/accounts/acc\_oiin624kqjrg2mp2ea000/payments \\  
  \-u test\_token\_ky6igyqi3qxa4: \\  
  \-H 'Content-Type: application/json' \\  
  \-d '{  
    "amount": "10.48",  
    "memo": "Drinks",  
    "payee": {  
      "scheme": "zelle",  
      "address": "jackson.lewis@teller.io"  
    }  
  }'  
\`\`\`

\`\`\`bash  
curl \-X POST https://api.teller.io/accounts/acc\_oiin624kqjrg2mp2ea000/payments \\  
  \-u test\_token\_ky6igyqi3qxa4: \\  
  \-H 'Content-Type: application/json' \\  
  \-d '{  
    "amount": "10.48",  
    "memo": "Drinks",  
    "payee": {  
      "scheme": "zelle",  
      "address": "jackson.lewis@teller.io",  
      "name": "Jackson Lewis",  
      "type": "person"  
    }  
  }'  
\`\`\`

\`\`\`json  
// The financial institution requires the end-user  
// to perform MFA to complete the payment  
{  
  "connect\_token": "xxxxxxxxxxxxxx"  
}  
\`\`\`

\`\`\`json  
{  
  "id": "zpay\_o2iauakr4qme4v7uku000",  
  "amount": "10.48",  
  "memo": "Drinks",  
  "reference": "GQ3C2MRQGIZC2MBXFUZDMLJVHEZDILKENFXG4ZLS",  
  "date": "2023-09-04",  
  "payee": {  
    "scheme": "zelle",  
    "type": "person",  
    "name": "Jackson Lewis",  
    "address": "jackson.lewis@teller.io",  
  },  
  "links": {  
    "self": "https://api.teller.io/accounts/acc\_oiin624kqjrg2mp2ea000/payments/zpay\_o2iauakr4qme4v7uku000",  
    "account": "https://api.teller.io/accounts/acc\_oiin624kqjrg2mp2ea000"  
  }  
}  
\`\`\`

\*\*\*

\#\# List Payments

Returns a list of all payments that have been initiated via Teller API.

\`\`\`bash  
curl https://api.teller.io/accounts/acc\_oiin624kqjrg2mp2ea000/payments \\  
  \-u test\_token\_ky6igyqi3qxa4:  
\`\`\`

\`\`\`json  
\[  
  {  
    "id": "zpay\_o2iauakr4qme4v7uku000",  
    "amount": "10.48",  
    "memo": "Drinks",  
    "reference": "GQ3C2MRQGIZC2MBXFUZDMLJVHEZDILKENFXG4ZLS",  
    "date": "2023-09-04",  
    "payee": {  
      "scheme": "zelle",  
      "type": "person",  
      "name": "Jackson Lewis",  
      "address": "jackson.lewis@teller.io",  
    },  
    "links": {  
      "self": "https://api.teller.io/accounts/acc\_oiin624kqjrg2mp2ea000/payments/zpay\_o2iauakr4qme4v7uku000",  
      "account": "https://api.teller.io/accounts/acc\_oiin624kqjrg2mp2ea000"  
    }  
  }  
,  
  ...  
\]  
\`\`\`

\*\*\*

\#\# Get Payment

Retrieve a specific payment by its id.

\`\`\`bash  
curl https://api.teller.io/accounts/acc\_oiin624kqjrg2mp2ea000/payments/zpay\_o2iauakr4qme4v7uku000 \\  
  \-u test\_token\_ky6igyqi3qxa4:  
\`\`\`

\`\`\`json  
{  
  "id": "zpay\_o2iauakr4qme4v7uku000",  
  "amount": "10.48",  
  "memo": "Drinks",  
  "reference": "GQ3C2MRQGIZC2MBXFUZDMLJVHEZDILKENFXG4ZLS",  
  "date": "2023-09-04",  
  "payee": {  
    "scheme": "zelle",  
    "type": "person",  
    "name": "Jackson Lewis",  
    "address": "jackson.lewis@teller.io",  
  },  
  "links": {  
    "self": "https://api.teller.io/accounts/acc\_oiin624kqjrg2mp2ea000/payments/zpay\_o2iauakr4qme4v7uku000",  
    "account": "https://api.teller.io/accounts/acc\_oiin624kqjrg2mp2ea000"  
  }  
}  
\`\`\`  
