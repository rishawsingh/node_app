pipeline 
{
  agent any
  parameters 
  {
    string(name: 'IP_ADDRESS', defaultValue: '13.127.201.247', description: 'Enter IP address of target VM instance')
  }
  
  stages 
  {
    stage('Connect to VM') 
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
            withCredentials([sshUserPrivateKey(credentialsId: 'vm-ssh-credentials', keyFileVariable: 'SSH_KEY', passphraseVariable: '', usernameVariable: 'SSH_USER')]) 
            {
              env.SSH_KEY = readFile(env.SSH_KEY)
  
              // SSH into VM instance
              sh "ssh -o StrictHostKeyChecking=no -i ${env.SSH_KEY} ${env.SSH_USER}@${params.IP_ADDRESS} 'echo SSH Agent initialized'"
            }
        }
      }
    }

  

    stage('Source Code Checkout') {
      steps {
        script 
        {
            withCredentials([sshUserPrivateKey(credentialsId: 'vm-ssh-credentials', keyFileVariable: 'SSH_KEY', passphraseVariable: '', usernameVariable: 'SSH_USER')]) 
            {
              env.SSH_KEY = readFile(env.SSH_KEY)
                withCredentials([usernamePassword(credentialsId: 'git-credentials-id', usernameVariable: 'GIT_USERNAME', passwordVariable: 'GIT_PASSWORD')]) 
                {
                    sh "git config --global credential.username ${env.GIT_USERNAME}"
                    sh "git config --global credential.helper '!echo password=${env.GIT_PASSWORD}; echo'"

                    // SSH into nodeapp Docker VM instance


                    // Create node_app directory
                    sh "ssh -o StrictHostKeyChecking=no -i ${env.SSH_KEY} ${env.SSH_USER}@${params.IP_ADDRESS} 'mkdir -p node_app'"

                    // Clone or update the node_app repository with the dev branch
                    sh "ssh -o StrictHostKeyChecking=no -i ${env.SSH_KEY} ${env.SSH_USER}@${params.IP_ADDRESS} 'cd node_app && if [ -d \".git\" ]; then git pull; else git clone https://${GIT_USERNAME}:${GIT_PASSWORD}@github.com/rishawsingh/node_app.git .; fi'"
                }
            }
        }
      }
    }


    stage('Build Docker Image') 
    {
      steps 
      {
        script 
        {
          // SSH into nodeapp Docker VM instance
            withCredentials([sshUserPrivateKey(credentialsId: 'vm-ssh-credentials', keyFileVariable: 'SSH_KEY', passphraseVariable: '', usernameVariable: 'SSH_USER')]) 
            {
                env.SSH_KEY = readFile(env.SSH_KEY)

                // Verify if Dockerfile exists in the node_app repository
                if (!fileExists('node_app/Dockerfile')) {
                error "Dockerfile not found in the node_app repository"
                }

                // Build the Docker image using the Dockerfile in the node_app directory
                def dockerImageTag = sh(returnStdout: true, script: "ssh -o StrictHostKeyChecking=no -i ${env.SSH_KEY} ${env.SSH_USER}@${params.IP_ADDRESS} 'cd node_app && git rev-parse --short HEAD'").trim()
                env.DOCKER_IMAGE_TAG = dockerImageTag // Store the tag in an environment variable
                sh "ssh -o StrictHostKeyChecking=no -i ${env.SSH_KEY} ${env.SSH_USER}@${params.IP_ADDRESS} 'cd node_app && docker build -t nodeapp:${dockerImageTag} .'"
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
            withCredentials([sshUserPrivateKey(credentialsId: 'vm-ssh-credentials', keyFileVariable: 'SSH_KEY', passphraseVariable: '', usernameVariable: 'SSH_USER')]) 
            {
              env.SSH_KEY = readFile(env.SSH_KEY)

              // SSH into VM instance and stop the container
              sh "ssh -o StrictHostKeyChecking=no -i ${env.SSH_KEY} ${env.SSH_USER}@${params.IP_ADDRESS} 'docker stop nodeapp && docker rm nodeapp'"
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
          withCredentials([sshUserPrivateKey(credentialsId: 'vm-ssh-credentials', keyFileVariable: 'SSH_KEY', passphraseVariable: '', usernameVariable: 'SSH_USER')]) 
          {
            env.SSH_KEY = readFile(env.SSH_KEY)

            // SSH into VM instance and run the new container
            sh "ssh -o StrictHostKeyChecking=no -i ${env.SSH_KEY} ${env.SSH_USER}@${params.IP_ADDRESS} 'docker run -d -p 3000:3000 --name nodeapp nodeapp:${env.DOCKER_IMAGE_TAG}'"
          }
        }
      }
    }

    // Previous stages omitted for brevity
  }
  post {
    always {
      script {
        def buildStatus = currentBuild.currentResult

        if (buildStatus == 'SUCCESS') {
          emailext (
            subject: "Application Build and Deployment Notification - Build #${env.BUILD_NUMBER} Successful",
            body: "The application has been built and deployed on the servers.\n\nBuild Number: ${env.BUILD_NUMBER}\nJob Name: ${env.JOB_NAME}",
            to: 'rishaw.2k@gmail.com',
            mimeType: 'text/plain'
          )
        } else if (buildStatus == 'FAILURE') {
          emailext (
            subject: "Application Build and Deployment Notification - Build #${env.BUILD_NUMBER} Failed",
            body: "Uh-oh! Something's wrong. The build failed.\n\nBuild Number: ${env.BUILD_NUMBER}\nJob Name: ${env.JOB_NAME}",
            to: 'rishaw.2k@gmail.com',
            mimeType: 'text/plain'
          )
        } else if (buildStatus == 'ABORTED') {
          emailext (
            subject: "Application Build and Deployment Notification - Build #${env.BUILD_NUMBER} Aborted",
            body: "Looks like somebody aborted the build.\n\nBuild Number: ${env.BUILD_NUMBER}\nJob Name: ${env.JOB_NAME}",
            to: 'rishaw.2k@gmail.com',
            mimeType: 'text/plain'
          )
        }
      }
    }
  }
}
