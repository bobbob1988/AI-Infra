# ML Training Pipeline with Kubeflow and SageMaker

This pipeline demonstrates a complete ML workflow that integrates Kubeflow with AWS SageMaker for model training and deployment.

## Pipeline Components

1. **Data Preprocessing**
   - Uses Spark for distributed data processing
   - Performs feature engineering
   - Scales features using StandardScaler
   - Saves processed data in Parquet format

2. **Model Training**
   - Uses SageMaker for distributed training
   - Implements TensorFlow model
   - Tracks experiments and metrics in SageMaker
   - Supports hyperparameter tuning

3. **Model Evaluation**
   - Evaluates model performance
   - Compares against threshold
   - Deploys model only if performance criteria are met

4. **Model Deployment**
   - Deploys model to SageMaker endpoint
   - Configures endpoint for inference
   - Supports A/B testing

## Prerequisites

- Kubeflow cluster with SageMaker integration
- AWS credentials configured
- S3 buckets for data and model storage
- Required Python packages (see requirements.txt)

## Setup

1. **Install Dependencies**
   ```bash
   pip install -r requirements.txt
   ```

2. **Configure AWS Credentials**
   ```bash
   aws configure
   ```

3. **Update S3 Paths**
   - Modify the default S3 paths in pipeline.py:
     ```python
     input_data: str = 's3://your-bucket/raw-data/'
     output_data: str = 's3://your-bucket/processed-data/'
     model_output: str = 's3://your-bucket/models/'
     test_data: str = 's3://your-bucket/test-data/'
     ```

4. **Compile Pipeline**
   ```bash
   python pipeline.py
   ```

## Running the Pipeline

1. **Upload to Kubeflow**
   ```bash
   kfp pipeline upload -p ml_pipeline.yaml
   ```

2. **Create Run**
   ```bash
   kfp run submit -e ml-pipeline -f ml_pipeline.yaml
   ```

3. **Monitor Progress**
   - Access Kubeflow UI to monitor pipeline progress
   - Check SageMaker console for training jobs
   - Monitor CloudWatch for logs

## Customization

1. **Data Preprocessing**
   - Modify `preprocess_data()` in pipeline.py
   - Add your specific feature engineering steps
   - Update data loading logic

2. **Model Architecture**
   - Modify `create_model()` in train.py
   - Update hyperparameters
   - Add custom layers or architectures

3. **Evaluation Criteria**
   - Update threshold in pipeline parameters
   - Modify evaluation metrics
   - Add custom validation logic

4. **Deployment Configuration**
   - Update instance types
   - Configure auto-scaling
   - Set up monitoring

## Best Practices

1. **Data Management**
   - Use version control for data
   - Implement data validation
   - Monitor data quality

2. **Model Training**
   - Use experiment tracking
   - Implement early stopping
   - Monitor resource usage

3. **Deployment**
   - Use blue-green deployment
   - Implement monitoring
   - Set up alerts

## Troubleshooting

1. **Common Issues**
   - S3 access permissions
   - IAM role configuration
   - Resource limits

2. **Debugging**
   - Check CloudWatch logs
   - Monitor SageMaker jobs
   - Review pipeline logs

## Support

For issues or questions, please create an issue in the repository. 