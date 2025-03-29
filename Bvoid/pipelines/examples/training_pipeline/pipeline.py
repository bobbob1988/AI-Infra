import kfp
from kfp import dsl
from kfp.components import func_to_container_op
import sagemaker
from sagemaker.tensorflow import TensorFlow
import boto3
import json

# Define the data preprocessing component
@func_to_container_op
def preprocess_data(input_data: str, output_data: str):
    """Preprocess data using Spark"""
    from pyspark.sql import SparkSession
    from pyspark.ml.feature import VectorAssembler, StandardScaler
    
    # Initialize Spark
    spark = SparkSession.builder.appName("DataPreprocessing").getOrCreate()
    
    # Read data
    df = spark.read.csv(input_data, header=True, inferSchema=True)
    
    # Feature engineering
    feature_cols = [col for col in df.columns if col != 'label']
    assembler = VectorAssembler(inputCols=feature_cols, outputCol="features")
    scaler = StandardScaler(inputCol="features", outputCol="scaled_features")
    
    # Transform data
    df = assembler.transform(df)
    df = scaler.fit(df).transform(df)
    
    # Save processed data
    df.write.mode("overwrite").parquet(output_data)
    
    return output_data

# Define the model training component
@func_to_container_op
def train_model(input_data: str, model_output: str, experiment_name: str):
    """Train model using SageMaker"""
    sagemaker_session = sagemaker.Session()
    
    # Create SageMaker experiment
    experiment = sagemaker.Experiment.create(
        experiment_name=experiment_name,
        description='Model training experiment'
    )
    
    # Create trial
    trial = experiment.create_trial(trial_name=f'{experiment_name}-trial')
    
    # Configure training job
    estimator = TensorFlow(
        entry_point='train.py',
        role='SageMakerRole',
        instance_count=1,
        instance_type='ml.g4dn.xlarge',
        framework_version='2.4',
        py_version='py37',
        hyperparameters={
            'learning_rate': 0.01,
            'batch_size': 32,
            'epochs': 10
        }
    )
    
    # Start training job
    estimator.fit(
        inputs={'train': input_data},
        job_name=f'{experiment_name}-training',
        wait=True
    )
    
    # Log metrics to trial
    metrics = estimator.latest_training_job.describe()['FinalMetricDataList']
    for metric in metrics:
        trial.log_metric(metric['MetricName'], float(metric['Value']))
    
    return model_output

# Define the model evaluation component
@func_to_container_op
def evaluate_model(model_output: str, test_data: str, threshold: float) -> bool:
    """Evaluate model performance"""
    sagemaker_session = sagemaker.Session()
    
    # Load model
    model = TensorFlowModel(
        model_data=model_output,
        role='SageMakerRole',
        framework_version='2.4'
    )
    
    # Run evaluation
    predictor = model.deploy(
        initial_instance_count=1,
        instance_type='ml.m5.xlarge'
    )
    
    # Get predictions
    predictions = predictor.predict(test_data)
    
    # Calculate metrics
    accuracy = calculate_accuracy(predictions, test_data)
    
    # Clean up
    predictor.delete_endpoint()
    
    return accuracy >= threshold

# Define the model deployment component
@func_to_container_op
def deploy_model(model_output: str, endpoint_name: str):
    """Deploy model to SageMaker endpoint"""
    sagemaker_session = sagemaker.Session()
    
    # Create model
    model = TensorFlowModel(
        model_data=model_output,
        role='SageMakerRole',
        framework_version='2.4'
    )
    
    # Deploy model
    predictor = model.deploy(
        initial_instance_count=1,
        instance_type='ml.m5.xlarge',
        endpoint_name=endpoint_name
    )
    
    return endpoint_name

# Define the pipeline
@dsl.pipeline(
    name='ML Training Pipeline',
    description='A pipeline that preprocesses data, trains a model, evaluates it, and deploys if it meets criteria'
)
def ml_pipeline(
    input_data: str = 's3://your-bucket/raw-data/',
    output_data: str = 's3://your-bucket/processed-data/',
    model_output: str = 's3://your-bucket/models/',
    experiment_name: str = 'ml-experiment',
    test_data: str = 's3://your-bucket/test-data/',
    threshold: float = 0.85,
    endpoint_name: str = 'ml-endpoint'
):
    # Preprocess data
    preprocess_task = preprocess_data(input_data, output_data)
    
    # Train model
    train_task = train_model(
        preprocess_task.output,
        model_output,
        experiment_name
    )
    
    # Evaluate model
    evaluate_task = evaluate_model(
        train_task.output,
        test_data,
        threshold
    )
    
    # Conditionally deploy model
    with dsl.Condition(evaluate_task.output == True):
        deploy_task = deploy_model(
            train_task.output,
            endpoint_name
        )

# Compile the pipeline
if __name__ == '__main__':
    kfp.compiler.Compiler().compile(ml_pipeline, 'ml_pipeline.yaml') 