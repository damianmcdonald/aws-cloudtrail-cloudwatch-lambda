#!/bin/bash

##############################################################
#                                                            #
# This sample demonstrates the following concepts:           #
#                                                            #
# * Creates a CloudTrail Trail                               #
# * Creates a CloudWatch Log Group                           #
# * Creates a CloudWatch Event Rule                          #
# * Creates a Lambda Fuunction to respond to the             #
#   CloudWatch Event Rule                                    #
# * Creates an S3 Bucket as the CloudTrail log               #
#   delivery location                                        #
# * IAM role creation                                        #
# * Cleans up all the resources created                      #
#                                                            #
##############################################################

# Colors
BLACK='\033[0;30m'
RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
LIGHT_GRAY='\033[0;37m'
DARK_GRAY='\033[1;30m'
LIGHT_RED='\033[1;31m'
LIGHT_GREEN='\033[1;32m'
YELLOW='\033[1;33m'
LIGHT_BLUE='\033[1;34m'
LIGHT_PURPLE='\033[1;35m'
LIGHT_CYAN='\033[1;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Global variable declarations
PROJECT_DIR=$PWD
AWS_PROFILE=dcorp
AWS_REGION=$(aws configure get region --output text --profile ${AWS_PROFILE})
STACK_NAME=clloudtrail-rule
CFN_STACK_TEMPLATE=stack-template.yml
UNDEPLOY_FILE=aws-undeploy.sh

###########################################################
#                                                         #
#  Validate the CloudFormation templates                  #
#                                                         #
###########################################################

echo -e "[${LIGHT_BLUE}INFO${NC}] Validating CloudFormation template ${YELLOW}$CFN_STACK_TEMPLATE${NC}.";
cat ${CFN_STACK_TEMPLATE} | xargs -0 aws cloudformation validate-template --template-body
# assign the exit code to a variable
CFN_STACK_TEMPLATE_VALIDAION_CODE="$?"

# check the exit code, 255 means the CloudFormation template was not valid
if [ $CFN_STACK_TEMPLATE_VALIDAION_CODE != "0" ]; then
    echo -e "[${RED}FATAL${NC}] CloudFormation template ${YELLOW}$CFN_STACK_TEMPLATE${NC} failed validation with non zero exit code ${YELLOW}$CFN_STACK_TEMPLATE_VALIDAION_CODE${NC}. Exiting.";
    exit 999;
fi

echo -e "[${GREEN}SUCCESS${NC}] CloudFormation template ${YELLOW}$CFN_STACK_TEMPLATE${NC} is valid.";

###########################################################
#                                                         #
#  Execute the CloudFormation templates                   #
#                                                         #
###########################################################

echo -e "[${LIGHT_BLUE}INFO${NC}] Exectuing the CloudFormation template ${YELLOW}$STACK_NAME${NC}.";
aws cloudformation create-stack \
	--template-body file://${CFN_STACK_TEMPLATE} \
	--stack-name ${STACK_NAME} \
	--capabilities CAPABILITY_IAM \
	--profile ${AWS_PROFILE}

echo -e "[${LIGHT_BLUE}INFO${NC}] Waiting for the creation of SAM stack ${YELLOW}$STACK_NAME${NC} ....";
aws cloudformation wait stack-create-complete --stack-name $STACK_NAME --profile ${AWS_PROFILE}

###########################################################
#                                                         #
# Undeployment file creation                              #
#                                                         #
###########################################################

# grab the S3 Bucket Name from the stack output
S3_DELIVERY_BUCKET_DOMAIN=$(aws cloudformation describe-stacks --stack-name ${STACK_NAME} --profile ${AWS_PROFILE} --query "Stacks[].Outputs[?OutputKey == 'S3BucketName'][OutputValue]" --output text)
S3_DELIVERY_BUCKET_NAME=$(echo "${S3_DELIVERY_BUCKET_DOMAIN}" | sed -e "s/.s3.amazonaws.com$//")

# delete any previous instance of undeploy.sh
if [ -f "$UNDEPLOY_FILE" ]; then
    rm $UNDEPLOY_FILE
fi

cat > $UNDEPLOY_FILE <<EOF
#!/bin/bash

# Colors
BLACK='\033[0;30m'
RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
LIGHT_GRAY='\033[0;37m'
DARK_GRAY='\033[1;30m'
LIGHT_RED='\033[1;31m'
LIGHT_GREEN='\033[1;32m'
YELLOW='\033[1;33m'
LIGHT_BLUE='\033[1;34m'
LIGHT_PURPLE='\033[1;35m'
LIGHT_CYAN='\033[1;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

echo -e "[${LIGHT_BLUE}INFO${NC}] Delete S3 Bucket ${YELLOW}${S3_DELIVERY_BUCKET_NAME}${NC}.";
aws s3 rm s3://${S3_DELIVERY_BUCKET_NAME}/ --recursive --profile ${AWS_PROFILE}
aws s3 rb s3://${S3_DELIVERY_BUCKET_NAME} --profile ${AWS_PROFILE}

echo -e "[${LIGHT_BLUE}INFO${NC}] Terminating cloudformation stack ${YELLOW}${STACK_NAME}${NC} ....";
aws cloudformation delete-stack --stack-name ${STACK_NAME} --profile ${AWS_PROFILE}

echo -e "[${LIGHT_BLUE}INFO${NC}] Waiting for the deletion of cloudformation stack ${YELLOW}${STACK_NAME}${NC} ....";
aws cloudformation wait stack-delete-complete --stack-name ${STACK_NAME} --profile ${AWS_PROFILE}

aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --profile ${AWS_PROFILE}
EOF

chmod +x $UNDEPLOY_FILE