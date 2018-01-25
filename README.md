# JDR-tools gateway

## Installation

### Pre-requisites

#### Softwares

You MUST ensure that ALL these software are installed in the given versions before installing and launching the application.

- RVM >= 1.29.1
- Ruby >= 2.3.1, installed via RVM
- Bundler gem >= 1.16.1
- MongoDB >= 3.2.13

#### Environment variable

You MUST ensure that ALL these environment variables are defined before passing to the next section and launching tests.

##### Gateway token

__Name :__ GATEWAY_TOKEN

__Meaning :__ the uniq identification token for this gateway. This token SHOULD not be identical to another gateway token, correct behaviour is NOT guaranteed if two gateways use the same token.

__Type :__ String

__Constraints :__ None

__Advices :__ This token SHOULD be at least 32 characters long to ensure security considerations.

##### Gateway URL

__Name :__ GATEWAY_URL

__Meaning :__ The current URL to make requests on this gateway. If two instances of the gateway have the same GATEWAY_TOKEN, one will not be taken in account, thus will be inactive.

__TYPE :__ String

__Constraints :__ This variable MUST have an URL format. This variable MUST end with a final slash ('/') symbol.

__Advices :__ None

##### MongoDB URL

__Name :__ MONGODB_URL

__meaning :__ This is the URL to contact the database linked to this instance of the gateway.

__TYPE :__ String

__Constraints :__ This variable MUST be a valid Mongo DB URL, otherwise the application will crash on startup.

__Advices :__ None

### Procedures

#### Cloning the repository

Note that you MUST be a contributor to push code into our architecture. Contact us if you're not listed as contributor, but would want to bring your own brick to the system.

##### HTTP cloning

If your SSH key is not registered, you MUST clone in HTTP with the command `git clone https://github.com/jdr-tools/gateway.git`

##### SSH cloning

If your SSH key is registered, you can use the following command `git clone git@github.com:jdr-tools/gateway.git`

#### Launching the web server

We will consider that you have installed all required applications described in the above section.

```shell
bundle install
rackup -o 0.0.0.0 -p 3000
```

The above commands launch the server to listen on the 3000 port.

#### Launching the unit tests suite

To launch the unit test suite, juste execute the `rspec` command, the results will then be displayed.

## Behaviour

The gateway is a forward tunnel to all the services, and provide several services before forwarding them.

### Activity checks

The gateway can detect if a service is currently disabled (therefore deemed as "inactive"), if no instances are available for a given service, or if a route is disabled.

#### Inactive service error

__Precondition :__ An entire service has been marked as "inactive" in the database.

__Scenario :__ A user tries to make a request on one of the routes of this service.

__Response status :__ 400 (Bad Request)

__Response format :__ JSON string.

__Response body :__ `{'message': 'inactive_service'}`

__Solution :__ Wait for the service to be available, or contact us directly to have more informations on the problem.

#### Inactive service error

__Precondition :__ The route you're trying to reach has been marked as "inactive" in the database.

__Scenario :__ A user tries to make a request on a route marked as inactive.

__Response status :__ 400 (Bad Request)

__Response format :__ JSON string.

__Response body :__ `{'message': 'inactive_route'}`

__Solution :__ Wait for the route to be available, or contact us directly to have more informations on the problem.

#### No available instances errors

__Precondition :__ All the instances of a service have been marked as inactive in the database.

__Scenario :__ A user tries to make a request on a service that has no activated instances.

__Response status :__ 400 (Bad Request)

__Response format :__ JSON string.

__Response body :__ `{'message': 'no_instance_available'}`

__Solution :__ This might be a big problem on our infrastructure, wait for our communication on it or contact us directly.

### Application identity check

The gateway checks if the user making the request is one of the applications registered in our database. If not, it won't complete the request, and return an error.

#### No application token given.

__Precondition :__ None

__Scenario :__ A user makes a request on a gateway without providing a `app_key` field in the querystring.

__Response status :__ 400 (Bad Request)

__Response format :__ JSON string.

__Response body :__ `{'message': 'bad_request`}`

__Solution :__ Provide your application key to make requests on the gateway.

#### Unexisting application token given.

__Precondition :__ None

__Scenario :__ A user makes a request on a gateway providing a `app_key` field that can't be linked to any application.

__Response status :__ 404 (Not Found)

__Response format :__ JSON string.

__Response body :__ `{'message': 'application_not_found`}`

__Solution :__ Check the spelling of your application key and the existence of your application. Contact us for more informations.

### Nominal behaviour

If you don't have any of the listed errors, your request will be forwarded to the dedicated service, and the status and body will be the ones it returns.