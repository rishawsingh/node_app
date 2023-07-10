pipeline 
{
  agent any
  parameters 
  {
    string(name: 'IP_ADDRESS', defaultValue: '52.255.134.135', description: 'Enter IP address of target EC2 instance Or any VM')
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
            if (params.IP_ADDRESS == '') 
            {
              error "IP address parameter is required"
            }
  
            // Set the SSH key environment variable
            withCredentials([sshUserPrivateKey(credentialsId: 'my-ssh-credentials', keyFileVariable: 'SSH_KEY', passphraseVariable: '', usernameVariable: 'SSH_USER')]) 
            {
              env.SSH_KEY = readFile(env.SSH_KEY)
  
              // SSH into EC2 instance Or any VM
              sh "ssh -o StrictHostKeyChecking=no -i ${env.SSH_KEY} ${env.SSH_USER}@${params.IP_ADDRESS} 'echo SSH Agent initialized'"
            }
        }
      }
    }

  

    stage('Source Code Checkout') {
      steps {
        script {
            withCredentials([sshUserPrivateKey(credentialsId: 'my-ssh-credentials', keyFileVariable: 'SSH_KEY', passphraseVariable: '', usernameVariable: 'SSH_USER')]) {
              env.SSH_KEY = readFile(env.SSH_KEY)
          withCredentials([usernamePassword(credentialsId: 'my-git-credentials-id', usernameVariable: 'GIT_USERNAME', passwordVariable: 'GIT_PASSWORD')]) {
            sh "git config --global credential.username ${env.GIT_USERNAME}"
            sh "git config --global credential.helper '!echo password=${env.GIT_PASSWORD}; echo'"

            // SSH into node_app Docker EC2 instance Or any VM

              // Create my_nodeapp directory
              sh "ssh -o StrictHostKeyChecking=no -i ${env.SSH_KEY} ${env.SSH_USER}@${params.IP_ADDRESS} 'mkdir -p /home/azureuser/my_nodeapp'"

              // Clone or update the my_nodeapp repository with the dev branch
              sh "ssh -o StrictHostKeyChecking=no -i ${env.SSH_KEY} ${env.SSH_USER}@${params.IP_ADDRESS} 'cd /home/azureuser/my_nodeapp && if [ -d \".git\" ]; then git checkout main && git pull; else git clone -b main https://${GIT_USERNAME}:${GIT_PASSWORD}@github.com/rishawsingh/node_app.git .; fi'"
            }
          }
        }
      }
    }


    stage('Build Docker Image') {
      steps {
        script {
          // SSH into node_app Docker EC2 instance Or any VM
withCredentials([sshUserPrivateKey(credentialsId: 'my-ssh-credentials', keyFileVariable: 'SSH_KEY', passphraseVariable: '', usernameVariable: 'SSH_USER')]) {
        env.SSH_KEY = readFile(env.SSH_KEY)


        // Build the Docker image using the Dockerfile in the my_nodeapp directory
        def dockerImageTag = sh(returnStdout: true, script: "ssh -o StrictHostKeyChecking=no -i ${env.SSH_KEY} ${env.SSH_USER}@${params.IP_ADDRESS} 'cd my_nodeapp && git rev-parse --short HEAD'").trim()
        env.DOCKER_IMAGE_TAG = dockerImageTag // Store the tag in an environment variable
        sh "ssh -o StrictHostKeyChecking=no -i ${env.SSH_KEY} ${env.SSH_USER}@${params.IP_ADDRESS} 'cd /home/azureuser/my_nodeapp && docker build -t node_app:${dockerImageTag} .'"
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
          try 
          {
            withCredentials([sshUserPrivateKey(credentialsId: 'my-ssh-credentials', keyFileVariable: 'SSH_KEY', passphraseVariable: '', usernameVariable: 'SSH_USER')]) 
            {
              env.SSH_KEY = readFile(env.SSH_KEY)

              // SSH into EC2 instance Or any VM and stop the container
              sh "ssh -o StrictHostKeyChecking=no -i ${env.SSH_KEY} ${env.SSH_USER}@${params.IP_ADDRESS} 'docker stop node_app && docker rm node_app'"
            }
          } catch (Exception e) 
          {
            echo "No old container found. Proceeding with the pipeline."
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
          withCredentials([sshUserPrivateKey(credentialsId: 'my-ssh-credentials', keyFileVariable: 'SSH_KEY', passphraseVariable: '', usernameVariable: 'SSH_USER')]) 
          {
            env.SSH_KEY = readFile(env.SSH_KEY)

            // SSH into EC2 instance Or any VM and run the new container
            sh "ssh -o StrictHostKeyChecking=no -i ${env.SSH_KEY} ${env.SSH_USER}@${params.IP_ADDRESS} 'docker run -d -p 3000:3000 --name node_app node_app:${env.DOCKER_IMAGE_TAG}'"
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
