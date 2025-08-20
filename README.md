AWS CI/CD Pipeline for a .NET Core Service

This project automates the deployment of a .NET Core application to an Auto Scaling Group behind a Network Load Balancer on AWS, using a full CI/CD pipeline with GitHub as the source, integrated with AWS CodeBuild, CodeDeploy, and CodePipeline.
📖 Table of Contents

    Project Overview

    Architecture Diagram

    Infrastructure Components

    Application

    CI/CD Pipeline Flow

    Prerequisites

    Setup & Deployment Instructions

    Repository Structure

    Cleaning Up
                                                                  
🚀 Project Overview

The goal of this project is to demonstrate Infrastructure as Code (IaC) and CI/CD best practices on AWS. The infrastructure, including networking, security, and compute resources, is provisioned using AWS CLI bash scripts. A simple .NET Core web service is automatically built, tested, and deployed whenever changes are pushed to the main branch of the GitHub repository.

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
```
