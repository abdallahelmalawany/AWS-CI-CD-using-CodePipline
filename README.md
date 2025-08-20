# AWS CI/CD Pipeline for a .NET Core Service

This project automates the deployment of a .NET Core application to an Auto Scaling Group behind a Network Load Balancer on AWS, using a full CI/CD pipeline with **GitHub** as the source, integrated with AWS CodeBuild, CodeDeploy, and CodePipeline.

## 📖 Table of Contents

- [Project Overview](#-project-overview)
- [Architecture Diagram](#-architecture-diagram)
- [Infrastructure Components](#-infrastructure-components)
- [Application](#-application)
- [CI/CD Pipeline Flow](#-cicd-pipeline-flow)
- [Prerequisites](#-prerequisites)
- [Setup & Deployment Instructions](#-setup--deployment-instructions)
- [Repository Structure](#-repository-structure)
- [Cleaning Up](#-cleaning-up)

---

## 🚀 Project Overview

The goal of this project is to demonstrate Infrastructure as Code (IaC) and CI/CD best practices on AWS. The infrastructure, including networking, security, and compute resources, is provisioned using AWS CLI bash scripts. A simple .NET Core web service is automatically built, tested, and deployed whenever changes are pushed to the main branch of the **GitHub** repository.

---

## 📐 Architecture Diagram

The following diagram illustrates the deployed infrastructure and CI/CD workflow:

```mermaid
flowchart LR
    Developer[Developer<br>git push] --> |1| GitHub[GitHub Repository]

    subgraph AWS_Pipeline [AWS CodePipeline]
        Source[Source] --> Build[Build] --> Deploy[Deploy]
    end

    GitHub --> |2 Triggers| Source

    Build --> |3| CodeBuild[CodeBuild<br>Build & Package Artifact]
    Deploy --> |4| CodeDeploy[CodeDeploy<br>Deploy to ASG]

    CodeDeploy --> |5| ASG_Group

    subgraph ASG_Group [Auto Scaling Group]
        Instance1[EC2 Instance<br>t3.micro]
        Instance2[EC2 Instance<br>t3.micro]
    end

    User[End User] --> |6 Traffic| NLB[Network Load Balancer<br>NLB]
    NLB --> |7| ASG_Group

    Health[Health Checks] --> |8| ASG_Group

🏗️ Infrastructure Components

The bash scripts in this repo (vpc.sh, security.sh, autoscalinggroup.sh) create the following core AWS resources:

    Networking (vpc.sh):

        VPC: A virtual network with a defined CIDR block (e.g., 10.0.0.0/16).

        Subnets: Public subnets (for load balancers) and private subnets (for data services) across two Availability Zones for high availability.

        Internet Gateway (IGW): Allows resources in public subnets to connect to the internet.

        Route Tables: Public and private route tables to control traffic flow.

    Security (security.sh):

        EC2 Key Pair: An SSH key pair for EC2 instance access, securely stored in AWS Secrets Manager.

        Security Group: A firewall for EC2 instances with rules allowing:

            SSH access (port 22) from anywhere (for initial troubleshooting).

            All traffic between instances in the same security group (for internal communication).

    Compute & Scaling (autoscalinggroup.sh):

        Launch Template: Defines the blueprint for EC2 instances:

            AMI: Latest Ubuntu 22.04

            Instance Type: t3.micro

            IAM Role: ec2_service_role (with permissions for S3 and CodeDeploy)

            Security Group: The one created above.

            User Data: A script (build.sh) that bootstraps instances by installing the .NET 6 runtime and the CodeDeploy agent.

        Auto Scaling Group (ASG):

            Name: [env]-srv02-asg (e.g., qc-srv02-asg)

            Size: Min 2, Desired 2, Max 7 instances.

            Uses the Launch Template and spreads instances across public subnets.

            Configured with a Target Tracking Scaling Policy to scale based on CPU utilization (target 50%).

        Load Balancer:

            A Network Load Balancer (NLB) to distribute traffic across the healthy instances in the ASG.

            A Target Group is created for the instances, listening on port 8002.

    IAM Roles:

        ec2_service_role: Attached to EC2 instances. Grants read-only access to S3 and permissions to work with CodeDeploy.

        codedeploy_service_role: Used by the CodeDeploy service to deploy applications to EC2 instances. Created manually via script.

📦 Application

The application is a simple .NET 6 web service (main.cs) that:

    Listens for HTTP requests on port 8002.

    Returns a random AWS S3 "fact" with each request.

    Is packaged and deployed as a self-contained release.

🔄 CI/CD Pipeline Flow

The pipeline is defined in the AWS CodePipeline console and is triggered automatically.

    Source Stage (GitHub):

        The pipeline is connected to your GitHub repository using a secure OAuth connection in AWS.

        It monitors a specified branch (e.g., main).

        When a developer pushes new code, GitHub notifies AWS CodePipeline, which automatically starts the pipeline.

    Build Stage (CodeBuild):

        CodeBuild uses the buildspec.yml file as its build instructions.

        It restores dependencies, compiles the .NET code, and publishes the application.

        It packages the published code, along with the appspec.yml and deployment scripts, into a zip artifact and stores it in an S3 bucket.

    Deploy Stage (CodeDeploy):

        CodeDeploy takes the build artifact from S3 and deploys it to the instances in the Auto Scaling Group.

        It uses the appspec.yml file to define the deployment lifecycle hooks:

            BeforeInstall: (e.g., before_install.sh) - Steps to run before installation.

            AfterInstall: (after_install.sh) - Creates a systemd service file to manage the application and enables it.

            ApplicationStart: (start.sh) - Starts the service via systemctl.

            ApplicationStop: (stop.sh) - Stops the service during deployment.

✅ Prerequisites

Before deploying, ensure you have the following:

    AWS Account: With appropriate permissions to create the resources listed above.

    AWS CLI: Installed and configured on your local machine (aws configure).

    Git: To clone and push code.

    GitHub Repository: A repository to hold this code.

    IAM Roles: The codedeploy_service_role must be created manually. The EC2 role will be created by the scripts.

🛠️ Setup & Deployment Instructions
1. Clone and Prepare the Repository
bash

git clone <your-github-repo-url>
cd <repo-name>
# Copy all the project files into this directory
git add .
git commit -m "Initial commit with all project files"
git push origin main

2. Create the IAM Role for CodeDeploy

    Go to the IAM console in AWS.

    Create a new role for CodeDeploy.

    Attach the managed policies AmazonS3ReadOnlyAccess and AWSCodeDeployRole.

    Name the role codedeploy_service_role.

3. Deploy the Infrastructure

The deploy.sh script is the main entry point. It sources environment-specific configuration and runs the other scripts.
bash

# Make the scripts executable
chmod +x *.sh

# Deploy to the QC (Quality Control) environment
./deploy.sh qc

# Later, deploy to Production
# ./deploy.sh prod

This script will sequentially create:

    The VPC and all networking components.

    The EC2 Key Pair and Security Group.

    The Launch Template, Load Balancer, and Auto Scaling Group.

4. Create the CI/CD Pipeline on AWS

    Open the AWS CodePipeline console.

    Click Create pipeline.

    Step 1: Pipeline settings

        Pipeline name: e.g., srv02-pipeline

    Step 2: Source stage

        Source provider: GitHub (Version 2)

        Connect to GitHub: Follow the prompts to authenticate and connect your AWS account to your GitHub account.

        Select your repository and the branch (e.g., main).

    Step 3: Build stage

        Build provider: AWS CodeBuild

        Create a new project.

        Environment image: Managed Image, Ubuntu, Standard, aws/codebuild/standard:7.0

        Service role: Let CodeBuild create a new role for you.

        Buildspec: Use a buildspec file (it will use the buildspec.yml in your repo root).

    Step 4: Deploy stage

        Deploy provider: AWS CodeDeploy

        Application name: Create a new one, e.g., srv02-app

        Deployment group: Create a new one.

        Deployment type: In-place

        Environment configuration: Amazon EC2 Auto Scaling group

        Select the Auto Scaling group created by the script (e.g., qc-srv02-asg).

        Service role: Select the codedeploy_service_role you created earlier.

    Review and create the pipeline. The first execution will start automatically.

📁 Repository Structure
text

├── deploy.sh                 # Main deployment script
├── conf-qc.sh               # Configuration for QC environment
├── conf-prod.sh             # Configuration for Production environment
├── vpc.sh                   # Script to create VPC, subnets, IGW, etc.
├── security.sh              # Script to create Key Pair, Secret, Security Group
├── autoscalinggroup.sh      # Script to create LT, NLB, ASG
├── dns.sh                   # (Optional) Script to create Route53 records
├── build.sh                 # User Data script for EC2 instances
├── lt.json                  # Launch Template JSON definition
│
├── buildspec.yml            # CodeBuild build instructions
├── appspec.yml              # CodeDeploy deployment instructions
│
├── srv02.csproj             # .NET Core project file
├── main.cs                  # .NET Core application source code
│
└── scripts/                 # CodeDeploy lifecycle hooks
    ├── after_install.sh
    ├── before_install.sh
    ├── start.sh
    └── stop.sh

🧹 Cleaning Up

To avoid ongoing costs, remember to delete all AWS resources created by this project:

    Empty and Delete the S3 Bucket created by CodePipeline/CodeBuild.

    Delete the CodePipeline and the CodeBuild project.

    Delete the CodeDeploy Application and Deployment Group.

    Delete the Auto Scaling Group (this will terminate all EC2 instances).

    Delete the Load Balancer and Target Group.

    Delete the Launch Template.

    Run the scripts in reverse order with delete commands or manually delete via the AWS console:

        EC2 Instances, Security Groups, VPC (this will delete subnets, IGW, etc.)

        IAM Roles and Policies

        Secrets from Secrets Manager

        EC2 Key Pairs

Warning: The scripts provided primarily handle creation. You may need to write corresponding deletion scripts or delete these resources manually through the AWS Management Console.
