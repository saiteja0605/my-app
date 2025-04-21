CI/CD Pipeline with Jenkins, GitHub, Docker, and Kubernetes

This repository outlines the procedure for setting up a Continuous Integration and Continuous Deployment (CI/CD) pipeline using GitHub, Jenkins, Docker, and Kubernetes (K8s). The goal is to automate the process of building artifacts whenever code is committed to specific Git repositories and deploying them to designated Kubernetes clusters.

🚀 Overview

The CI/CD pipeline automates the following tasks:

Triggering a build: The pipeline initiates automatically when code is pushed to the main branch of the GitHub repository.

Building a Docker image: A Docker image of the application is built.

Pushing to Docker Hub: The newly built Docker image is pushed to Docker Hub.

Deploying to Kubernetes: The application image is deployed to a Kubernetes cluster.

✅ Prerequisites

1. Infrastructure
   
EC2 instance or any Linux-based server.
Kubernetes cluster (this can be a single-node cluster for testing purposes).
Jenkins installed and running on the server.

2. Tools & Packages
   
Docker installed and running on the Jenkins server.
kubectl installed and configured on the Jenkins server.
kubeconfig file for your Kubernetes cluster.

3. External Services
   
GitHub: Git repository with the source code and Kubernetes manifests.
Docker Hub: For pushing and hosting built Docker images.

4. Jenkins Plugins
   
Git Plugin
Pipeline Plugin
Credentials Binding Plugin
docker plugin

Based on your requirements, I have set up the necessary repositories, including Docker Hub, GitHub, and the cloud platform (AWS in this case, though GCP or Azure could also be used).

🛠️ Infrastructure Setup

EC2 Setup:

I created EC2 instances in AWS and installed the required prerequisites: Jenkins, Git, Kubernetes, Docker, and kubectl.

Directory Structure:

Locally, I created a directory called my-app that includes:

my-app/
│
├── k8s/
│   ├── deployment.yaml
│   ├── service.yaml
│
├── src/
│   ├── app.js
│   ├── package.json
│
├── Dockerfile
├── Jenkinsfile


Kubernetes manifests (deployment.yaml, service.yaml).

Source code (app.js, package.json).

Dockerfile for building the image.

Jenkinsfile for CI/CD integration.

Dockerfile

    # Stage 1 - Builder
    FROM node:16 AS builder
    WORKDIR /app
    
    # Copy package.json from src/
    COPY src/package*.json ./src/
    
    # Install dependencies inside the src directory
    RUN cd src && npm install --omit=dev
    
    # Copy the rest of the app
    COPY . .
    
    # Stage 2 - Final image
    FROM gcr.io/distroless/nodejs:16
    WORKDIR /app
    
    COPY --from=builder /app .
    
    CMD ["src/app.js"]  # Replace with your actual entry point
    Base Image: The base image is the official Node.js image based on Debian with Node.js v16 installed.

Once the Dockerfile is ready, I built the Docker image using:

Building and Pushing the Docker Image
docker build -t <docker_image_name:tag> .

List the image:
docker images

Login and push to Docker Hub:
docker login
docker tag <docker_image_name:tag> saiteja0605/finocplus:latest
docker push saiteja0605/finocplus:latest

Kubernetes Setup
For the Kubernetes setup, I opted for a manual cluster creation for cost optimization. However, we can also use Amazon EKS, GKE, or other managed Kubernetes services. And the resource allocation to the clusters can be modified and negotiated based on the requirements like cpu, memory, type of cluster, node pools etc.

The following manifests were written in the working directory:

