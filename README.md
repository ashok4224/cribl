# Cribl Leader Deployment Package

## Overview
This repository contains an automated deployment system for **Cribl Leader Nodes** on AWS using Jenkins, CloudFormation, and Bash scripts.

## Quick Start
1. Configure your deployment settings in `grd.yaml`
2. Update the Jenkinsfile repository URL (line 6)
3. Run the Jenkins pipeline
4. Cribl Leader nodes will be deployed to AWS

## Documentation
📖 **[Complete Code Explanation](CODE_EXPLANATION.md)** - Comprehensive documentation covering:
- Architecture and workflow
- Detailed breakdown of each component
- Configuration guide
- Security considerations
- Known issues and improvements

## Components
- **grd.yaml** - Central configuration file
- **Jenkinsfile** - CI/CD pipeline definition
- **cloudformation/cribl-leader.yaml** - AWS infrastructure template
- **scripts/leader-userdata.sh** - Cribl installation script
- **scripts/leader-bootstrap.sh** - Service startup script

## Infrastructure
- **Region**: ap-south-1 (Mumbai)
- **Instances**: 2x t3.large EC2 instances
- **Storage**: 50GB gp3 volumes
- **Deployment**: Auto Scaling Group for high availability

## Prerequisites
- Jenkins with AWS CLI configured
- AWS account with appropriate IAM permissions
- VPC, Subnet, Security Group, and SSH Key in target region
- Jenkins plugins: Pipeline, EmailExt, YAML

## Support
For detailed explanations of the code, architecture, and deployment workflow, see [CODE_EXPLANATION.md](CODE_EXPLANATION.md)
