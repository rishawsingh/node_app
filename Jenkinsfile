pipeline 
{
  agent any
  parameters 
  {
    string(name: 'IP_ADDRESS', defaultValue: '172.190.129.18', description: 'Enter IP address of target EC2 instance')
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
  
              // SSH into EC2 instance
              sh "ssh -o StrictHostKeyChecking=no -i ${env.SSH_KEY} ${env.SSH_USER}@${params.IP_ADDRESS} 'echo SSH Agent initialized'"
            }
        }
      }
    }

  

    stage('Source Code Checkout') 
    {
      steps 
      {
        script 
        {
          withCredentials([usernamePassword(credentialsId: 'my-git-credentials-id', usernameVariable: 'GIT_USERNAME', passwordVariable: 'GIT_PASSWORD')]) 
          {
            sh "git config --global credential.username ${env.GIT_USERNAME}"
            sh "git config --global credential.helper '!echo password=${env.GIT_PASSWORD}; echo'"

            // Clone or update the node_app repository
            dir('node_app') 
            {
              if (fileExists('.git')) 
              {
                // If the repository already exists, perform a git pull to update the code
                sh "git pull"
              } else {
                // If the repository doesn't exist, clone it
                sh "git clone https://github.com/rishawsingh/node_app.git ."
              }
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
          if (!fileExists('node_app/Dockerfile')) 
          {
            error "Dockerfile not found in the node_app repository"
          }
          // Build the Docker image using the Dockerfile in the node_app directory
          def dockerImageTag = sh(returnStdout: true, script: 'git -C node_app rev-parse --short HEAD').trim()
          env.DOCKER_IMAGE_TAG = dockerImageTag // Store the tag in an environment variable
          sh "docker build -t node_app:${dockerImageTag} node_app"
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

              // SSH into EC2 instance and stop the container
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

            // SSH into EC2 instance and run the new container
            sh "ssh -o StrictHostKeyChecking=no -i ${env.SSH_KEY} ${env.SSH_USER}@${params.IP_ADDRESS} 'docker run -d -p 3000:3000 --name node_app node_app:${env.DOCKER_IMAGE_TAG}'"
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
