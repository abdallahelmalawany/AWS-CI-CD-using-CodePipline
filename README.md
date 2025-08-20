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
![draw](https://github.com/user-attachments/assets/24c828bd-d61f-4808-b584-b24eb1289f47)

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
<img width="1920" height="1080" alt="Screenshot (49)" src="https://github.com/user-attachments/assets/4f3a7a31-36db-4258-8b26-89fc09f93b3d" />
<img width="1920" height="1080" alt="Screenshot (45)" src="https://github.com/user-attachments/assets/d8364295-6cea-42ac-b0fa-5830db048758" />
<img width="1920" height="1080" alt="Screenshot (44)" src="https://github.com/user-attachments/assets/815d66c5-53b6-47e4-8cde-20893a72a219" />
<img width="1920" height="1080" alt="Screenshot (43)" src="https://github.com/user-attachments/assets/2bb7aae4-c24e-400d-a972-d42fc709dc36" />
<img width="1920" height="1080" alt="Screenshot (42)" src="https://github.com/user-attachments/assets/8b0ebcbc-709b-4658-8e37-642991c58a41" />
<img width="1920" height="1080" alt="Screenshot (35)" src="https://github.com/user-attachments/assets/4d3e721e-1676-4134-9a60-7b5af3c6bc19" />
<img width="1920" height="1080" alt="Screenshot (34)" src="https://github.com/user-attachments/assets/1f72e801-31a6-47f1-aec0-1e022c5a0467" />
<img width="1920" height="1080" alt="Screenshot (33)" src="https://github.com/user-attachments/assets/6ab0da98-78f9-4e7f-b51c-5265c8fea656" />
<img width="1920" height="1080" alt="Screenshot (32)" src="https://github.com/user-attachments/assets/05e4d531-58ec-4d4e-ad2d-12630c6dddbb" />
<img width="1920" height="1080" alt="Screenshot (31)" src="https://github.com/user-attachments/assets/60076d65-e3bb-4107-bc84-6cd15d7c8e78" />
<img width="1920" height="1080" alt="Screenshot (30)" src="https://github.com/user-attachments/assets/132989ae-bea1-4055-b804-657695fc9654" />
<img width="1920" height="1080" alt="Screenshot (29)" src="https://github.com/user-attachments/assets/1da7d8ae-15d2-4a1a-ba8d-e43f6775d735" />
<img width="1920" height="1080" alt="Screenshot (28)" src="https://github.com/user-attachments/assets/86301408-b615-4848-87bb-32bb577cab59" />
<img width="1920" height="1080" alt="Screenshot (27)" src="https://github.com/user-attachments/assets/10548910-ea20-4a51-bf81-97ba1f7e9652" />
<img width="1920" height="1080" alt="Screenshot (26)" src="https://github.com/user-attachments/assets/15db4b18-2efc-4f03-ba18-10d9e47a0267" />
<img width="1920" height="1080" alt="Screenshot (25)" src="https://github.com/user-attachments/assets/a4397dc8-3efa-4ca5-ba0a-ceaedf731010" />
<img width="1920" height="1080" alt="Screenshot (24)" src="https://github.com/user-attachments/assets/7080ce6a-1a08-4f3a-90a2-0a755530bb63" />
<img width="1920" height="1080" alt="Screenshot (23)" src="https://github.com/user-attachments/assets/6bebc8b4-8d19-4ec1-b193-b34a4c4f4af9" />
<img width="1920" height="1080" alt="Screenshot (22)" src="https://github.com/user-attachments/assets/a59d8ded-6a04-433f-a18d-802988765fa6" />
<img width="1920" height="1080" alt="Screenshot (21)" src="https://github.com/user-attachments/assets/f70af1a5-d5aa-475c-9b33-b8be57745e44" />
<img width="1920" height="1080" alt="Screenshot (20)" src="https://github.com/user-attachments/assets/b3a398ff-1b00-4f77-9a72-4980e31a7d30" />
<img width="1920" height="1080" alt="Screenshot (19)" src="https://github.com/user-attachments/assets/38d46b7f-c7fb-419d-b512-e4285d9bd0c5" />