deployment.yaml 

    apiVersion: apps/v1
      kind: Deployment                    # Defines a Deployment resource
      metadata:
        name: finocplus-deployment        # Name of the deployment
        labels:
          app: finocplus                  # Label for identifying the app
    
    spec:
      replicas: 2                         # Run 2 replicas (pods) of the application
      strategy:
        rollingUpdate:
          maxSurge: 1                     # Allow 1 extra pod during update
          maxUnavailable: 0               # Ensure no downtime during rollout
      selector:
        matchLabels:
          app: finocplus                  # Match pods with this label
    
      template:
        metadata:
          labels:
        app: finocplus                    # Pod label for selector match
    spec:
      containers:
      - name: finocplus                   # Name of the container
        image: saiteja0605/finocplus:latest  # Docker image used in container
        ports:
        - containerPort: 8080             # Container listens on port 8080
        env:
        - name: NODE_ENV
          value: production               # Sets environment variable for Node.js

        resources:
          limits:
            cpu: "500m"                   # Maximum CPU the container can use
            memory: "512Mi"               # Maximum memory
          requests:
            cpu: "100m"                   # Guaranteed minimum CPU
            memory: "256Mi"               # Guaranteed minimum memory

        livenessProbe:
          httpGet:
            path: /                      # Endpoint checked to verify the app is alive
            port: 8080
          initialDelaySeconds: 30        # Wait 30s before starting liveness checks
          periodSeconds: 10              # Check every 10s

        readinessProbe:
          httpGet:
            path: /                     # Endpoint checked to verify app is ready
            port: 8080
          initialDelaySeconds: 5        # Start checking after 5s
          periodSeconds: 5              # Check every 5s

      securityContext:
        runAsNonRoot: true              # Ensures the container does not run as root
        runAsUser: 1000                 # Runs as user with UID 1000 (non-root)

 
service.yaml

    apiVersion: v1
    kind: Service              # Defines a Service resource
    metadata:
      name: finocplus-service  # Name of the service
    
    spec:
      selector:
        app: finocplus        # Selects pods with this label (must match the Deployment)
    
      ports:
        - protocol: TCP       # Uses TCP protocol for communication
          port: 80            # Exposes service on port 80 (accessible externally)
          targetPort: 8080    # Forwards traffic to container's port 8080
    
      type: LoadBalancer      # Exposes service via a cloud provider load balancer
                              # (used in AWS/GCP to get an external IP)


Jenkins Setup

Install required Jenkins plugins: Git, Docker, Kubernetes CLI, Pipeline.

Add the kubeconfig file manually in Jenkins from the Kubernetes master node by copying it.

Add credentials for Docker Hub, GitHub, and kubeconfig file in Jenkins (Manage Jenkins → Credentials → Global → Add credentials).

Create a new Jenkins pipeline and integrate it with the GitHub repository and Jenkinsfile.

Set up a pipeline to trigger on every Git commit, build the Docker image, push it to Docker Hub, and deploy it to the Kubernetes cluster.

