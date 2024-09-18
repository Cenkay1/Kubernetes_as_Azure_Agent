

## **Kubernetes CI/CD Agents on Azure**

**Overview**

This repository provides a comprehensive setup for using Kubernetes agents on Azure to run CI/CD pipelines. It includes configurations for KEDA-based autoscaling, Dockerfile for building your application, and Kubernetes manifests for deploying the setup.

**Key Components**

 - KEDA (Kubernetes Event-driven Autoscaling): Automatically scales the number of agents based on workload.
 - Dockerfile: Defines the build process for your application.
 - Kubernetes Manifests: Includes deployment configurations for running your CI/CD agents on Azure Kubernetes Service (AKS).

## Getting Started

**Prerequisites**

 - Azure account with AKS cluster
 - Docker installed
 - Kubernetes CLI (kubectl) installed
 - Azure CLI (az) installed

**Setup**

**Clone the Repository**

Copy Code

    git clone[ https://github.com/your-username/your-repo.git](https://github.com/Cenkay1/Kubernetes_as_Azure_Agent.git)
    cd Kubernetes_as_Azure_Agent

    
**Note**

With --addvirtualmachineresourcetags flag on agent_installation.sh you can give tag to your agent so. You can manage same agent pool for different dependency.

**Build Docker Image**

Navigate to the directory containing your Dockerfile and build the image:

    docker build -t your-image-name .

**Deploy to AKS**

Apply the Kubernetes manifests to your AKS cluster:


    kubectl apply -f keda-deployment.yml
    kubectl apply -f deployment.yml

**Configure KEDA**

Ensure KEDA is set up in your cluster for autoscaling. Refer to the KEDA documentation for detailed configuration.

**Usage**
The CI/CD agents will scale dynamically based on workload, thanks to KEDA.
Use the provided Kubernetes manifests to deploy and manage your agents.

**Contributing**
Feel free to submit issues or pull requests if you have suggestions or improvements!


This README provides a solid overview of your project and instructions for getting started. Feel free to adjust any sections to better fit your specific needs.
