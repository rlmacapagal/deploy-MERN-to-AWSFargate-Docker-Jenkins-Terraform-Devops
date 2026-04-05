# Deploy MERN Stack to AWS ECS Fargate using Terraform and Jenkins

⬇️⬇️⬇️⬇️⬇️⬇️⬇️⬇️⬇️⬇️⬇️⬇️

**Original Article:** https://medium.com/@mericac33/deploy-mern-stack-to-aws-fargate-using-terraform-and-jenkins-77b23a5803f9

<img width="627" alt="Photot" src="https://github.com/mericalp/Deploy-AWS-ECS-Fargate-using-Terraform-and-Jenkins/assets/83503845/7a0511d0-b627-41ab-9dcf-0f46d3fecff7">

## 📋 Complete Step-by-Step Deployment Guide

This comprehensive guide includes **ALL** the steps needed for a successful deployment, including critical steps missing from the original article.

### 🔧 Prerequisites

- AWS Account with appropriate billing setup
- Docker installed locally
- Basic knowledge of AWS services (ECS, VPC, ALB)
- Git repository for your code

---

## 🚀 Phase 1: AWS Account Setup

### Step 1: Create IAM User for Jenkins

1. **Login to AWS Console** → Navigate to **IAM**
2. **Users** → **Create User**
3. **Username:** `jenkins-user`
4. **Access type:** Programmatic access
5. **Attach policies directly:**
   - `AmazonECS_FullAccess`
   - `AmazonEC2FullAccess`
   - `ElasticLoadBalancingFullAccess`
   - `IAMFullAccess`
   - `CloudWatchLogsFullAccess`
6. **Download credentials** (Access Key ID and Secret)
7. **Save credentials securely** - you'll need them later

### Step 2: Create Docker Hub Account

1. Sign up at https://hub.docker.com
2. **Create repository:** `your-username/mern-stack`
3. **Generate access token:** Account Settings → Security → New Access Token
4. **Save token** - you'll need it for Jenkins

---

## 🐳 Phase 2: Local Development Setup

### Step 3: Fix Application Configuration

#### Update Server Port Configuration

```javascript
// mern-todo-main/server.js - Fix port mismatch
const PORT = process.env.PORT || 3000; // Changed from 5001
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});

// Add health check endpoint (CRITICAL for ALB)
app.get("/", (req, res) => {
  res.json({
    status: "OK",
    message: "MERN Todo API is running",
    timestamp: new Date().toISOString(),
  });
});
```

#### Update React API Configuration

```javascript
// mern-todo-main/client/src/App.js - Fix API base URL
const api_base = process.env.REACT_APP_API_BASE || window.location.origin;
```

#### Create Production Dockerfile

```dockerfile
FROM --platform=linux/amd64 node:16-alpine

WORKDIR /app

COPY mern-todo-main/package*.json ./
COPY mern-todo-main/client/package*.json ./client/

RUN npm install --only=production
RUN cd client && npm install --only=production

COPY mern-todo-main/ ./

# Build React app for production
RUN cd client && npm run build

RUN addgroup -g 1001 -S nodejs && adduser -S nodejs -u 1001
RUN chown -R nodejs:nodejs /app
USER nodejs

EXPOSE 3000

ENV NODE_ENV=production
ENV PORT=3000

CMD ["npm", "start"]
```

### Step 4: Fix Terraform Configuration

#### Remove AWS Profile from Provider

```terraform
// tf/provider.tf - Remove profile reference
provider "aws" {
  region = var.aws_region
}
```

#### Update ECS Task Template

```json
// tf/templates/ecs/myapp.json.tpl - Add environment variables
[
  {
    "name": "myapp",
    "image": "${app_image}",
    "cpu": ${fargate_cpu},
    "memory": ${fargate_memory},
    "networkMode": "awsvpc",
    "environment": [
      {
        "name": "NODE_ENV",
        "value": "production"
      },
      {
        "name": "PORT",
        "value": "3000"
      }
    ],
    "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/myapp",
          "awslogs-region": "${aws_region}",
          "awslogs-stream-prefix": "ecs"
        }
    },
    "portMappings": [
      {
        "containerPort": ${app_port},
        "hostPort": ${app_port}
      }
    ]
  }
]
```

---

## 🔨 Phase 3: Jenkins Setup

### Step 5: Install and Configure Jenkins

```bash
# Create Jenkins container with Docker access
docker run -d \
  --name jenkins \
  -p 8080:8080 \
  -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  jenkins/jenkins:lts

# Get initial admin password
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

### Step 6: Configure Jenkins Credentials

1. **Access Jenkins:** http://localhost:8080
2. **Complete initial setup** with admin password
3. **Install suggested plugins**
4. **Manage Jenkins** → **Manage Credentials** → **System** → **Global credentials**

#### Add Docker Hub Credentials

- **Kind:** Username with password
- **ID:** `docker-hub-token`
- **Username:** Your Docker Hub username
- **Password:** Your Docker Hub access token

### Step 7: Configure AWS CLI in Jenkins Container

```bash
# Access Jenkins container as root
docker exec -u root -it jenkins bash

# Install AWS CLI (if not present)
apt-get update && apt-get install -y awscli

# Switch to jenkins user
su - jenkins

# Configure AWS credentials
aws configure
# Enter your AWS Access Key ID
# Enter your AWS Secret Access Key
# Enter region: ap-southeast-1 (or your preferred region)
# Enter output format: json

