def sshCredentials = [
    sshUserPrivateKey(
        credentialsId: 'ec2-ssh-credentials',
        keyFileVariable: 'SSH_KEY',
        passphraseVariable: '',
        usernameVariable: 'SSH_USER'
    )
]

pipeline
{
  agent any
  parameters
  {
    string(name: 'IP_ADDRESS', defaultValue: '20.115.89.60', description: 'Enter IP address of target EC2 instance')
  }

  environment {
        SERVER_INSTANCE_USERNAME = 'azureuser'
        REPOSITORY_NAME = 'node_app'
        REPOSITORY_DIRECTORY = "/home/$SERVER_INSTANCE_USERNAME/$REPOSITORY_NAME"
        DOCKER_IMAGE_TAG = ''
        DOCKER_PORT = '3000'
  }

  stages
  {
    stage('Connect to EC2')
    {
      steps
      {
        script
        {
          // Check if IP address was provided
          if (params.IP_ADDRESS == '') {
            error 'IP address parameter is required'
          }

            // Set the SSH key environment variable
            withCredentials(sshCredentials)
            {
              env.SSH_KEY = readFile(env.SSH_KEY)

              // SSH into EC2 instance
              sh "ssh -o StrictHostKeyChecking=no -i ${env.SSH_KEY} ${env.SSH_USER}@${params.IP_ADDRESS} 'echo SSH Agent initialized'"
            }
        }
      }
    }

    stage('Source Code Checkout') {
      steps {
        script {
            withCredentials(sshCredentials) {
              env.SSH_KEY = readFile(env.SSH_KEY)
            withCredentials([usernamePassword(credentialsId: 'git-credentials-id', usernameVariable: 'GIT_USERNAME', passwordVariable: 'GIT_PASSWORD')]) {
              sh "git config --global credential.username ${env.GIT_USERNAME}"
              sh "git config --global credential.helper '!echo password=${env.GIT_PASSWORD}; echo'"

              def remoteCommands = [
                    "mkdir -p ${REPOSITORY_DIRECTORY}",
                    "cd ${REPOSITORY_DIRECTORY} && if [ -d \".git\" ]; then git checkout main && git pull; else git clone -b main https://${GIT_USERNAME}:${GIT_PASSWORD}@github.com/rishawsingh/${REPOSITORY_NAME}.git .; fi"
                ]

                def sshCommand = "ssh -o StrictHostKeyChecking=no -i ${env.SSH_KEY} ${env.SSH_USER}@${params.IP_ADDRESS}"

                remoteCommands.each { command ->
                    sh "${sshCommand} '${command}'"
                }

              // Define docker tag based on last commit
              def dockerImageTag = sh(returnStdout: true, script: "ssh -o StrictHostKeyChecking=no -i ${env.SSH_KEY} ${env.SSH_USER}@${params.IP_ADDRESS} 'cd ${REPOSITORY_DIRECTORY} && git rev-parse --short HEAD'").trim()
              DOCKER_IMAGE_TAG = dockerImageTag
            }
            }
        }
      }
    }

    stage('Build Docker Image') {
      steps {
        script {
          withCredentials(sshCredentials) {
            env.SSH_KEY = readFile(env.SSH_KEY)

            sh "ssh -o StrictHostKeyChecking=no -i ${env.SSH_KEY} ${env.SSH_USER}@${params.IP_ADDRESS} 'export DOCKER_IMAGE_TAG=${DOCKER_IMAGE_TAG} DOCKER_PORT=${DOCKER_PORT} && docker compose -f ${REPOSITORY_DIRECTORY}/docker-compose.yml build'"
          }
        }
      }
    }

    stage('Stop Old Container')
    {
      steps
      {
        script
        {
          try {
            withCredentials(sshCredentials)
            {
              env.SSH_KEY = readFile(env.SSH_KEY)

              // SSH into EC2 instance and stop the container
              sh "ssh -o StrictHostKeyChecking=no -i ${env.SSH_KEY} ${env.SSH_USER}@${params.IP_ADDRESS} 'export DOCKER_IMAGE_TAG=${DOCKER_IMAGE_TAG} DOCKER_PORT=${DOCKER_PORT} && docker compose -f ${REPOSITORY_DIRECTORY}/docker-compose.yml down'"
            }
          } catch (Exception e)
          {
            echo 'No old container found. Proceeding with the pipeline.'
          }
        }
      }
    }

    stage('Run New Container')
    {
      steps
      {
        script
        {
          withCredentials(sshCredentials)
          {
            env.SSH_KEY = readFile(env.SSH_KEY)

            // SSH into EC2 instance and run the new container
            sh "ssh -o StrictHostKeyChecking=no -i ${env.SSH_KEY} ${env.SSH_USER}@${params.IP_ADDRESS} 'export DOCKER_IMAGE_TAG=${DOCKER_IMAGE_TAG} DOCKER_PORT=${DOCKER_PORT} && docker compose -f ${REPOSITORY_DIRECTORY}/docker-compose.yml up -d'"
          }
        }
      }
    }
  }
    post {
    always {
          script {
            try {
          def buildStatus = currentBuild.currentResult
          def urlWebhook = env.URL_WEBHOOK

          if (buildStatus == 'SUCCESS') {
            office365ConnectorSend webhookUrl: urlWebhook,
                  message: "Application Build and Deployment Notification - Build #${env.BUILD_NUMBER} Successful",
                  status: 'Success'
              } else if (buildStatus == 'FAILURE') {
            office365ConnectorSend webhookUrl: urlWebhook,
                  message: "Application Build and Deployment Notification - Build #${env.BUILD_NUMBER} Failed",
                  status: 'Failure'
              } else if (buildStatus == 'ABORTED') {
            office365ConnectorSend webhookUrl: urlWebhook,
                  message: "Application Build and Deployment Notification - Build #${env.BUILD_NUMBER} Aborted",
                  status: 'Aborted'
          }
            } catch (Exception e) {
          echo "Failed to send notification: ${e.message}"
            }
          }
    }
    }
}
