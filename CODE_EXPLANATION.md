# Cribl Leader Deployment - Complete Code Explanation

## Table of Contents
1. [Project Overview](#project-overview)
2. [Architecture](#architecture)
3. [File Structure](#file-structure)
4. [Detailed Component Breakdown](#detailed-component-breakdown)
5. [Deployment Workflow](#deployment-workflow)
6. [Configuration Guide](#configuration-guide)
7. [Security Considerations](#security-considerations)

---

## Project Overview

This repository contains an automated deployment system for **Cribl Leader Nodes** on AWS infrastructure. Cribl is a data observability and pipeline management platform, and the "Leader Node" acts as a central control plane for managing Cribl Stream worker nodes.

**Purpose:** Automate the provisioning and configuration of Cribl Leader nodes using:
- **Jenkins** for CI/CD orchestration
- **AWS CloudFormation** for infrastructure as code
- **Bash scripts** for application setup and bootstrapping

---

## Architecture

```
┌─────────────────┐
│   Jenkins       │  Orchestrates the deployment
│   Pipeline      │
└────────┬────────┘
         │
         ├──> Reads grd.yaml (configuration)
         │
         ├──> Validates CloudFormation Template
         │
         ├──> Deploys AWS Infrastructure (Auto Scaling Group + Launch Template)
         │
         ├──> Runs Userdata Script (install Cribl)
         │
         ├──> Runs Bootstrap Script (start Cribl)
         │
         └──> Sends Email Notification
```

**AWS Resources Created:**
- **EC2 Launch Template**: Defines instance configuration
- **Auto Scaling Group**: Manages multiple Leader node instances
- **EBS Volumes**: Persistent storage (50GB gp3 by default)

---

## File Structure

```
cribl/
├── README.md                           # Basic project description
├── grd.yaml                            # Central configuration file
├── Jenkinsfile                         # Jenkins pipeline definition
├── cloudformation/
│   └── cribl-leader.yaml              # AWS CloudFormation template
└── scripts/
    ├── leader-userdata.sh             # Installation script
    └── leader-bootstrap.sh            # Service startup script
```

---

## Detailed Component Breakdown

### 1. `README.md`
**Purpose:** Project identifier
**Content:** Simply states "Cribl Leader Deployment Package"
**Note:** Could be enhanced with setup instructions, prerequisites, and usage examples

---

### 2. `grd.yaml` - Configuration File
**Purpose:** Central configuration that drives the entire deployment

```yaml
stack_name: cribl-leader-stack           # CloudFormation stack name
region: ap-south-1                       # AWS Mumbai region
cloudformation_template: cloudformation/cribl-leader.yaml
parameters:                              # CloudFormation parameters
  InstanceType: t3.large                 # EC2 instance size
  KeyName: cribl-key                     # SSH key for access
  AmiId: ami-0abcdef123123               # Amazon Machine Image ID
  VpcId: vpc-98765abcd                   # Virtual Private Cloud ID
  SubnetId: subnet-54321efg              # Subnet for instances
  SecurityGroup: sg-00112233             # Firewall rules
  LeaderNodeCount: 2                     # Number of Leader instances
  VolumeSize: 50                         # Disk size in GB
userdata_script: scripts/leader-userdata.sh
bootstrap_script: scripts/leader-bootstrap.sh
notification_email: "ashok.team@company.com"
```

**Key Decisions:**
- **2 Leader nodes** for high availability
- **t3.large instances** (2 vCPU, 8GB RAM) - suitable for moderate workloads
- **ap-south-1** (Mumbai) - likely for regional compliance/latency
- **50GB volumes** - adequate for logs and configuration

---

### 3. `Jenkinsfile` - CI/CD Pipeline
**Purpose:** Automates the deployment process through Jenkins

#### Stage 1: Checkout Repo
```groovy
git branch: 'main', url: 'https://your.repo/project.git'
```
- Clones the repository containing deployment code
- **Note:** URL is a placeholder and needs to be updated

#### Stage 2: Load grd.yaml
```groovy
grd = readYaml file: "grd.yaml"
STACK_NAME = grd.stack_name
// ... loads all configuration
```
- Parses YAML configuration into Jenkins variables
- Makes configuration values available to subsequent stages

#### Stage 3: Build CFN Parameters JSON
```groovy
writeJSON file: "parameters.json",
          json: PARAMETERS, pretty: 4
```
- Converts parameters from YAML to JSON format
- CloudFormation CLI requires JSON for parameter overrides

#### Stage 4: Validate CFN Template
```bash
aws cloudformation validate-template \
    --template-body file://${TEMPLATE_FILE}
```
- Pre-deployment validation to catch syntax errors
- Fails fast before attempting actual deployment
- Checks template structure and parameter definitions

#### Stage 5: Deploy Infrastructure
```bash
aws cloudformation deploy \
    --stack-name ${STACK_NAME} \
    --template-file ${TEMPLATE_FILE} \
    --parameter-overrides file://parameters.json \
    --capabilities CAPABILITY_NAMED_IAM \
    --region ${AWS_REGION}
```
- Creates or updates the CloudFormation stack
- `CAPABILITY_NAMED_IAM`: Required because template may create IAM resources
- Uses update-or-create semantics (idempotent)

#### Stage 6: Run Scripts
```bash
bash ${USERDATA_FILE}
bash ${BOOTSTRAP_FILE}
```
- **Issue:** These scripts are run on the Jenkins agent, not on EC2 instances
- **Expected behavior:** Should be embedded in EC2 UserData or run via SSH
- **Current behavior:** May fail or have no effect on actual instances

#### Stage 7: Notify Team
```groovy
emailext(
    to: EMAIL_TO,
    subject: "Cribl Leader Deployment Completed",
    body: "Deployment finished using grd.yaml."
)
```
- Sends success notification
- Uses Jenkins EmailExt plugin

#### Post-Failure Handler
```groovy
post {
    failure {
        emailext(..., subject: "Cribl Leader Deployment FAILED", ...)
    }
}
```
- Sends failure notification if any stage fails
- Ensures team is always notified

---

### 4. `cloudformation/cribl-leader.yaml` - Infrastructure Template
**Purpose:** Defines AWS infrastructure as code

#### Parameters Section
```yaml
Parameters:
  InstanceType: {Type: String}
  KeyName: {Type: String}
  AmiId: {Type: String}
  VpcId: {Type: AWS::EC2::VPC::Id}
  SubnetId: {Type: AWS::EC2::Subnet::Id}
  SecurityGroup: {Type: AWS::EC2::SecurityGroup::Id}
  LeaderNodeCount: {Type: Number}
  VolumeSize: {Type: Number}
```
- All values are externalized for flexibility
- Type validation ensures correct input format

#### Resource: CriblLeaderLaunchConfig (EC2 Launch Template)
```yaml
LaunchTemplateData:
  ImageId: !Ref AmiId                    # Operating system image
  InstanceType: !Ref InstanceType        # Instance size
  KeyName: !Ref KeyName                  # SSH access key
  NetworkInterfaces:
    - AssociatePublicIpAddress: false    # Private instances only
      SubnetId: !Ref SubnetId
      Groups: [!Ref SecurityGroup]
  BlockDeviceMappings:
    - DeviceName: "/dev/xvda"
      Ebs:
        VolumeSize: !Ref VolumeSize
        VolumeType: gp3                  # General Purpose SSD v3
  UserData:
    Fn::Base64: |
      #!/bin/bash
      /opt/cribl/start-leader.sh
```

**Key Points:**
- **No public IP**: Instances are in private subnet for security
- **gp3 volumes**: Latest generation SSD with better price/performance
- **UserData**: Runs a startup script (assumes script exists at that path)
- **Issue**: The UserData references `/opt/cribl/start-leader.sh` which doesn't exist yet; it's created by the userdata script

#### Resource: CriblLeaderAutoScalingGroup
```yaml
MinSize: !Ref LeaderNodeCount
MaxSize: !Ref LeaderNodeCount
DesiredCapacity: !Ref LeaderNodeCount
VPCZoneIdentifier: [!Ref SubnetId]
LaunchTemplate:
  LaunchTemplateId: !Ref CriblLeaderLaunchConfig
  Version: !GetAtt CriblLeaderLaunchConfig.LatestVersionNumber
```

**Key Points:**
- Min = Max = Desired: Fixed size cluster (no auto-scaling)
- Uses latest version of launch template
- Single subnet deployment (could be enhanced with multi-AZ)

#### Outputs Section
```yaml
Outputs:
  LeaderASG: {Value: !Ref CriblLeaderAutoScalingGroup}
```
- Exports Auto Scaling Group ID for reference
- Can be used by other stacks or for monitoring

---

### 5. `scripts/leader-userdata.sh` - Installation Script
**Purpose:** Installs Cribl software on fresh EC2 instances

```bash
#!/bin/bash
set -e                                   # Exit on any error

yum update -y                            # Update system packages (Amazon Linux)
yum install -y curl wget unzip jq        # Install dependencies
mkdir -p /opt/cribl                      # Create installation directory
cd /opt/cribl

wget https://cdn.cribl.io/cribl-4.0.0.tgz -O cribl.tgz
tar -xzf cribl.tgz                       # Extract Cribl package
```

**What it does:**
1. **Error handling**: `set -e` ensures script stops if any command fails
2. **System preparation**: Updates packages and installs utilities
3. **Cribl download**: Fetches specific version (4.0.0) from official CDN
4. **Extraction**: Unpacks software into `/opt/cribl`

**Tools installed:**
- **curl/wget**: HTTP clients for downloading
- **unzip**: Archive extraction
- **jq**: JSON processing (for API interactions)

**Version pinning:**
- Uses Cribl 4.0.0 specifically (not latest)
- Ensures consistent deployments
- Should be updated when upgrading

---

### 6. `scripts/leader-bootstrap.sh` - Service Startup Script
**Purpose:** Starts and enables Cribl service

```bash
#!/bin/bash
set -e                                   # Exit on any error

cd /opt/cribl/cribl/bin
./cribl start                            # Start Cribl immediately
systemctl enable cribl                   # Enable service on boot
```

**What it does:**
1. **Navigate to Cribl binary directory**
2. **Start service**: Launches Cribl Leader process
3. **Enable auto-start**: Ensures Cribl starts after system reboot

**Assumptions:**
- Cribl was successfully extracted by userdata script
- The `./cribl` binary exists at expected path
- Systemd service file exists (may be created by `./cribl start`)

---

## Deployment Workflow

### Complete Deployment Sequence:

```
1. Developer triggers Jenkins job
   ↓
2. Jenkins checks out code from Git
   ↓
3. Jenkins reads grd.yaml configuration
   ↓
4. Jenkins converts parameters to JSON
   ↓
5. CloudFormation validates template syntax
   ↓
6. CloudFormation creates/updates stack:
   - Creates Launch Template
   - Creates Auto Scaling Group
   - ASG launches 2 EC2 instances
   ↓
7. EC2 instances boot and run UserData:
   - leader-userdata.sh downloads Cribl
   - Cribl is extracted to /opt/cribl
   ↓
8. Bootstrap runs on instances:
   - leader-bootstrap.sh starts Cribl
   - Service is enabled for auto-start
   ↓
9. Jenkins sends success email
   ↓
10. Cribl Leader nodes are operational
```

### Time Estimates:
- **CloudFormation deployment**: 3-5 minutes
- **EC2 instance launch**: 1-2 minutes
- **Cribl download and extract**: 1-2 minutes
- **Total**: ~5-10 minutes end-to-end

---

## Configuration Guide

### How to Customize Deployment:

#### 1. Change Instance Size
Edit `grd.yaml`:
```yaml
parameters:
  InstanceType: t3.xlarge  # 4 vCPU, 16GB RAM
```

#### 2. Deploy to Different Region
Edit `grd.yaml`:
```yaml
region: us-east-1
```
**Note:** Must also update AmiId, VpcId, SubnetId for that region

#### 3. Increase Leader Node Count
Edit `grd.yaml`:
```yaml
parameters:
  LeaderNodeCount: 3  # Deploy 3 leaders instead of 2
```

#### 4. Upgrade Cribl Version
Edit `scripts/leader-userdata.sh`:
```bash
wget https://cdn.cribl.io/cribl-4.2.0.tgz -O cribl.tgz
```

#### 5. Change Notification Email
Edit `grd.yaml`:
```yaml
notification_email: "newteam@company.com"
```

---

## Security Considerations

### Current Security Posture:

✅ **Good Practices:**
- Instances in private subnet (no public IP)
- Uses security groups for network isolation
- SSH key authentication for access
- IAM capabilities explicitly declared
- Error handling in scripts (`set -e`)

⚠️ **Security Concerns:**

1. **Hardcoded Credentials Risk**
   - Git repository URL is placeholder
   - AMI ID, VPC ID, Subnet ID are visible in config
   - **Mitigation**: Use Jenkins credentials store or AWS Secrets Manager

2. **No HTTPS Verification**
   - Cribl download doesn't verify checksum
   - **Mitigation**: Add SHA256 verification:
     ```bash
     echo "EXPECTED_SHA256 cribl.tgz" | sha256sum -c
     ```

3. **Broad IAM Capabilities**
   - `CAPABILITY_NAMED_IAM` allows creating any IAM resource
   - **Mitigation**: Use `CAPABILITY_IAM` if possible, or specify exact IAM resources

4. **Script Execution Issues**
   - Jenkinsfile runs scripts locally (Stage 6)
   - Scripts should be embedded in EC2 UserData
   - **Current**: May fail silently

5. **No Logging/Monitoring**
   - No CloudWatch logs for script execution
   - No alerts for failures
   - **Mitigation**: Add CloudWatch Logs agent, SNS alerts

6. **Version Pinning**
   - Cribl 4.0.0 may have known vulnerabilities
   - **Mitigation**: Regular version updates, security scanning

7. **No Encryption at Rest**
   - EBS volumes not explicitly encrypted
   - **Mitigation**: Add to BlockDeviceMappings:
     ```yaml
     Encrypted: true
     KmsKeyId: !Ref MyKmsKey
     ```

### Recommended Security Enhancements:

```yaml
# In CloudFormation template
BlockDeviceMappings:
  - DeviceName: "/dev/xvda"
    Ebs:
      VolumeSize: !Ref VolumeSize
      VolumeType: gp3
      Encrypted: true              # Add this
      DeleteOnTermination: true    # Add this
```

```bash
# In userdata script
wget https://cdn.cribl.io/cribl-4.0.0.tgz -O cribl.tgz
echo "EXPECTED_CHECKSUM cribl.tgz" | sha256sum -c
```

---

## Known Issues and Limitations

1. **Single Subnet Deployment**
   - No multi-AZ redundancy
   - Single point of failure
   - **Fix**: Use multiple subnets in different AZs

2. **Script Execution Bug**
   - Stage 6 in Jenkinsfile runs scripts on Jenkins agent
   - Should run on EC2 instances via UserData or SSH
   - **Fix**: Embed scripts in CloudFormation UserData or remove stage

3. **No Health Checks**
   - Auto Scaling Group has no health checks
   - Won't replace unhealthy instances
   - **Fix**: Add ELB or EC2 health checks

4. **No Load Balancer**
   - No single endpoint for accessing leaders
   - **Fix**: Add Application Load Balancer

5. **Static Configuration**
   - All config in grd.yaml must be manually edited
   - **Fix**: Use parameter files per environment

---

## Quick Reference

### Key Files:
| File | Purpose | Language |
|------|---------|----------|
| `grd.yaml` | Configuration | YAML |
| `Jenkinsfile` | CI/CD pipeline | Groovy |
| `cribl-leader.yaml` | Infrastructure | CloudFormation |
| `leader-userdata.sh` | Install Cribl | Bash |
| `leader-bootstrap.sh` | Start Cribl | Bash |

### Key AWS Resources:
- **Stack Name**: `cribl-leader-stack`
- **Region**: `ap-south-1` (Mumbai)
- **Instances**: 2x t3.large
- **Storage**: 50GB gp3 per instance

### Key Ports (implied):
- **9000**: Cribl UI/API (default)
- **4200**: Cribl internal communication
- **22**: SSH (for key-based access)

---

## Conclusion

This codebase implements a Jenkins-driven, CloudFormation-based deployment system for Cribl Leader nodes. It demonstrates infrastructure-as-code principles with externalized configuration, automated validation, and notification mechanisms.

**Strengths:**
- Automated, repeatable deployments
- Configuration externalized to YAML
- Multiple deployment stages with validation
- Email notifications for visibility

**Areas for Improvement:**
- Security enhancements (encryption, checksum verification)
- Multi-AZ deployment for high availability
- Health checks and auto-recovery
- Fix script execution in Jenkinsfile Stage 6
- Enhanced error handling and logging
- Parameter validation and defaults

The code is functional for basic deployments but would benefit from production-grade enhancements for enterprise use cases.
