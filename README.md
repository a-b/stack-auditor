# Stack Auditor

![Stack Auditor Logo](logo.png "Stack Auditor Logo")

## Installation

* Download the latest stack-auditor from the [release section](https://github.com/cloudfoundry/stack-auditor/releases) of this repository for your operating system. 
* Install the plugin with `cf install-plugin <path_to_binary>`.

### Alternative: Compile from source

Prerequisite: Have a working golang environment with correctly set
`GOPATH`.

```sh
go get github.com/cloudfoundry/stack-auditor
cd $GOPATH/src/github.com/cloudfoundry/stack-auditor
./scripts/build.sh

```

## Usage

Install the plugin with `cf install-plugin <path_to_binary>` or use the shell scripts `./scripts/install.sh` or `./scripts/reinstall.sh`.

* Audit cf applications using `cf audit-stack [--csv | --json]`. These optional flags return csv or json format instead of plain text.
* Change stack association using `cf change-stack <app> <stack>`. This will attempt to perform a zero downtime restart. Make sure to target the space that contains the app you want to re-associate. 
* Delete a stack using `cf delete-stack <stack> [--force | -f]`

## Development

## Run the Tests

Target a cloudfoundry with the following prerequisites:
  - has cflinuxfs3 and cflinuxfs4 stacks and buildpacks
    - If using cf-deployment, this can be enabled with the ops file `operations/experimental/add-cflinuxfs4.yml`
  - you are targeting an org and a space

Then run:

`./scripts/all-tests.sh`

### GitHub Actions

#### Integration Tests
The integration tests require a Cloud Foundry environment with both cflinuxfs3 and cflinuxfs4 stacks and their corresponding buildpacks available.
To enable the workflow, you need to configure the following secrets in your GitHub repository:

* `CF_API` - The Cloud Foundry API endpoint
* `CF_ORG` - The Cloud Foundry organization name
* `CF_SPACE` - The Cloud Foundry space name
* `CF_USERNAME` - The Cloud Foundry username
* `CF_PASSWORD` - The Cloud Foundry password

These credentials should have sufficient permissions to:
- Access the target org and space
- Create and manage applications
- Create and manage stacks
- Create and manage buildpacks