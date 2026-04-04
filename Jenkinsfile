pipeline {
    agent any
    environment {
        DOCKER_HUB_CREDENTIALS = credentials('docker-hub-token')
        DOCKER_HUB_IMAGE_NAME = 'coolth/mern-stack'
        IMAGE_TAG = "v${env.BUILD_NUMBER}"
    }
    
    stages {
        stage('Checking Docker version') {
            steps {
                sh 'docker -v'
            }
        }
       
        stage('Login to Docker Hub') {      	
            steps{                       	
                 sh 'echo $DOCKER_HUB_CREDENTIALS_PSW | docker login -u $DOCKER_HUB_CREDENTIALS_USR --password-stdin'               		
                echo 'Login Completed'      
            }           
        }  
      

        stage('Build and Push to Docker Hub') {
            steps {
                 //dir('/var/jenkins_home/workspace/mern-stack/mern-stack-ci-cd-fargate') 
                
                sh "docker build -t ${DOCKER_HUB_IMAGE_NAME}:latest ."
                sh "docker tag ${DOCKER_HUB_IMAGE_NAME}:latest ${DOCKER_HUB_IMAGE_NAME}:lts"
                sh "docker push ${DOCKER_HUB_IMAGE_NAME}:lts"
                
            }
        }
         stage('Terraform Init') {
            steps {
                 dir('/var/jenkins_home/workspace/mern-stack/mern-stack-ci-cd-fargate/tf') 
                {
                    sh 'terraform init'
                }
            }
        }
        
        stage('Terraform Plan') {
            steps {
                dir('tf') {
                    sh 'terraform plan'
                }
            }
        }
        
        stage('Terraform Apply') {
            steps {
                dir('tf') {
                    sh 'terraform apply -auto-approve'
                }
            }
        }
        
    }

    // post {
    //     always {
    //         sh 'docker logout'
    //     }
    // }
}
