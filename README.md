# Rusty Lambda Fxn

Build and deploy containerized Rust lambda functions + logging/tracing integration

Jump To:
* [PreReqs](#prereqs)
* [Configure Env Vars](#configure-env-vars)
* [Configure Roles & Permissions](#configure-roles--permissions)
* [Configure Local AWS Credentials](#configure-local-aws-credentials)
* [Deploy Containerized Lambda Function](#deploy-containerized-lambda-function)

### PreReqs

⚠️ Ensure all resources are provisioned in the same AWS region ⚠️

**Install AWS CLI v2**

Refer to the latest install [docs](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)

```
# Check if installed
$ aws --version

# Install 
$ curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
$ unzip awscliv2.zip
$ sudo ./aws/install
```

### Configure env vars

Create `.env` file and configure variables

```
AWS_ACCT_ID=<YOUR_AWS_ACCT_ID>
AWS_DEFAULT_REGION=<YOUR_AWS_REGION>
LAMBDA_FXN=<LAMBDA_FUNCTION_NAME>
```

### Configure Policies & Permissions

⚠️ For this blueprint ${LAMBDA_FXN}=rusty-lambda-fxn. Name policies and roles accordingly. ⚠️

**Create policy `rusty-lambda-deploy`**

IAM console > Policies > Create Policy > JSON

NB: Replace {AWS-ACCT-ID} and {LAMBDA_FXN}

```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "iam:CreateRole",
                "iam:AttachRolePolicy",
                "iam:UpdateAssumeRolePolicy",
                "iam:PassRole"
            ],
            "Resource": [
                "arn:aws:iam::{AWS-ACCT-ID}:role/AWSLambdaBasicExecutionRole",
                "arn:aws:iam::{AWS-ACCT-ID}:role/"arn:aws:iam::141774272727:role/{LAMBDA_FXN}-role"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "lambda:CreateFunction",
                "lambda:UpdateFunctionCode",
                "lambda:GetFunction",
                "lambda:InvokeFunction" 
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ecr:GetAuthorizationToken",
                "ecr:SetRepositoryPolicy",
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "ecr:CompleteLayerUpload",
                "ecr:DescribeImages",
                "ecr:DescribeRepositories",
                "ecr:UploadLayerPart",
                "ecr:ListImages",
                "ecr:InitiateLayerUpload",
                "ecr:BatchCheckLayerAvailability",
                "ecr:GetRepositoryPolicy",
                "ecr:PutImage",
                "ecr:CreateRepository"
            ],
            "Resource": "*"
        }
    ]
}
```

**Create policy `${LAMBDA_FXN}-policy`**

IAM console > Policies > Create Policy > JSON

NB: Add other resource permissions for your lambda function as needed

```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:PutLogEvents",
                "logs:CreateLogGroup",
                "logs:CreateLogStream"
            ],
            "Resource": "arn:aws:logs:*:*:*"
        }
    ]
}
```

**Create role `${LAMBDA_FXN}-role`**

IAM console > Roles > Create Role > AWS Service: Lambda > Permissions: `${LAMBDA_FXN}-policy`

**Create user `rusty-lambda-developer`**

IAM console > Users > Create User > Attach Policies Directly: `rusty-lambda-deploy`

### Configure Local AWS Credentials

Create Access Key for `rusty-lambda-developer` > add new `~/.aws/credentials` profile:

```
[rusty-lambda-dev]
aws_access_key_id=<RUSTY_LAMBDA_DEVELOPER_ACCESS_KEY>
aws_secret_access_key=<RUSTY_LAMBDA_DEVELOPER_SECRET_KEY>
```

### Deploy Containerized Lambda Function

**Install cargo-lambda**

```
$ make install-lambda
```

**Build containerized lambda**

```
# NB: Update Dockerfile commands to match your fxn name
$ make build-container
```

**Test container locally**

```
# Install AWS Lambda Runtime Emulator
$ make install-emulator

# Launch container on emulator
$ make local-container

# Modify test payload
$ curl -XPOST "http://localhost:9000/2015-03-31/functions/function/invocations" -d '{ "name": "World"}'
```

**Make ECR Repo if DNE**

```
$ make ecr-login
$ make ecr-repo
```

**Push Container to ECR**

```
$ make ecr-login
$ make deploy-container
```

**Deploy Containerized Lambda**

```
$ make deploy-lambda
```

**Test Remote Invocation**

```
$ make invoke
```

### Updating & Redeploying

If you make function/container edits, you will need to rebuild and update

```
$ make build-container
$ make deploy-container
$ make update-lambda
```

### Deploy .zip Archive

To deploy function as standard cargo-lambda .zip archive

```
$ make deploy-zip
```

### References
* [AWS Building Lambda Functions with Rust](https://docs.aws.amazon.com/lambda/latest/dg/lambda-rust.html)
* [Deploying Lambda Containers](https://docs.aws.amazon.com/lambda/latest/dg/images-create.html)
* [Lambda Runtime Emulator](https://github.com/aws/aws-lambda-runtime-interface-emulator)
* [Cargo Lambda Docs](https://www.cargo-lambda.info/)