# Day 1 – AWS basics (LocalStack + Terraform)

Working directory for all Terraform commands: `terraform-localstack/01_aws_basic/`

Shared CLI setup (used in every AWS CLI command below):

```bash
export AWS_ACCESS_KEY_ID=x AWS_SECRET_ACCESS_KEY=x AWS_DEFAULT_REGION=us-east-1
alias awsl='aws --endpoint-url http://localhost:4566'
```

Prerequisite: the LocalStack container is running (`docker compose up -d`, port 4566).

## 1. IAM group `WorkshopAdmins`

In `main.tf`:

1. Add `iam = "http://localhost:4566"` to the provider `endpoints` block.
2. Add the resource `aws_iam_group.workshop_admins` (`name = "WorkshopAdmins"`).

```bash
cd terraform-localstack/01_aws_basic
terraform init
terraform apply -auto-approve
```

Verify:

```bash
awsl iam list-groups
```

Expected: `GroupName` = `WorkshopAdmins`, `Arn` = `arn:aws:iam::000000000000:group/WorkshopAdmins`
(`GroupId` and `CreateDate` differ on every run).

CLI alternative (instead of Terraform):

```bash
awsl iam create-group --group-name WorkshopAdmins
```

## 2. Policy `WorkshopS3AthenaGluePolicy`

Policy document: `tmp/WorkshopS3AthenaGluePolicy.json`
It contains the placeholder `<YOUR-BUCKET-NAME>`; Terraform replaces it with `localstack-demo-bucket`.

Terraform (used here): resources `aws_iam_policy.workshop_s3_athena_glue` and
`aws_iam_group_policy_attachment.workshop_admins_s3_athena_glue`, then `terraform apply -auto-approve`.

CLI alternative (instead of Terraform). Replace the placeholder first, otherwise the bucket ARNs are invalid:

```bash
sed 's/<YOUR-BUCKET-NAME>/localstack-demo-bucket/g' tmp/WorkshopS3AthenaGluePolicy.json > /tmp/policy.json

awsl iam create-policy \
  --policy-name WorkshopS3AthenaGluePolicy \
  --policy-document file:///tmp/policy.json

awsl iam attach-group-policy \
  --group-name WorkshopAdmins \
  --policy-arn arn:aws:iam::000000000000:policy/WorkshopS3AthenaGluePolicy
```

Verify:

```bash
awsl iam list-attached-group-policies --group-name WorkshopAdmins
```

## 3. User `Workshop-User` with console access

Terraform (used here): `aws_iam_user.workshop_user`, `aws_iam_user_login_profile.workshop_user`,
`aws_iam_user_group_membership.workshop_user`, then `terraform apply -auto-approve`.
The generated password: `terraform output -raw workshop_user_password`.

CLI alternative (instead of Terraform):

```bash
awsl iam create-user --user-name Workshop-User
awsl iam create-login-profile --user-name Workshop-User --password '<password>' --no-password-reset-required
awsl iam add-user-to-group --user-name Workshop-User --group-name WorkshopAdmins
```

Verify:

```bash
awsl iam get-login-profile --user-name Workshop-User
awsl iam list-groups-for-user --user-name Workshop-User
```

Note: the console sign-in page is not available in free LocalStack; the login profile is only created via the IAM API.

## Cleanup

```bash
cd terraform-localstack/01_aws_basic
terraform destroy -auto-approve
```
