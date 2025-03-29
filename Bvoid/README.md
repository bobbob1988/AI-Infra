# AI Infrastructure with AWS EMR and Kubeflow

This repository contains Terraform configurations to set up a comprehensive AI/ML infrastructure using AWS EMR and Kubeflow, enabling you to work with Jupyter notebooks and run ML pipelines.

## Prerequisites

- AWS Account with appropriate permissions
- AWS CLI configured with your credentials
- Terraform installed (version >= 1.0)
- kubectl installed
- AWS IAM user with appropriate permissions
- Docker installed (for local development)

## Infrastructure Components

1. **AWS EMR Cluster**
   - Spark for distributed computing
   - JupyterHub for notebook access
   - JupyterEnterpriseGateway for remote kernel support
   - TensorFlow, PyTorch, and MXNet for deep learning
   - Horovod for distributed training
   - Ganglia for monitoring
   - Master node: m5.2xlarge (8 vCPU, 32GB RAM)
   - Core nodes: 2x m5.2xlarge
   - 100GB EBS storage per node
   - Optimized Spark and YARN configurations

2. **Kubeflow on EKS**
   - Kubernetes cluster for ML workflow orchestration
   - GPU-enabled nodes (g4dn.xlarge) for deep learning
   - Auto-scaling enabled (1-4 nodes)
   - S3 integration for artifact storage
   - ML pipeline components:
     - Katib for hyperparameter tuning
     - KFServing for model serving
     - Kubeflow Pipelines for workflow orchestration
     - AWS SageMaker integration for experiment tracking and model management

3. **Storage and Data Management**
   - S3 buckets for:
     - ML data storage
     - Model artifacts
     - Training results
     - Pipeline artifacts

## ML Pipeline Components

1. **Data Processing**
   - Spark for large-scale data processing
   - Data validation and cleaning
   - Feature engineering
   - Data versioning with DVC

2. **Model Development**
   - Jupyter notebooks for interactive development
   - Support for multiple ML frameworks:
     - TensorFlow
     - PyTorch
     - MXNet
   - Distributed training with Horovod
   - GPU acceleration

3. **Model Training**
   - Kubeflow Pipelines for workflow automation
   - Katib for hyperparameter optimization
   - AWS SageMaker for experiment tracking and model management
   - Distributed training capabilities

4. **Model Serving**
   - KFServing for model deployment
   - A/B testing support
   - Model monitoring
   - Automatic scaling

5. **Monitoring and Logging**
   - Ganglia for system monitoring
   - AWS SageMaker for experiment tracking
   - CloudWatch integration
   - Custom metrics collection

## Setup Instructions

1. **Configure AWS Credentials**
   ```bash
   aws configure
   ```

2. **Initialize Terraform**
   ```bash
   cd terraform/emr
   terraform init
   
   cd ../kubeflow
   terraform init
   ```

3. **Deploy EMR Cluster**
   ```bash
   cd terraform/emr
   terraform plan
   terraform apply
   ```

4. **Deploy Kubeflow**
   ```bash
   cd terraform/kubeflow
   terraform plan
   terraform apply
   ```

5. **Access Jupyter Notebooks**
   - After EMR cluster is ready, get the master node public DNS from Terraform outputs
   - Access JupyterHub at: `http://<master-node-public-dns>:8888`
   - Default credentials will be provided in the EMR cluster details

6. **Access Kubeflow Dashboard**
   ```bash
   kubectl port-forward svc/kubeflow-dashboard -n kubeflow 8080:80
   ```
   Then open `http://localhost:8080` in your browser

7. **Configure SageMaker Integration**
   ```bash
   # Configure AWS credentials for SageMaker
   aws configure set region <your-region>
   
   # Access SageMaker Studio (if needed)
   aws sagemaker create-domain --domain-name ml-domain --auth-mode IAM
   ```

## Project Structure

```
Bvoid/
├── terraform/
│   ├── emr/
│   │   ├── main.tf
│   │   └── variables.tf
│   └── kubeflow/
│       ├── main.tf
│       └── variables.tf
├── notebooks/
│   └── examples/
│       ├── data_processing/
│       ├── model_training/
│       └── model_serving/
└── pipelines/
    └── examples/
        ├── training_pipeline/
        └── serving_pipeline/
```

## Cost Management

- The infrastructure uses on-demand instances
- GPU instances are more expensive but provide better performance for ML workloads
- Remember to destroy resources when not in use:
  ```bash
  terraform destroy
  ```

## Security Notes

- The EMR cluster is deployed in a VPC with public access
- Security groups are configured to allow:
  - SSH (port 22)
  - Jupyter (port 8888)
  - TensorBoard (port 6006)
  - TensorFlow Serving (port 8501)
- S3 buckets are private by default
- Consider implementing additional security measures for production use

## Best Practices

1. **Data Management**
   - Use version control for data (DVC)
   - Implement data validation
   - Use appropriate data formats (Parquet, TFRecord)
   - Implement data lineage tracking

2. **Model Development**
   - Use version control for code
   - Implement CI/CD pipelines
   - Use containerization for reproducibility
   - Implement proper logging and monitoring

3. **Resource Management**
   - Use spot instances for cost optimization
   - Implement auto-scaling policies
   - Monitor resource usage
   - Clean up unused resources

## Support

For issues or questions, please create an issue in this repository.

## Description
A brief description of your project goes here.

## Features
- Feature 1
- Feature 2
- Feature 3

## Installation
```bash
# Installation instructions will go here
```

## Usage
```bash
# Usage examples will go here
```

## Configuration
Explain any configuration options here.

## Contributing
Contributions are welcome! Please feel free to submit a Pull Request.

## License
This project is licensed under the [LICENSE NAME] - see the [LICENSE](LICENSE) file for details.

## Contact
Your Name - [@yourtwitter](https://twitter.com/yourtwitter) - email@example.com

Project Link: [https://github.com/yourusername/Bvoid](https://github.com/yourusername/Bvoid) 