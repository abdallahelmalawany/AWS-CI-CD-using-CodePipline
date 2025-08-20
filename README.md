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
                                                                   +-----------------------------+
                                                                   |       AWS CodePipeline      |
                                                                   |                             |
                                                                   |  [Source] --> [Build] --> [Deploy]
                                                                   |    |            |            |
+----------------+      +-------------+      +-----------------+   |    v            v            v
| Developer      +----->+ GitHub      +----->+ CodeBuild       +---+                         +-----------------+
| (git push)     |      | (Repository)|      | (Build &        |   |                         | CodeDeploy      |
+----------------+      +-------------+      |  Package Artifact) |   |                         | (Deploy to ASG) |
                                             +-----------------+   |                         +--------+--------+
                                                                   |                                  |
                                                                   +-----------------------------+    |
                                                                                                  |    v
                                                                                            +-----+-----------+      +-----------------+
                                                                                            |                 |      |                 |
                                                                                            | Auto Scaling    +------+ EC2 Instances   |
                                                                                            | Group (ASG)     |      | (t3.micro)      |
                                                                                            |                 |      |                 |
                                                                                            +--------+--------+      +-----------------+
                                                                                                     ^
                                                                                                     |
                                                                                            +--------+--------+
                                                                                            | Network Load   |
                                                                                            | Balancer (NLB) |
                                                                                            +--------+--------+
                                                                                                     ^
                                                                                                     |
                                                                                            +--------+--------+
                                                                                            | End User /     |
                                                                                            | Health Checks  |
                                                                                            +----------------+
