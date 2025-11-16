# GitHub Actions Workflow Setup Guide

This document explains how to use the GitHub Actions workflow for Cribl Leader deployment.

## Overview

The GitHub Actions workflow (`.github/workflows/cribl-deployment.yml`) provides the same functionality as the Jenkins pipeline but runs natively on GitHub.

## Differences from Jenkins Pipeline

| Feature | Jenkins | GitHub Actions |
|---------|---------|----------------|
| Configuration | Jenkinsfile | `.github/workflows/cribl-deployment.yml` |
| Credentials | Jenkins Credentials Manager | GitHub Secrets |
| Email Notifications | emailext plugin | GitHub Actions Summary + Optional email action |
| YAML Parsing | readYaml plugin | yq command-line tool |
| Trigger | Manual or webhook | Push to main branch or manual dispatch |

## Setup Instructions

### 1. Configure GitHub Secrets

You need to add AWS credentials as GitHub repository secrets:

1. Go to your repository on GitHub
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add the following secrets:

   - **AWS_ACCESS_KEY_ID**: Your AWS access key ID
   - **AWS_SECRET_ACCESS_KEY**: Your AWS secret access key

**Security Note:** Never hardcode credentials in the workflow file or commit them to the repository.

### 2. Verify grd.yaml Configuration

The workflow reads configuration from `grd.yaml`. Ensure it contains:

```yaml
stack_name: cribl-leader-stack
region: ap-south-1
cloudformation_template: cloudformation/cribl-leader.yaml
parameters:
  InstanceType: t3.large
  KeyName: cribl-key
  AmiId: ami-0abcdef123123
  VpcId: vpc-98765abcd
  SubnetId: subnet-54321efg
  SecurityGroup: sg-00112233
  LeaderNodeCount: 2
  VolumeSize: 50
userdata_script: scripts/leader-userdata.sh
bootstrap_script: scripts/leader-bootstrap.sh
notification_email: "your-email@company.com"
```

### 3. Trigger the Workflow

The workflow can be triggered in two ways:

**Automatic Trigger:**
- Push changes to the `main` branch
- The workflow will automatically start

**Manual Trigger:**
1. Go to your repository on GitHub
2. Click **Actions** tab
3. Select **Cribl Leader Deployment** workflow
4. Click **Run workflow** button
5. Select the branch and click **Run workflow**

## Workflow Stages

The GitHub Actions workflow performs these stages:

1. **Checkout Repository** - Clones the repository
2. **Configure AWS Credentials** - Sets up AWS authentication
3. **Install yq** - Installs YAML processing tool
4. **Load Configuration** - Reads grd.yaml parameters
5. **Build Parameters JSON** - Converts YAML to CloudFormation format
6. **Validate Template** - Validates CloudFormation template syntax
7. **Deploy Infrastructure** - Creates/updates AWS resources
8. **Run Userdata Script** - Executes initial setup
9. **Run Bootstrap Script** - Starts Cribl service
10. **Generate Summary** - Creates deployment summary

## Monitoring Deployment

### View Workflow Execution

1. Go to the **Actions** tab in your repository
2. Click on the workflow run
3. View real-time logs for each step

### Deployment Summary

After the workflow completes, a summary is displayed showing:
- Stack name
- AWS region
- Deployment status (SUCCESS/FAILED)
- Links to logs (if failed)

## Email Notifications (Optional)

To add email notifications similar to Jenkins:

1. Add an email notification action to the workflow
2. Use a service like SendGrid or AWS SES
3. Add the necessary secrets for the email service

Example using a third-party action:

```yaml
- name: Send Email Notification
  if: always()
  uses: dawidd6/action-send-mail@v3
  with:
    server_address: smtp.gmail.com
    server_port: 465
    username: ${{ secrets.EMAIL_USERNAME }}
    password: ${{ secrets.EMAIL_PASSWORD }}
    subject: Cribl Leader Deployment ${{ job.status }}
    body: Deployment finished with status ${{ job.status }}
    to: ${{ env.EMAIL_TO }}
    from: GitHub Actions
```

## Troubleshooting

### Workflow Fails at AWS Authentication

**Issue:** AWS credentials are not configured properly

**Solution:**
- Verify AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY secrets are set correctly
- Ensure the IAM user has CloudFormation permissions
- Check the AWS region is correct in grd.yaml

### Template Validation Fails

**Issue:** CloudFormation template has syntax errors

**Solution:**
- Review the template file: `cloudformation/cribl-leader.yaml`
- Test locally using: `aws cloudformation validate-template --template-body file://cloudformation/cribl-leader.yaml`

### Deployment Fails

**Issue:** CloudFormation deployment encounters errors

**Solution:**
- Check AWS CloudFormation console for stack events
- Review error messages in the GitHub Actions logs
- Verify all parameters in grd.yaml are correct (AMI ID, VPC, Subnet, Security Group)

### Script Execution Fails

**Issue:** Userdata or bootstrap scripts fail

**Solution:**
- Verify scripts have correct bash syntax
- Check if required dependencies are available
- Review script logs in the workflow output

## Migrating from Jenkins

If you're migrating from the Jenkins pipeline:

1. **Keep the Jenkinsfile** (for backward compatibility if needed)
2. **Set up GitHub Secrets** (equivalent to Jenkins credentials)
3. **Test the workflow** on a development branch first
4. **Update team documentation** to reference the new workflow
5. **Consider disabling** the Jenkins job once GitHub Actions is verified

## Comparison: Jenkins vs GitHub Actions

### Advantages of GitHub Actions:

- ✅ Native integration with GitHub repository
- ✅ No separate Jenkins server to maintain
- ✅ Free for public repositories, included minutes for private repos
- ✅ Built-in secrets management
- ✅ Easy workflow syntax (YAML-based)
- ✅ Rich marketplace of pre-built actions

### Jenkins Advantages:

- ✅ More plugins available
- ✅ Self-hosted option for complete control
- ✅ Advanced pipeline features (shared libraries)
- ✅ Better for complex enterprise workflows

## Security Best Practices

1. **Never commit credentials** to the repository
2. **Use GitHub Secrets** for all sensitive data
3. **Rotate AWS credentials** regularly
4. **Use IAM roles** with least privilege principle
5. **Review workflow logs** for sensitive data before sharing
6. **Enable branch protection** on main branch
7. **Require PR reviews** before merging workflow changes

## Cost Considerations

- **GitHub Actions Minutes:** Free tier includes 2,000 minutes/month for private repos
- **AWS CloudFormation:** No additional charge (pay for resources created)
- **EC2 Instances:** t3.large instances with 50GB storage (~$70-100/month per instance)

## Support

For issues or questions:
- Review workflow logs in GitHub Actions
- Check AWS CloudFormation events in AWS Console
- Contact: ashok.team@company.com

## Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [AWS CloudFormation Documentation](https://docs.aws.amazon.com/cloudformation/)
- [Cribl Documentation](https://docs.cribl.io/)
- [yq Documentation](https://mikefarah.gitbook.io/yq/)