# Test configuration
aws sts get-caller-identity
```

---

## 🚀 Phase 4: Pipeline Setup

### Step 8: Create Jenkins Pipeline

1. **New Item** → **Pipeline**
2. **Pipeline name:** `mern-pipeline`
3. **Pipeline definition:** Pipeline script from SCM
4. **SCM:** Git
5. **Repository URL:** Your GitHub repository URL
6. **Branch:** `*/main`
7. **Script Path:** `Jenkinsfile`

### Step 9: Verify Jenkinsfile

```groovy
// Jenkinsfile - Ensure this matches your setup
pipeline {
    agent any
    environment {
        DOCKER_HUB_CREDENTIALS = credentials('docker-hub-token')
        DOCKER_HUB_IMAGE_NAME = 'your-username/mern-stack'
        IMAGE_TAG = "v${env.BUILD_NUMBER}"
    }

    stages {
        stage('Checking Docker version') {
            steps {
                sh 'docker -v'
            }
        }

        stage('Login to Docker Hub') {
            steps {
                sh 'echo $DOCKER_HUB_CREDENTIALS_PSW | docker login -u $DOCKER_HUB_CREDENTIALS_USR --password-stdin'
                echo 'Login Completed'
            }
        }

        stage('Build and Push to Docker Hub') {
            steps {
                sh "docker build -t ${DOCKER_HUB_IMAGE_NAME}:latest ."
                sh "docker tag ${DOCKER_HUB_IMAGE_NAME}:latest ${DOCKER_HUB_IMAGE_NAME}:lts"
                sh "docker push ${DOCKER_HUB_IMAGE_NAME}:lts"
            }
        }

        stage('Terraform Init') {
            steps {
                dir('tf') {
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

    post {
        always {
            sh 'docker logout'
        }
    }
}
```

---

## 🎯 Phase 5: Deployment & Testing

### Step 10: Run the Pipeline

1. **Go to your pipeline** → **Build Now**
2. **Monitor the build** in real-time
3. **Check each stage** for successful completion

### Step 11: Access Your Application

1. **Get ALB DNS name** from Terraform output or AWS Console:
   - AWS Console → EC2 → Load Balancers
   - Find "myapp-load-balancer"
   - Copy DNS name

2. **Access your application:**
   ```
   http://your-alb-dns-name.ap-southeast-1.elb.amazonaws.com
   ```

### Step 12: Verify Deployment

1. **Check ECS Service:**
   - AWS Console → ECS → Clusters → myapp-cluster
   - Verify tasks are running and healthy

2. **Check ALB Target Health:**
   - AWS Console → EC2 → Target Groups → myapp-target-group
   - Verify targets are healthy

3. **Check Application Logs:**
   - AWS Console → CloudWatch → Log groups → /ecs/myapp

---

## 🔧 Troubleshooting Guide

### Common Issues & Solutions

#### 1. **AWS Credentials Error**

```
Error: failed to get shared config profile, default
```

**Solution:** Run `aws configure` in Jenkins container

#### 2. **Insufficient Permissions**

```
User is not authorized to perform: ec2:DescribeAvailabilityZones
```

**Solution:** Add required IAM policies to jenkins-user

#### 3. **Health Check Failures**

**Solution:** Ensure your app responds to GET `/` with HTTP 200

#### 4. **Port Mismatch Issues**

**Solution:** Verify server runs on port 3000, not 5001

#### 5. **Docker Build Failures**

**Solution:** Check Dockerfile syntax and dependencies

---

## 🎯 Success Checklist

- [ ] AWS IAM user created with proper permissions
- [ ] Docker Hub credentials configured in Jenkins
- [ ] AWS CLI configured in Jenkins container
- [ ] Application port fixed to 3000
- [ ] Health check endpoint added
- [ ] Production Dockerfile created
- [ ] Terraform provider.tf fixed
- [ ] Jenkins pipeline created and successful
- [ ] ECS service running and healthy
- [ ] Application accessible via ALB DNS

---

## 📈 What Gets Deployed

### AWS Infrastructure:

- **VPC** with public/private subnets across 2 AZs
- **Application Load Balancer** (ALB)
- **ECS Fargate Cluster** and Service
- **CloudWatch** logs and monitoring
- **Security Groups** with proper access rules
- **IAM Roles** for ECS task execution

### Application Stack:

- **React Frontend** (built and served statically)
- **Node.js/Express Backend** (API server)
- **Health check endpoint** (for ALB monitoring)
- **Docker containerized** deployment

---

## ⚠️ Important Notes

1. **Security:** The IAM permissions used are broad for simplicity. In production, use least-privilege principle.

2. **Database:** This setup doesn't include a database. You'll need to:
   - Enable DocumentDB in terraform files, OR
   - Use MongoDB Atlas, OR
   - Add RDS PostgreSQL/MySQL

3. **Domain:** The application is accessible via ALB DNS. For production, add:
   - Route 53 for custom domain
   - ACM certificate for HTTPS

4. **Monitoring:** Basic CloudWatch logging is included. Consider adding:
   - Application Performance Monitoring (APM)
   - Custom metrics and alarms
   - Log aggregation tools

---

## 🎉 Congratulations!

You've successfully deployed a MERN stack application to AWS ECS Fargate using Terraform and Jenkins! Your application is now running in a production-ready containerized environment with automatic scaling, load balancing, and monitoring.

---

## 🔗 Useful Links

- [Original Article](https://medium.com/@mericac33/deploy-mern-stack-to-aws-fargate-using-terraform-and-jenkins-77b23a5803f9)
- [AWS ECS Documentation](https://docs.aws.amazon.com/ecs/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Jenkins Pipeline Documentation](https://www.jenkins.io/doc/book/pipeline/)

---

**Need help?** Open an issue in this repository with your error logs and specific questions.
