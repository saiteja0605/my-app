pipeline {
    agent any
    environment {
        DOCKER_IMAGE = "saiteja0605/finocplus:build-${env.BUILD_NUMBER}-${env.GIT_COMMIT.take(8)}"
        KUBE_NAMESPACE = "finocplus-prod"
        PATH = "/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:${env.PATH}"  // Explicitly ensure /bin is included
    }
    stages {
        stage('Checkout') {
            steps {
                cleanWs()
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: '*/main']],
                    userRemoteConfigs: [[
                        url: 'https://github.com/saiteja0605/my-app.git'
                    ]]
                ])
            }
        }

        stage('Verify Docker Access') {
            steps {
                script {
                    sh '''
                    echo "Running as user: $(whoami)"
                    echo "PATH: $PATH"
                    echo "Docker binary location: $(which docker)"
                    docker info || { echo 'Docker is not accessible'; exit 1; }
                    '''
                }
            }
        }

        stage('Build Distroless Image') {
            steps {
                script {
                    sh """
                    docker build \\
                      --no-cache \\
                      -t ${DOCKER_IMAGE} \\
                      -t saiteja0605/finocplus:latest \\
                      . || { echo 'Docker build failed'; exit 1; }
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
                        echo ${DOCKER_PASS} | docker login -u ${DOCKER_USER} --password-stdin || { echo 'Docker login failed'; exit 1; }
                        docker push ${DOCKER_IMAGE} || { echo 'Push failed for versioned tag'; exit 1; }
                        docker push saiteja0605/finocplus:latest || { echo 'Push failed for latest tag'; exit 1; }
                        """
                    }
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                script {
                    withCredentials([file(credentialsId: 'kubeconfig-prod', variable: 'KUBECONFIG')]) {
                        sh """
                        # Replace the image tag in the deployment YAML with the newly built image
                        sed -i 's|image:.*|image: ${DOCKER_IMAGE}|g' k8s/deployment.yaml || { echo 'Image tag replacement failed'; exit 1; }

                        echo "--- DEBUG: kubeconfig and cluster info ---"
                        kubectl config view
                        kubectl cluster-info || { echo 'Cluster unreachable'; exit 1; }

                        # Apply the updated deployment YAML
                        kubectl apply -f k8s/deployment.yaml -n ${KUBE_NAMESPACE} || { echo 'kubectl apply failed'; exit 1; }

                        # Wait for the deployment to complete with an increased timeout
                        kubectl rollout status deployment/finocplus-deployment -n ${KUBE_NAMESPACE} --timeout=300s || {
                            echo 'Rollout failed, rolling back deployment';
                            kubectl rollout undo deployment/finocplus-deployment -n ${KUBE_NAMESPACE} || { echo 'Rollback failed'; exit 1; }
                        }
                        """
                    }
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
