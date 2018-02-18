# JDR-tools gateway

## Install

### Pre-requisites

You MUST ensure that ALL these software are installed in the given versions before installing and launching the application.

- RVM >= 1.29.1
- Ruby >= 2.3.1, installed via RVM
- Bundler gem >= 1.16.1
- MongoDB >= 3.2.13

### Needed environment variable


#### Gateway token

__Name :__ GATEWAY_TOKEN  
__Type :__ String  
__Meaning :__ the uniq identification token for this gateway. This token SHOULD not be identical to another gateway token, correct behaviour is NOT guaranteed if two gateways use the same token.

#### Gateway URL

__Name :__ GATEWAY_URL  
__TYPE :__ String  
__Meaning :__ The current URL to make requests on this gateway. If two instances of the gateway have the same GATEWAY_TOKEN, one will not be taken in account, thus will be inactive. This variable MUST have an URL format. This variable MUST end with a final slash ('/') symbol.

#### MongoDB URL

__Name :__ MONGODB_URL  
__meaning :__ This is the URL to contact the database linked to this instance of the gateway.  
__TYPE :__ String  
__Constraints :__ This variable MUST be a valid Mongo DB URL, otherwise the application will crash on startup.  
__Advices :__ None

## Run the server

We will consider that you have installed all required applications described in the above section.

```shell
bundle install
rackup -o 0.0.0.0 -p 3000
```

The above commands launch the server to listen on the 3000 port.

## Run the tests suite

To launch the unit test suite, juste execute the `rspec` command, the results will then be displayed.

### Number of tests

__Date :__ 18/02/2018 17:37  
__Count :__ 96
