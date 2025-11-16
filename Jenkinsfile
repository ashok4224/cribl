/*
 * ============================================================================
 * CRIBL LEADER DEPLOYMENT PIPELINE
 * ============================================================================
 * 
 * ABOUT THIS REPOSITORY:
 * This repository contains an automated deployment solution for Cribl Leader
 * nodes on AWS infrastructure. Cribl is a data observability and streaming
 * platform that helps organizations collect, reduce, enrich, and route data
 * from any source to any destination.
 * 
 * PURPOSE:
 * - Automate the deployment of Cribl Leader nodes using AWS CloudFormation
 * - Provide Infrastructure as Code (IaC) for Cribl Leader infrastructure
 * - Ensure consistent and repeatable deployments across environments
 * - Manage deployment configuration through YAML files (grd.yaml)
 * 
 * COMPONENTS:
 * 1. Jenkinsfile - This CI/CD pipeline orchestrates the entire deployment
 * 2. grd.yaml - Configuration file containing deployment parameters
 * 3. cloudformation/cribl-leader.yaml - AWS CloudFormation template
 * 4. scripts/leader-userdata.sh - Initial setup script for EC2 instances
 * 5. scripts/leader-bootstrap.sh - Cribl service initialization script
 * 
 * PIPELINE WORKFLOW:
 * 1. Checkout Repository - Pulls the latest code from the main branch
 * 2. Load Configuration - Reads grd.yaml for deployment parameters
 * 3. Build Parameters - Converts YAML parameters to JSON for CloudFormation
 * 4. Validate Template - Ensures CloudFormation template is valid
 * 5. Deploy Infrastructure - Creates/updates AWS resources via CloudFormation
 * 6. Run Scripts - Executes userdata and bootstrap scripts
 * 7. Notify Team - Sends email notification on deployment status
 * 
 * DEPLOYMENT DETAILS:
 * - AWS Region: ap-south-1 (configurable in grd.yaml)
 * - Instance Type: t3.large (configurable)
 * - Auto Scaling: Deploys 2 Leader nodes by default
 * - Storage: 50GB EBS volumes with gp3 type
 * - Cribl Version: 4.0.0 (defined in userdata script)
 * 
 * PREREQUISITES:
 * - Jenkins with AWS CLI configured
 * - AWS credentials with CloudFormation permissions
 * - Required Jenkins plugins: Pipeline, Email Extension, YAML parser
 * - Valid AMI ID, VPC, Subnet, and Security Group in target AWS region
 * 
 * MAINTAINED BY: ashok.team@company.com
 * ============================================================================
 */

pipeline {
    agent any
    stages {
        stage('Checkout Repo') {
            steps {
                git branch: 'main', url: 'https://your.repo/project.git'
            }
        }
        stage('Load grd.yaml') {
            steps {
                script {
                    grd = readYaml file: "grd.yaml"
                    STACK_NAME      = grd.stack_name
                    AWS_REGION      = grd.region
                    TEMPLATE_FILE   = grd.cloudformation_template
                    PARAMETERS      = grd.parameters
                    USERDATA_FILE   = grd.userdata_script
                    BOOTSTRAP_FILE  = grd.bootstrap_script
                    EMAIL_TO        = grd.notification_email
                }
            }
        }
        stage('Build CFN Parameters JSON') {
            steps {
                script {
                    writeJSON file: "parameters.json",
                              json: PARAMETERS, pretty: 4
                }
            }
        }
        stage('Validate CFN Template') {
            steps {
                sh """
                aws cloudformation validate-template                     --template-body file://${TEMPLATE_FILE}
                """
            }
        }
        stage('Deploy Infra via CloudFormation') {
            steps {
                sh """
                aws cloudformation deploy                     --stack-name ${STACK_NAME}                     --template-file ${TEMPLATE_FILE}                     --parameter-overrides file://parameters.json                     --capabilities CAPABILITY_NAMED_IAM                     --region ${AWS_REGION}
                """
            }
        }
        stage('Run Scripts (Userdata & Bootstrap)') {
            steps {
                script {
                    sh "bash ${USERDATA_FILE}"
                    sh "bash ${BOOTSTRAP_FILE}"
                }
            }
        }
        stage('Notify Team') {
            steps {
                emailext(
                    to: EMAIL_TO,
                    subject: "Cribl Leader Deployment Completed",
                    body: "Deployment finished using grd.yaml."
                )
            }
        }
    }
    post {
        failure {
            emailext(
                to: EMAIL_TO,
                subject: "Cribl Leader Deployment FAILED",
                body: "Pipeline failed. Check logs in Jenkins."
            )
        }
    }
}