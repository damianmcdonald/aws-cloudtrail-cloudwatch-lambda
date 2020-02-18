# AWS CloudTrail CloudWatch Lambda

The `aws-cloudtrail-cloudwatch-lambda` project demonstrates the creation of a CloudTrail trail which pushes events to CloudWatch. CloudWatch is configured with an Event Rule which responds to specific CloudTrail events by invoking a Lambda function.

# Architecture overview

The project architecture is depicted in the diagram below:

![Architecture diagram](assets/architecture.png)

# Prerequisites

* An AWS account with appropriate permissions to create the required resources
* [AWS CLI installed and configured](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv1.html)
* Bash environment in which to execute the scripts

# Deploy the project

## Grab the project 

The first step is to git clone the project.

```bash
git clone --verbose --progress https://github.com/damianmcdonald/aws-cloudtrail-cloudwatch-lambda aws-cloudtrail-cloudwatch-lambda
```

## Configure global variables

The second step is to modify any of the global variables to suit your needs.

The global variables are defined in the [aws-deploy.sh](aws-deploy.sh) script.

You will need to update the `AWS_PROFILE` variable to reflect the profile that you have configured in the AWS CLI.

For the remaining global variables, if you just want to have a sandbox environment to experiment with the project then the defaults below are probably fine.

```bash
# Global variable declarations
PROJECT_DIR=$PWD
AWS_PROFILE=<!-- ADD_YOUR_AWS_CLI_PROFILE_HERE -->
AWS_REGION=$(aws configure get region --output text --profile ${AWS_PROFILE})
STACK_NAME=clloudtrail-rule
CFN_STACK_TEMPLATE=stack-template.yml
UNDEPLOY_FILE=aws-undeploy.sh
```

## Create the resources and deploy the project

Create the resources and deploy the project by executing the [aws-deploy.sh](aws-deploy.sh) script.

```bash
./aws-deploy.sh
```

As part of the execution of the [aws-deploy.sh](aws-deploy.sh) script, four additional files are dynamically created.

Location | Purpose
------------ | -------------
aws-undeploy.sh | Script that can be used to destroy and clean-up all of the resources created by the `aws-cloudtrail-cloudwatch-lambda` project

# Test the project

To test the project, follow the high-level steps below.

1. Create an EC2 instance
2. Allow the instance to enter the *Running* state
3. Terminate the EC2 instance
4. Navigate to CloudWatch and go to the Log Groups
5. Verify that the Lambda function has writted log information based on the CloudWatch Event Rule