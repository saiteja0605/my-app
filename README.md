CI/CD Pipeline with Jenkins, GitHub, Docker, and Kubernetes

This repository outlines the setup of a Continuous Integration and Continuous Deployment (CI/CD) pipeline using GitHub, Jenkins, Docker, and Kubernetes (K8s).

🚀 Overview

This CI/CD pipeline automatically:

Triggers a build when code is pushed to the GitHub main branch

Builds a Docker image of the application

Pushes the Docker image to Docker Hub

Deploys the image to a Kubernetes cluster

✅ Prerequisites

1. Infrastructure

EC2 instance or any Linux-based server

Kubernetes cluster (can be a single-node cluster for testing)

Jenkins installed and running on a server

2. Tools & Packages

Docker installed and running on the Jenkins server

kubectl installed and configured on the Jenkins server

kubeconfig file for your Kubernetes cluster

3. External Services

GitHub: Git repository with source code and Kubernetes manifests

Docker Hub: To push and host built images

4. Jenkins Plugins

Git Plugin

Pipeline Plugin

Credentials Binding Plugin

