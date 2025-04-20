pipeline {
    agent any
    environment {
  
        DOCKER_IMAGE = "saiteja0605/finocplus:build-${env.BUILD_NUMBER}-${env.GIT_COMMIT.take(8)}"
        KUBE_NAMESPACE = "finocplus-prod"
    }
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build Distroless Image') {
            steps {
                script {
                    sh """
                    docker build \
                      --no-cache \
                      -t ${DOCKER_IMAGE} \
                      -t saiteja0605/finocplus:latest \
                      .
                    """
                }
            }
        }

        stage('Push to Docker Hub') {
            steps {
                script {
              
                    withCredentials([usernamePassword(
                        credentialsId: 'docker-hub-creds',  
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )]) {
                        sh """
                        echo ${DOCKER_PASS} | docker login -u ${DOCKER_USER} --password-stdin
                        docker push ${DOCKER_IMAGE}
                        docker push saiteja0605/finocplus:latest
                        docker logout
                        """
                    }
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                script {
                    sh """
                    sed -i 's|image:.*|image: ${DOCKER_IMAGE}|g' k8s/deployment.yaml
                    kubectl apply -f k8s/deployment.yaml -n ${KUBE_NAMESPACE}
                    kubectl rollout status deployment/finocplus-deployment -n ${KUBE_NAMESPACE}
                    """
                }
            }
        }
    }
    post {
        always {
            
            sh 'docker logout || true'
            cleanWs()
        }
    }
}