Jenkinsfile

    pipeline {
        agent any
        environment {
            # Define Docker image tag using build number and short Git commit
            DOCKER_IMAGE = "saiteja0605/finocplus:build-${env.BUILD_NUMBER}-${env.GIT_COMMIT.take(8)}"
            
            # Target Kubernetes namespace
            KUBE_NAMESPACE = "finocplus-prod"
            
            # Explicitly set PATH to avoid command not found issues
            PATH = "/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:${env.PATH}"
        }
    
        stages {
            stage('Checkout') {
                steps {
                    cleanWs()  # Clean previous workspace to ensure a fresh build
                    checkout([
                        $class: 'GitSCM',
                        branches: [[name: '*/main']],  # Checkout the 'main' branch
                        userRemoteConfigs: [[
                            url: 'https://github.com/saiteja0605/my-app.git'  # Clone from GitHub
                        ]]
                    ])
                }
            }
    
            stage('Verify Docker Access') {
                steps {
                    script {
                        sh '''
                        echo "Running as user: $(whoami)"  # Check Jenkins user
                        echo "PATH: $PATH"  # Debug PATH variable
                        echo "Docker binary location: $(which docker)"  # Ensure docker is installed
                        docker info || { echo 'Docker is not accessible'; exit 1; }  # Confirm Docker access
                        '''
                    }
                }
            }
    
            stage('Build Distroless Image') {
                steps {
                    script {
                        sh """
                        docker build \\
                          --no-cache \\  # Ensure clean image build with no caching
                          -t ${DOCKER_IMAGE} \\  # Tag with version
                          -t saiteja0605/finocplus:latest \\  # Also tag as latest
                          . || { echo 'Docker build failed'; exit 1; }
                        """
                    }
                }
            }
    
            stage('Push to Docker Hub') {
                steps {
                    script {
                        withCredentials([usernamePassword(
                            credentialsId: 'docker-hub-creds',  # Jenkins stored DockerHub credentials
                            usernameVariable: 'DOCKER_USER',
                            passwordVariable: 'DOCKER_PASS'
                        )]) {
                            sh """
                            echo ${DOCKER_PASS} | docker login -u ${DOCKER_USER} --password-stdin || { echo 'Docker login failed'; exit 1; }
                            docker push ${DOCKER_IMAGE} || { echo 'Push failed for versioned tag'; exit 1; }  # Push versioned tag
                            docker push saiteja0605/finocplus:latest || { echo 'Push failed for latest tag'; exit 1; }  # Push latest tag
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
                            # Replace the image tag in the deployment manifest
                            sed -i 's|image:.*|image: ${DOCKER_IMAGE}|g' k8s/deployment_*



Now push the my app directory to the github repository and confirm that the jenkins pipeline is triggered and deployment is working.


Conclusion:

Once the setup is complete, any commit to the GitHub repository's main branch will trigger the pipeline in Jenkins. The pipeline will:

Build the Docker image.

Push the image to Docker Hub.

Deploy the image to the Kubernetes cluster using kubectl.

By pushing the my-app directory to GitHub, we can set up the automated CI/CD pipeline, and Jenkins will run the pipeline and autoamtes the deployments.

🔧 Tools for Monitoring & Alerting (CI/CD + Kubernetes Setup)

1. CPU & Memory Monitoring (Kubernetes Cluster)

Tool:

Prometheus (for metrics collection)

Grafana (for visualization)

Setup Steps:

Install using Helm:

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts

helm install monitoring prometheus-community/kube-prometheus-stack

Access Grafana UI:

kubectl port-forward svc/monitoring-grafana 3000:80 -n default

Login to Grafana (admin/admin by default) and import Kubernetes dashboards.

Set alerts in Grafana (e.g., when CPU > 80%, memory > 75%).

2. CI/CD Failure Monitoring (Jenkins Pipeline Failures)
Tool:

Jenkins Email/Slack Plugin

Prometheus + Grafana (optional)

Setup Steps:

Install Jenkins plugins:

Email Extension Plugin

Slack Notification Plugin

Configure email or Slack under: Manage Jenkins → Configure System

Add this to your Jenkinsfile for email/slack:

post {
    failure {
        mail to: 'team@example.com',
             subject: "Build Failed: ${env.JOB_NAME}",
             body: "Check Jenkins for details."
    }
}

3. Application Failure Monitoring (Node.js App)
Tool:

Liveness & Readiness Probes (already set up in deployment.yaml)

Prometheus + Grafana (for custom app metrics, optional)

kubectl get pods (to check crash loops)

Setup Steps:

our current Kubernetes deployment already uses livenessProbe and readinessProbe, which restart the app if it becomes unresponsive.

For extra monitoring, expose metrics with prom-client in our Node.js app and let Prometheus scrape it.

4. Alerting
   
Tool:

Grafana Alerts or Prometheus Alertmanager

Setup Steps:

In Grafana:

Go to any panel → Click Alert → Create alert rule.

Set condition like:

CPU usage > 80% for 5m

Container restarts > 3

Add notification channel (Slack, Email, etc.)
