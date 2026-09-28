# LocalStack + Terraform

A small macOS learning setup for creating AWS resources locally. Terraform uses the AWS provider; LocalStack emulates AWS APIs in Docker. No AWS account or `LOCALSTACK_AUTH_TOKEN` is needed with the pinned legacy Community image.

## Stack

- Docker Desktop (or another running Docker-compatible engine)
- LocalStack `4.14.0`, exposed at `http://localhost:4566`
- Terraform `1.16+` and HashiCorp AWS provider `~> 5.0`
- AWS CLI v2 (optional; used below to inspect the bucket)

Install tools on macOS with Homebrew:

```sh
brew install --cask docker
brew install hashicorp/tap/terraform
brew install awscli
```

Open Docker Desktop and wait until its engine is running. If Docker or Terraform is already installed, skip that install command.

## Run

From the repository root, start LocalStack and confirm it responds:

```sh
docker compose up -d
curl -fsS http://localhost:4566/_localstack/health
```

Initialize and apply Terraform:

```sh
cd terraform-localstack
terraform init
terraform plan
terraform apply
```

Type `yes` when Terraform asks for confirmation. This creates `localstack-demo-bucket` in LocalStack, not AWS.

Optionally list the bucket with AWS CLI v2:

```sh
AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test \
  aws --region us-east-1 --endpoint-url=http://localhost:4566 s3 ls
```

## Stop and clean up

Remove the Terraform-managed bucket, then stop LocalStack:

```sh
cd terraform-localstack
terraform destroy
cd ..
docker compose down
```

`localstack-data/` is ignored by Git and holds local runtime data. Terraform state is also local and ignored; do not commit it or real credentials. Keep `.terraform.lock.hcl` in version control.

## Troubleshooting

- **Docker connection error:** Start Docker Desktop, then retry `docker compose up -d`.
- **Terraform cannot connect:** Check `docker compose ps` and `docker compose logs localstack`.
- **S3 hostname/DNS error:** The provider uses `s3.localhost.localstack.cloud:4566`. If it does not resolve to your machine, change its S3 endpoint in `main.tf` to `http://localhost:4566` and add `s3_use_path_style = true` inside the AWS provider block; then rerun `terraform plan`.
- **Auth token prompt/error:** Confirm Compose still pins `localstack/localstack:4.14.0`; do not change it to `latest` for this token-free learning setup.