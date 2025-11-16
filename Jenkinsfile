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