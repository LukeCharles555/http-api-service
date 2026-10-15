# IAM bootstrap — proposed migration

This directory captures the existing GitHub deployment roles, IAM policies and OIDC configuration in Terraform, so future access changes can be tracked and reviewed in Git.

**Status: not applied.** The configuration was generated from an export of the working AWS setup. It has not been imported into Terraform state or validated through a live AWS Terraform plan. Current deployments still use the manually configured IAM resources.

## What is included?

- GitHub OIDC provider and dev/prod deployment roles, including their trust policies.
- 11 customer-managed policies and the existing role/user policy attachments.
- Inline deployment policies for the dev role and local deployer user.
- Import definitions for 34 existing resources.

Policy and trust documents are stored as readable JSON. Terraform natively supports the `.tf.json` configuration files.

The local IAM user itself, its password and MFA, the S3 state bucket, and GitHub repository settings are outside this configuration. Application runtime roles are already managed by the dev/prod Terraform roots.

## Why keep this separate?

Application pipelines should not manage their own deployment permissions. This is a separate Terraform root for an authorised administrator, with its own state key: `bootstrap/terraform.tfstate` in the existing S3 backend.

It is not run by the application workflows. No further setup is needed to continue using the existing dev/prod deployments.

## Complete the migration later

Use a separate authorised administrator profile with access to IAM and the bootstrap state location. From the repository root:

```bash
export AWS_PROFILE=your-admin-profile
terraform -chdir=infra/bootstrap init
terraform -chdir=infra/bootstrap validate
terraform -chdir=infra/bootstrap plan -out=bootstrap.tfplan
```

The initial target is **34 to import, 0 to add, 0 to change, 0 to destroy**. This is based on the exported configuration; inspect the complete plan and resolve any differences before applying.

Once the plan contains only the intended imports:

```bash
terraform -chdir=infra/bootstrap apply bootstrap.tfplan
terraform -chdir=infra/bootstrap plan
```

The final plan should report no changes. Commit the generated `.terraform.lock.hcl`; keep plans, state and `.terraform/` out of Git.

## Limits

This captures existing permissions; it does not tighten them. Individual policy attachments are managed, so additional attachments made outside Terraform are not automatically removed. The OIDC provider may be shared with other projects and should be reviewed before changes.

Do not destroy this root during application cleanup: its resources provide deployment access.
