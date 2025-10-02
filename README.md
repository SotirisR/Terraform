# Django + S3 Terraform Infrastructure

This Terraform configuration deploys a highly available Django application on AWS with the following architecture:

## Architecture Overview

- **Frontend**: React/Vue.js hosted on S3 with CloudFront CDN
- **Backend**: Django application running on EC2 instances behind an Application Load Balancer
- **Database**: PostgreSQL on RDS with encrypted storage
- **Networking**: VPC with public/private subnets across 2 availability zones
- **Security**: Security groups, IAM roles, and Secrets Manager for database credentials

## Infrastructure Components

### Networking
- VPC with public and private subnets across 2 AZs
- Internet Gateway for public subnet internet access
- NAT Gateways for private subnet internet access
- Route tables and associations

### Frontend (S3 + CloudFront)
- S3 bucket with versioning and encryption
- CloudFront distribution with Origin Access Control
- Custom error pages for SPA routing

### Backend (EC2 + Auto Scaling)
- Auto Scaling Group with configurable capacity
- Launch template with Ubuntu 22.04 AMI
- Application Load Balancer with health checks
- Security groups with least privilege access

### Database (RDS PostgreSQL)
- PostgreSQL 15.4 with encryption at rest
- Multi-AZ deployment option
- Automated backups and maintenance windows
- Enhanced monitoring and Performance Insights

### Security
- IAM roles and policies with minimal permissions
- Secrets Manager for database password management
- Security groups restricting access between tiers
- Encrypted storage for S3 and RDS

## Prerequisites

1. **AWS CLI configured** with appropriate permissions
2. **Terraform >= 1.0** installed
3. **AWS Key Pair** (optional, for SSH access to EC2 instances)

## Deployment Instructions

### 1. Clone and Configure

```bash
git clone <repository-url>
cd terraform-django-infrastructure
```

### 2. Set Variables

Copy the example variables file and customize:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your specific values:

```hcl
aws_region   = "eu-central-1"
environment  = "dev"
project_name = "my-django-app"
domain_name  = "mydomain.com"
key_pair_name = "my-key-pair"  # Optional
```

### 3. Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Plan the deployment
terraform plan

# Apply the configuration
terraform apply
```

### 4. Post-Deployment Setup

After deployment, you'll need to:

1. **Update Django Settings**: Configure your Django application with the database endpoint and credentials
2. **Deploy Application Code**: Upload your Django code to EC2 instances or create a custom AMI
3. **Upload Frontend Files**: Upload your React/Vue.js build files to the S3 bucket
4. **Configure DNS**: Update your domain's nameservers to point to the Route53 hosted zone

## Configuration Options

### Environment Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `aws_region` | AWS region for deployment | `eu-central-1` | No |
| `environment` | Environment name (dev/staging/prod) | `dev` | No |
| `project_name` | Project name for resource naming | `django-app` | No |
| `domain_name` | Domain name for the application | `example.com` | No |
| `key_pair_name` | AWS Key Pair for EC2 SSH access | `""` | No |
| `instance_type` | EC2 instance type | `t3.micro` | No |
| `min_capacity` | ASG minimum instances | `1` | No |
| `max_capacity` | ASG maximum instances | `3` | No |
| `desired_capacity` | ASG desired instances | `2` | No |
| `db_instance_class` | RDS instance class | `db.t3.micro` | No |
| `multi_az` | Enable RDS Multi-AZ | `false` | No |
| `enable_deletion_protection` | Enable deletion protection | `false` | No |

### Production Recommendations

For production deployments, consider these settings:

```hcl
environment = "prod"
instance_type = "t3.small"
db_instance_class = "db.t3.small"
multi_az = true
enable_deletion_protection = true
backup_retention_period = 30
```

## Accessing Your Application

After deployment, your applications will be available at:

- **Frontend**: `https://app.yourdomain.com` (CloudFront)
- **Backend API**: `https://api.yourdomain.com` (Load Balancer)

## Monitoring and Logging

The infrastructure includes:

- **CloudWatch Logs**: Application and system logs
- **CloudWatch Metrics**: Infrastructure monitoring
- **RDS Performance Insights**: Database performance monitoring
- **ALB Access Logs**: Load balancer request logs

## Security Best Practices

This configuration implements several security best practices:

- ✅ Database credentials stored in AWS Secrets Manager
- ✅ EC2 instances in private subnets
- ✅ Security groups with minimal required access
- ✅ Encrypted storage for S3 and RDS
- ✅ IAM roles with least privilege principles
- ✅ S3 bucket public access blocked

## Cost Optimization

To optimize costs:

1. Use `t3.micro` instances for development
2. Enable RDS storage autoscaling
3. Configure CloudFront caching properly
4. Use S3 lifecycle policies for old versions
5. Monitor and right-size resources based on usage

## Troubleshooting

### Common Issues

1. **AMI not found**: Ensure you're using the correct region
2. **Key pair not found**: Create an AWS key pair or remove the variable
3. **Domain already exists**: Route53 hosted zones must have unique names
4. **Insufficient permissions**: Ensure your AWS credentials have admin access

### Debugging

Check the following logs:

- **EC2 User Data**: `/var/log/cloud-init-output.log`
- **Django Application**: Check application logs via SSH
- **Load Balancer**: Check target health in AWS console
- **Database**: Check RDS events and logs

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

**Warning**: This will permanently delete all data. Ensure you have backups if needed.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test the deployment
5. Submit a pull request

## Support

For issues and questions:

1. Check the troubleshooting section
2. Review AWS documentation
3. Open an issue in the repository